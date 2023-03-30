/*
 * functions.h
 *
 *  Created on: Aug 31, 2017
 *      Author: User
 */

#ifndef FUNCTIONS_H_
#define FUNCTIONS_H_


//================================================================PUF related
void encode_bch(unsigned char *ri, unsigned char *helper,unsigned char *key){
    unsigned int    idx, j;
    signed int i;// i need to use at 0
    unsigned char    feedback;

    unsigned char bb[47];
    const int length = 63;//===========fixed parameter
    const int k = 16;//key length
    const char g[48] = {1,1,0,1,0,1,0,0,1,1,0,1,1,1,0,0,1,0,1,1,1,0,1,1,1,1,0,1,0,0,0,0,1,1,0,0,1,0,0,1,1,0,1,1,0,0,1,1};

    //parallel to serial engine
    unsigned char data[63];//put each bit into an individual byte 10100101 =>00000001, 00000000, 00000001, 00000000, 00000000, 00000001, 00000000, 00000001
    for(idx = 0;idx < length; idx++){
        data[idx] = (ri[idx/8] & (0x1 << (7-(idx%8)))) != 0;
    }

    //generate key for SKE decoder.
    //use the first K bits as the Key "Cryptographic Key Generation from PUF Data Using Efficient Fuzzy Extractor"
    key[0] = ri[0];
    key[1] = ri[1];

    for (i = 0; i < length - k; i++)
        bb[i] = 0;
    for (i = k - 1; i >= 0; i--) {
        feedback = data[i] ^ bb[length - k - 1];
        if (feedback != 0) {
            for (j = length - k - 1; j > 0; j--)
                if (g[j] != 0)
                    bb[j] = bb[j - 1] ^ feedback;
                else
                    bb[j] = bb[j - 1];
            bb[0] = g[0] && feedback;
        } else {
            for (j = length - k - 1; j > 0; j--)
                bb[j] = bb[j - 1];
            bb[0] = 0;
        }
    }


    //serial to parallel engine
    idx = 0;
    for(i = 0;i < 2;i++){
        helper[i] = 0;
        for(j = 0;j < 8;j++){
            if(idx >= 47){
                helper[i] &= ~0x1;
                break;
            }
            helper[i] |= (bb[idx] << (7-j));
            idx++;
        }
    }

    helper[0] ^= ri[2];
    helper[1] ^= ri[3];
    helper[2] ^= ri[4];
    helper[3] ^= ri[5];
    helper[4] ^= ri[6];
    helper[5] ^= ri[7];
}

void decode_bch(unsigned char *ri,unsigned char *helper,unsigned char *key){
    register int    i, j, u, q, t2, count = 0, syn_error = 0;
    static int             elp[63][11], d[63], l[63], u_lu[63], s[22];
    static int             root[11], loc[11], err[11], reg[11];
    static int             recd[63];

    const char alpha_to[8] = {1,2,4,8,16,32,64,128};
    const char index_of[32] ={-1,0,1,6,2,12,7,26,3,32,13,35,8,48,27,18,4,24,33,16,14,52,36,54,9,45,49,38,28,41,19,56};

    const char length = 63;
    const char k = 16;
    const char n = length;
    const char t = 11;
    t2 = 2 * t;


    //parallel to serial engine
    //put each bit into an individual byte 10100101 =>00000001, 00000000, 00000001, 00000000, 00000000, 00000001, 00000000, 00000001
    for(i = 0;i < length-k; i++){
        recd[i] = (helper[i/8] & (0x1 << (7-(i%8)))) != 0;
    }
    for(i = length-k;i <length;i++ ){
        recd[i] = (ri[i/8] & (0x1 << (7-(i%8)))) != 0;
    }

    /* first form the syndromes */
    for (i = 1; i <= t2; i++) {
        s[i] = 0;
        for (j = 0; j < length; j++)
            if (recd[j] != 0)
                s[i] ^= alpha_to[(i * j) % n];
        if (s[i] != 0)
            syn_error = 1; /* set error flag if non-zero syndrome */
/*
 * Note:    If the code is used only for ERROR DETECTION, then
 *          exit program here indicating the presence of errors.
 */
        /* convert syndrome from polynomial form to index form  */
        s[i] = index_of[s[i]];
    }

    if (syn_error) {    /* if there are errors, try to correct them */
        /*
         * Compute the error location polynomial via the Berlekamp
         * iterative algorithm. Following the terminology of Lin and
         * Costello's book :   d[u] is the 'mu'th discrepancy, where
         * u='mu'+1 and 'mu' (the Greek letter!) is the step number
         * ranging from -1 to 2*t (see L&C),  l[u] is the degree of
         * the elp at that step, and u_l[u] is the difference between
         * the step number and the degree of the elp.
         */
        /* initialise table entries */
        d[0] = 0;           /* index form */
        d[1] = s[1];        /* index form */
        elp[0][0] = 0;      /* index form */
        elp[1][0] = 1;      /* polynomial form */
        for (i = 1; i < t2; i++) {
            elp[0][i] = -1; /* index form */
            elp[1][i] = 0;  /* polynomial form */
        }
        l[0] = 0;
        l[1] = 0;
        u_lu[0] = -1;
        u_lu[1] = 0;
        u = 0;

        do {
            u++;
            if (d[u] == -1) {
                l[u + 1] = l[u];
                for (i = 0; i <= l[u]; i++) {
                    elp[u + 1][i] = elp[u][i];
                    elp[u][i] = index_of[elp[u][i]];
                }
            } else
                /*
                 * search for words with greatest u_lu[q] for
                 * which d[q]!=0
                 */
            {
                q = u - 1;
                while ((d[q] == -1) && (q > 0))
                    q--;
                /* have found first non-zero d[q]  */
                if (q > 0) {
                  j = q;
                  do {
                    j--;
                    if ((d[j] != -1) && (u_lu[q] < u_lu[j]))
                      q = j;
                  } while (j > 0);
                }

                /*
                 * have now found q such that d[u]!=0 and
                 * u_lu[q] is maximum
                 */
                /* store degree of new elp polynomial */
                if (l[u] > l[q] + u - q)
                    l[u + 1] = l[u];
                else
                    l[u + 1] = l[q] + u - q;

                /* form new elp(x) */
                for (i = 0; i < t2; i++)
                    elp[u + 1][i] = 0;
                for (i = 0; i <= l[q]; i++)
                    if (elp[q][i] != -1)
                        elp[u + 1][i + u - q] =
                                   alpha_to[(d[u] + n - d[q] + elp[q][i]) % n];
                for (i = 0; i <= l[u]; i++) {
                    elp[u + 1][i] ^= elp[u][i];
                    elp[u][i] = index_of[elp[u][i]];
                }
            }
            u_lu[u + 1] = u - l[u + 1];

            /* form (u+1)th discrepancy */
            if (u < t2) {
            /* no discrepancy computed on last iteration */
              if (s[u + 1] != -1)
                d[u + 1] = alpha_to[s[u + 1]];
              else
                d[u + 1] = 0;
                for (i = 1; i <= l[u + 1]; i++)
                  if ((s[u + 1 - i] != -1) && (elp[u + 1][i] != 0))
                    d[u + 1] ^= alpha_to[(s[u + 1 - i]
                                  + index_of[elp[u + 1][i]]) % n];
              /* put d[u+1] into index form */
              d[u + 1] = index_of[d[u + 1]];
            }
        } while ((u < t2) && (l[u + 1] <= t));

        u++;
        if (l[u] <= t) {/* Can correct errors */
            /* put elp into index form */
            for (i = 0; i <= l[u]; i++)
                elp[u][i] = index_of[elp[u][i]];

            /* Chien search: find roots of the error location polynomial */
            for (i = 1; i <= l[u]; i++)
                reg[i] = elp[u][i];
            count = 0;
            for (i = 1; i <= n; i++) {
                q = 1;
                for (j = 1; j <= l[u]; j++)
                    if (reg[j] != -1) {
                        reg[j] = (reg[j] + j) % n;
                        q ^= alpha_to[reg[j]];
                    }
                if (!q) {   /* store root and error
                         * location number indices */
                    root[count] = i;
                    loc[count] = n - i;
                    count++;
                }
            }

            if (count == l[u])
            /* no. roots = degree of elp hence <= t errors */
                for (i = 0; i < l[u]; i++)
                    recd[loc[i]] ^= 1;
            else{}    /* elp has degree >t hence cannot solve */

        }
    }
    //serial to parallel engine
    int idx = length-k;
    for(i = 0;i < k/8;i++){
        key[i] = 0;
        for(j = 0;j < 8;j++){
            if(idx >= length){
                break;
            }
            key[i] |= (recd[idx] << (7-j));
            idx++;
        }
    }
}

#endif /* FUNCTIONS_H_ */
