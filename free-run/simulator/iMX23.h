
#ifndef __IMX23_H
#define __IMX23_H


#include <stdint.h>


typedef struct
{
  uint32_t  BASE;
  uint32_t  SET;
  uint32_t  CLR;
  uint32_t  TOG;
}
_NSCT;


typedef struct
{
  _NSCT  CTRL;
  uint8_t  pad0[0x100-0x010];
  _NSCT  MUXSEL[8]; // 4 banks, 32 pins per bank, 2 bits per pin. %11 means GPIO
  uint8_t  pad1[0x200-0x180];
  _NSCT  DRIVE[15]; // " 4 bits per pin, only 1/2 bank 3 because its for ext RAM
  uint8_t  pad2[0x400-0x2f0];
  _NSCT  PULL[4];   // 4 banks, 32 pins per bank, 1 bit per pin
  uint8_t  pad3[0x500-0x440];
  _NSCT  DOUT[3];   // 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad4[0x600-0x530];
  _NSCT  DIN[3];    // 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad5[0x700-0x630];
  _NSCT  DOE[3];    // 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad6[0x800-0x730];
  _NSCT  PIN2IRQ[3];// 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad7[0x900-0x830];
  _NSCT  IRQEN[3];// 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad8[0xa00-0x930];
  _NSCT  IRQLEVEL[3];// 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad9[0xb00-0xa30];
  _NSCT  IRQPOL[3];// 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
  uint8_t  pad10[0xc00-0xb30];
  _NSCT  IRQSTAT[3];// 3 banks, 32 pins per bank, 1 bit per pin.  No GPIO bank#3
}
HW_PINCTRL_t;


#define  _BV( bit_position )  ( 1 << (bit_position) )


// Maps a block of peripheral control/status registers in to the calling
// process.  Example:
//
//   #define  PINCTRL_BASE  0x80018000
//   #define  PINCTRL_SIZE  ( 0x80019FFF - 0x80018000 + 1 )
//   #define  HW_PINCTRL_CTRL  0x000
//   uint32_t  *pin_ctrl = peripheral_block( PINCTRL_BASE, PINCTRL_SIZE );
//   printf("HW_PINCTRL_CTRL: 0x%x\n", pin_ctrl[ HW_PINCTRL_CTRL ]);
//
// @param  address  The address of the I/O block in the memory map from the
//                  i.MX23 Applications Processor Reference Manual, for example
//                  0x80018000 for PINCTRL
// @param  size     The size in bytes of the area of memory to map ( END
//                  ADDRESS - START ADDRESS + 1 from the Memory Map chapter of
//                  the i.MX23 Applications Processor Reference Manual)
// @return  A pointer to a an address that has been mapped to the specified
//          peripheral block or NULL if an error occurred.
//
extern
void *peripheral_block( uint32_t address, uint32_t size )
;


#endif

