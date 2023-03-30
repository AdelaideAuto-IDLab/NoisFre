/** @file       main.c
 *  @brief      TINA encode verify
 *
 *  @author     Yang Su, Auto-ID Lab, The University of Adelaide
 *  Compile> mex -O aes.c utils.c TC_aes.c cmac_mode.c tina.c TINAmain.c -output CMAC
 */ 

/**
 * as a unique ID.
 */
#include <stdint.h>
#include "tina.h"
#include "cmac_mode.h"
#include <stdio.h>
#include "mex.h"
#include <string.h>
#include "matrix.h"

#define BUF_LEN 16
struct tc_cmac_struct cmac_ctx;// CMAC context

void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[]){
	if (nrhs != 4)
        mexErrMsgIdAndTxt("MATLAB:xtimesy:invalidNumInputs","Usage: CMAC(key,challenge,msg,msg_sz)");
	if (nlhs != 2)
        mexErrMsgIdAndTxt("MATLAB:xtimesy:invalidNumOutputs", "Two output [SUCCESS, CMAC_Tag] required.");
    uint8_t InKey_sz = mxGetN(prhs[0]);
    if (InKey_sz != BUF_LEN)
        mexErrMsgIdAndTxt("MATLAB:xtimesy:invalidNumInputs","Expected 16 bits key.");
    uint8_t InChallenge_sz = mxGetN(prhs[1]);
    if (InChallenge_sz != BUF_LEN)
        mexErrMsgIdAndTxt("MATLAB:xtimesy:invalidNumInputs","Expected 16 bits challenge.");
	uint8_t *InKey = (uint8_t*)mxGetPr(prhs[0]);//get key
    uint8_t *InChanllenge = (uint8_t*)mxGetPr(prhs[1]);//get challenge
    uint32_t buflen = mxGetScalar(prhs[3]); // get the message length
    uint8_t *InMsg = (uint8_t*)mxGetPr(prhs[2]);
    uint8_t Response[16];
    tc_cmac_AIO(&cmac_ctx,InKey,InMsg,buflen,Response);
	plhs[1] = mxCreateDoubleScalar(0);
	int Tag_sz = {BUF_LEN};
	plhs[0] = mxCreateNumericMatrix(1,Tag_sz,mxUINT8_CLASS,mxREAL);
	uint8_t *start_of_pr = (uint8_t*)mxGetData(plhs[0]);
	memcpy(start_of_pr,Response,Tag_sz*sizeof(uint8_t));
}

