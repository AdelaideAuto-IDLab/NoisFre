/* cmac_mode.c - TinyCrypt CMAC mode implementation */

/*
 *  Copyright (C) 2017 by Intel Corporation, All Rights Reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are met:
 *
 *    - Redistributions of source code must retain the above copyright notice,
 *     this list of conditions and the following disclaimer.
 *
 *    - Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 *    - Neither the name of Intel Corporation nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 *  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 *  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *  POSSIBILITY OF SUCH DAMAGE.
 */

#include "cmac_mode.h"
#include "nrf_soc.h"
#include "app_error.h"

#include <stdio.h>
#include <string.h>

#define MASK_TWENTY_SEVEN 0x1b


extern uint8_t PUF_Key[16]; // reformed PUF key
//ECB data setuct
nrf_ecb_hal_data_t ecb;

uint32_t _copy(uint8_t *to, uint32_t to_len, const uint8_t *from, uint32_t from_len)
{
    if (from_len <= to_len) {
        (void)memcpy(to, from, from_len);
        return from_len;
    } else {
        return TC_CRYPTO_FAIL;
    }
}

void _set(void *to, uint8_t val, uint32_t len)
{
    (void)memset(to, val, len);
}

/*
 * Doubles the value of a byte for values up to 127.
 */
uint8_t _double_byte(uint8_t a)
{
    return ((a<<1) ^ ((a>>7) * MASK_TWENTY_SEVEN));
}

int32_t _compare(const uint8_t *a, const uint8_t *b, size_t size)
{
    const uint8_t *tempa = a;
    const uint8_t *tempb = b;
    uint8_t result = 0;
    uint32_t i;
    for (i = 0; i < size; i++) {
        result |= tempa[i] ^ tempb[i];
    }
    return result;
}

/* max number of calls until change the key (2^48).*/
static const uint64_t MAX_CALLS = ((uint64_t)1 << 48);

/*
 *  gf_wrap -- In our implementation, GF(2^128) is represented as a 16 byte
 *  array with byte 0 the most significant and byte 15 the least significant.
 *  High bit carry reduction is based on the primitive polynomial
 *
 *                     X^128 + X^7 + X^2 + X + 1,
 *
 *  which leads to the reduction formula X^128 = X^7 + X^2 + X + 1. Indeed,
 *  since 0 = (X^128 + X^7 + X^2 + 1) mod (X^128 + X^7 + X^2 + X + 1) and since
 *  addition of polynomials with coefficients in Z/Z(2) is just XOR, we can
 *  add X^128 to both sides to get
 *
 *       X^128 = (X^7 + X^2 + X + 1) mod (X^128 + X^7 + X^2 + X + 1)
 *
 *  and the coefficients of the polynomial on the right hand side form the
 *  string 1000 0111 = 0x87, which is the value of gf_wrap.
 *
 *  This gets used in the following way. Doubling in GF(2^128) is just a left
 *  shift by 1 bit, except when the most significant bit is 1. In the latter
 *  case, the relation X^128 = X^7 + X^2 + X + 1 says that the high order bit
 *  that overflows beyond 128 bits can be replaced by addition of
 *  X^7 + X^2 + X + 1 <--> 0x87 to the low order 128 bits. Since addition
 *  in GF(2^128) is represented by XOR, we therefore only have to XOR 0x87
 *  into the low order byte after a left shift when the starting high order
 *  bit is 1.
 */
const unsigned char gf_wrap = 0x87;

/*
 *  assumes: out != NULL and points to a GF(2^n) value to receive the
 *            doubled value;
 *           in != NULL and points to a 16 byte GF(2^n) value
 *            to double;
 *           the in and out buffers do not overlap.
 *  effects: doubles the GF(2^n) value pointed to by "in" and places
 *           the result in the GF(2^n) value pointed to by "out."
 */
void gf_double(uint8_t *out, uint8_t *in)
{

	/* start with low order byte */
	uint8_t *x = in + (TC_AES_BLOCK_SIZE - 1);

	/* if msb == 1, we need to add the gf_wrap value, otherwise add 0 */
	uint8_t carry = (in[0] >> 7) ? gf_wrap : 0;

	out += (TC_AES_BLOCK_SIZE - 1);
	for (;;) {
		*out-- = (*x << 1) ^ carry;
		if (x == in) {
			break;
		}
		carry = *x-- >> 7;
	}
}

int32_t tc_cmac_setup(TCCmacState_t s, const uint8_t *key)
{

	/* input sanity check: */
	if (s == (TCCmacState_t) 0 ||
	    key == (const uint8_t *) 0) {
		return TC_CRYPTO_FAIL;
	}

	/* put s into a known state */
	_set(s, 0, sizeof(*s));
	
	/* initialize the AES context */
	memcpy(ecb.key, key, 16);
  memset(ecb.cleartext, 0, 16);
  memset(ecb.ciphertext, 0, 16);

	/* compute s->K1 and s->K2 from s->iv using s->keyid */
	_set(s->iv, 0, TC_AES_BLOCK_SIZE);
	tc_aes_encrypt(s->iv, s->iv);
	gf_double (s->K1, s->iv);
	gf_double (s->K2, s->K1);

	/* reset s->iv to 0 in case someone wants to compute now */
	tc_cmac_init(s);

	return TC_CRYPTO_SUCCESS;
}

int32_t tc_cmac_erase(TCCmacState_t s)
{
	if (s == (TCCmacState_t) 0) {
		return TC_CRYPTO_FAIL;
	}

	/* destroy the current state */
	_set(s, 0, sizeof(*s));

	return TC_CRYPTO_SUCCESS;
}

int32_t tc_cmac_init(TCCmacState_t s)
{
	/* input sanity check: */
	if (s == (TCCmacState_t) 0) {
		return TC_CRYPTO_FAIL;
	}

	/* CMAC starts with an all zero initialization vector */
	_set(s->iv, 0, TC_AES_BLOCK_SIZE);

	/* and the leftover buffer is empty */
	_set(s->leftover, 0, TC_AES_BLOCK_SIZE);
	s->leftover_offset = 0;

	/* Set countdown to max number of calls allowed before re-keying: */
	s->countdown = MAX_CALLS;

	return TC_CRYPTO_SUCCESS;
}


int32_t tc_cmac_update(TCCmacState_t s, const uint8_t *data, size_t data_length)
{
	uint32_t i;

	/* input sanity check: */
	if (s == (TCCmacState_t) 0) {
		return TC_CRYPTO_FAIL;
	}
	if (data_length == 0) {
		return  TC_CRYPTO_SUCCESS;
	}
	if (data == (const uint8_t *) 0) {
		return TC_CRYPTO_FAIL;
	}

	if (s->countdown == 0) {
		return TC_CRYPTO_FAIL;
	}

	s->countdown--;

	if (s->leftover_offset > 0) {
		/* last data added to s didn't end on a TC_AES_BLOCK_SIZE byte boundary */
		size_t remaining_space = TC_AES_BLOCK_SIZE - s->leftover_offset;

		if (data_length < remaining_space) {
			/* still not enough data to encrypt this time either */
			_copy(&s->leftover[s->leftover_offset], data_length, data, data_length);
			s->leftover_offset += data_length;
			return TC_CRYPTO_SUCCESS;
		}
		/* leftover block is now full; encrypt it first */
		_copy(&s->leftover[s->leftover_offset],
		      remaining_space,
		      data,
		      remaining_space);
		data_length -= remaining_space;
		data += remaining_space;
		s->leftover_offset = 0;

		for (i = 0; i < TC_AES_BLOCK_SIZE; ++i) {
			s->iv[i] ^= s->leftover[i];
		}
		tc_aes_encrypt(s->iv, s->iv);
	}

	/* CBC encrypt each (except the last) of the data blocks */
	while (data_length > TC_AES_BLOCK_SIZE) {
		for (i = 0; i < TC_AES_BLOCK_SIZE; ++i) {
			s->iv[i] ^= data[i];
		}
		tc_aes_encrypt(s->iv, s->iv);
		data += TC_AES_BLOCK_SIZE;
		data_length  -= TC_AES_BLOCK_SIZE;
	}

	if (data_length > 0) {
		/* save leftover data for next time */
		_copy(s->leftover, data_length, data, data_length);
		s->leftover_offset = data_length;
	}

	return TC_CRYPTO_SUCCESS;
}

int32_t tc_cmac_final(uint8_t *tag, TCCmacState_t s)
{
	uint8_t *k;
	uint32_t i;

	/* input sanity check: */
	if (tag == (uint8_t *) 0 ||
	    s == (TCCmacState_t) 0) {
		return TC_CRYPTO_FAIL;
	}

	if (s->leftover_offset == TC_AES_BLOCK_SIZE) {
		/* the last message block is a full-sized block */
		k = (uint8_t *) s->K1;
	} else {
		/* the final message block is not a full-sized  block */
		size_t remaining = TC_AES_BLOCK_SIZE - s->leftover_offset;

		_set(&s->leftover[s->leftover_offset], 0, remaining);
		s->leftover[s->leftover_offset] = TC_CMAC_PADDING;
		k = (uint8_t *) s->K2;
	}
	for (i = 0; i < TC_AES_BLOCK_SIZE; ++i) {
		s->iv[i] ^= s->leftover[i] ^ k[i];
	}

	tc_aes_encrypt(tag, s->iv);

	/* erasing state: */
	tc_cmac_erase(s);

	return TC_CRYPTO_SUCCESS;
}

int32_t tc_cmac_AIO(TCCmacState_t s, const uint8_t *key, const uint8_t *data, size_t dlen, uint8_t *tag)
{
    tc_cmac_setup(s,key);
    tc_cmac_init(s);
    tc_cmac_update(s,data,dlen);
    tc_cmac_final(tag,s);
		return 0;
}

uint32_t errcd;

int32_t tc_aes_encrypt(uint8_t *out, const uint8_t *in)
{

    if (out == (uint8_t *) 0) {
        return TC_CRYPTO_FAIL;
    } else if (in == (const uint8_t *) 0) {
        return TC_CRYPTO_FAIL;
    }
		
		memcpy(ecb.cleartext, in, 16);
		memset(ecb.ciphertext, 0, 16);
		errcd = sd_ecb_block_encrypt(&ecb);
		memcpy(out,ecb.ciphertext,16);

    return TC_CRYPTO_SUCCESS;
}

int32_t tc_aes_decrypt(uint8_t *out, const uint8_t *in)
{

    if (out == (uint8_t *) 0) {
        return TC_CRYPTO_FAIL;
    } else if (in == (const uint8_t *) 0) {
        return TC_CRYPTO_FAIL;
    }

		memcpy(ecb.cleartext, in, 16);
		memset(ecb.ciphertext, 0, 16);
		errcd = sd_ecb_block_encrypt(&ecb);
		memcpy(out,ecb.ciphertext,16);
    return TC_CRYPTO_SUCCESS;
}

int32_t tc_cbc_mode_encrypt(uint8_t *out, uint32_t outlen, const uint8_t *in,
                uint32_t inlen, const uint8_t *iv)
{

    uint8_t buffer[TC_AES_BLOCK_SIZE];
    uint32_t n, m;

    /* input sanity check: */
    if (out == (uint8_t *) 0 ||
        in == (const uint8_t *) 0 ||
        inlen == 0 ||
        outlen == 0 ||
        (inlen % TC_AES_BLOCK_SIZE) != 0 ||
        (outlen % TC_AES_BLOCK_SIZE) != 0 ||
        outlen != inlen + TC_AES_BLOCK_SIZE) {
        return TC_CRYPTO_FAIL;
    }

    /* copy iv to the buffer */
    (void)_copy(buffer, TC_AES_BLOCK_SIZE, iv, TC_AES_BLOCK_SIZE);
    /* copy iv to the output buffer */
    (void)_copy(out, TC_AES_BLOCK_SIZE, iv, TC_AES_BLOCK_SIZE);
    out += TC_AES_BLOCK_SIZE;

    for (n = m = 0; n < inlen; ++n) {
        buffer[m++] ^= *in++;
        if (m == TC_AES_BLOCK_SIZE) {
            (void)tc_aes_encrypt(buffer, buffer);
            (void)_copy(out, TC_AES_BLOCK_SIZE,
                    buffer, TC_AES_BLOCK_SIZE);
            out += TC_AES_BLOCK_SIZE;
            m = 0;
        }
    }

    return TC_CRYPTO_SUCCESS;
}

int32_t tc_cbc_mode_decrypt(uint8_t *out, uint32_t outlen, const uint8_t *in,
                uint32_t inlen, const uint8_t *iv)
{

    uint8_t buffer[TC_AES_BLOCK_SIZE];
    const uint8_t *p;
    uint32_t n, m;

    /* sanity check the inputs */
    if (out == (uint8_t *) 0 ||
        in == (const uint8_t *) 0 ||
        inlen == 0 ||
        outlen == 0 ||
        (inlen % TC_AES_BLOCK_SIZE) != 0 ||
        (outlen % TC_AES_BLOCK_SIZE) != 0 ||
        outlen != inlen) {
        return TC_CRYPTO_FAIL;
    }

    /*
     * Note that in == iv + ciphertext, i.e. the iv and the ciphertext are
     * contiguous. This allows for a very efficient decryption algorithm
     * that would not otherwise be possible.
     */
    p = iv;
    for (n = m = 0; n < outlen; ++n) {
        if ((n % TC_AES_BLOCK_SIZE) == 0) {
            (void)tc_aes_decrypt(buffer, in);
            in += TC_AES_BLOCK_SIZE;
            m = 0;
        }
        *out++ = buffer[m++] ^ *p++;
    }

    return TC_CRYPTO_SUCCESS;
}
