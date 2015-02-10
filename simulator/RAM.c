
#include "RAM.h"


uint8_t  memory[ 1 << 16 ];


void  init_RAM()
{
  for ( int  a = 0;  a < sizeof(memory);  a += 1 )
    memory[ a] = 0xea; // NOP
  memory[ 0xfffc] = 0x34;
  memory[ 0xfffd] = 0x12;
}


uint8_t  read_from_RAM( uint16_t address )
{
  return memory[ address];
}


void  write_to_RAM( uint16_t address, uint8_t data )
{
  memory[ address] = data;
}

