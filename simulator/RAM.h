
#ifndef __RAM_H
#define __RAM_H


#include <stdint.h>


extern
void  init_RAM()
;


extern
uint8_t  read_from_RAM( uint16_t address )
;


extern
void  write_to_RAM( uint16_t address, uint8_t data )
;


#endif

