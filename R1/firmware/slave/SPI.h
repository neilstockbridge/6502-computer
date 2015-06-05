
#ifndef __SPI_H
#define __SPI_H


#include <stdbool.h>
#include <stdint.h>

#include "pinout.h"


extern
void  init_SPI()
;

extern
void  byte_received_via_SPI( uint8_t  data )
;

extern
bool  SPI_is_ready_to_send()
;

extern
void  send_byte_via_SPI( uint8_t  data )
;


#endif

