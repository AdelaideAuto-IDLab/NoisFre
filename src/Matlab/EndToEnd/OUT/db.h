// DHW method For nrf52_298644 only
#ifndef DB_H_
#define DB_H_
#include <stdint.h>
#include <string.h>

const uint8_t e_bits[128] = {
	0, 1, 0, 1, 1, 1, 0, 0, 
	1, 0, 1, 1, 0, 1, 0, 1, 
	1, 0, 0, 1, 0, 1, 1, 1, 
	1, 1, 0, 0, 1, 0, 0, 0, 
	1, 0, 1, 1, 0, 1, 1, 0, 
	0, 0, 1, 1, 1, 1, 0, 0, 
	1, 0, 1, 1, 1, 1, 0, 0, 
	0, 0, 1, 0, 0, 0, 0, 1, 
	0, 0, 1, 1, 1, 0, 0, 1, 
	0, 0, 0, 1, 1, 0, 0, 0, 
	0, 1, 0, 0, 1, 0, 0, 0, 
	0, 1, 1, 0, 1, 0, 1, 1, 
	0, 1, 1, 1, 1, 0, 0, 0, 
	1, 1, 0, 0, 1, 0, 1, 1, 
	0, 0, 1, 1, 0, 1, 1, 0, 
	1, 1, 1, 1, 0, 1, 1, 1}; 

	
const uint8_t e_nums[16] = {0x3A, 0xAD, 0xE9, 0x13, 0x6D, 0x3C, 0x3D, 0x84, 0x9C, 0x18, 0x12, 0xD6, 0x1E, 0xD3, 0x6C, 0xEF}; 

const uint8_t u[16] = {0xD7, 0x7B, 0x7F, 0xE2, 0x28, 0xA2, 0x62, 0xDB, 0x76, 0x28, 0x2F, 0x98, 0x8A, 0xE9, 0x9F, 0x70}; 

void getPUF_DB(uint8_t* sk_out, uint8_t* u_out){
	memcpy(sk_out,e_nums,16);
	memcpy(u_out,u,16);
}
#endif /* DB_H_ */
