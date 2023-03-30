/*
 * tina.h
 *
 *  Created on: 2019Äê11ÔÂ12ÈÕ
 *      Author: Yang
 */

#ifndef TINA_H_
#define TINA_H_

#include <stdint.h>
#include "tina.h"

typedef enum {fast,elaborate} TINAmode;

// Token Identification and Attestation function

void doTINA(uint8_t* response, uint8_t* k, uint8_t* challenge,uint8_t* appCode, uint16_t appCode_Sz, uint8_t* id,uint8_t* veri, TINAmode mode);



#endif /* TINA_H_ */
