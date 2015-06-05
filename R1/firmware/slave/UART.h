
#ifndef __UART_H
#define __UART_H


#include <stdbool.h>
#include <stdint.h>


extern
void  init_UART()
;

extern
void  byte_received_via_UART( uint8_t  data )
;

extern
bool  UART_is_ready_to_send()
;

extern
void  send_byte_via_UART( uint8_t  data )
;


#endif

