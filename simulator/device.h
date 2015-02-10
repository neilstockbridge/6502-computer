
#ifndef __DEVICE_H
#define __DEVICE_H


#include <stdint.h>


typedef struct
{
  uint8_t  (*read)( uint16_t address );
  void  (*write)( uint16_t address, uint8_t data );
}
Device;


#endif

