/*
 * tina.c
 *
 *  Created on: 2019Äê11ÔÂ12ÈÕ
 *      Author: Yang
 */


#include "tina.h"
#include <string.h>
#include "cmac_mode.h"
uint8_t fastData[16];

void doTINA(uint8_t* response, uint8_t* k, uint8_t* challenge,uint8_t* appCode, uint16_t appCode_Sz, uint8_t* id,uint8_t* veri, TINAmode mode){
    struct tc_cmac_struct cmac_ctx;// CMAC context
    tc_cmac_setup(&cmac_ctx,k);
    tc_cmac_init(&cmac_ctx);
    if(mode == elaborate){
        tc_cmac_update(&cmac_ctx,challenge,16);
        tc_cmac_update(&cmac_ctx,appCode,appCode_Sz);
        tc_cmac_final(response,&cmac_ctx);
    }else{
        memset(fastData,0,16);
        memcpy(fastData,id,2);
        memcpy(fastData+2,veri,1);
        tc_cmac_update(&cmac_ctx,challenge,16);
        tc_cmac_update(&cmac_ctx,fastData,16);
        tc_cmac_final(response,&cmac_ctx);
    }
}
