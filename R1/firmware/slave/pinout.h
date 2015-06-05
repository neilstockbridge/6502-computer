/*
              __ __
     /RESET [|  U  |] Vcc
  RXD   PD0 [|     |] PB7  SCK
  TXD   PD1 [|     |] PB6  MISO
 XTAL2  PA1 [|     |] PB5  MOSI
 XTAL1  PA0 [|     |] PB4  /SSA
  RESB  PD2 [|     |] PB3  /SS3
  IRQB  PD3 [|     |] PB2  /SS2
  /SS4  PD4 [|     |] PB1  /SS1
  /SS5  PD5 [|     |] PB0  /SS0
        GND [|_____|] PD6  /SS6

*/

#define  RXD        PD0
#define  TXD        PD1
#define  RESB       PD2
#define  RESB_PORT  PORTD
#define  IRQB       PD3
#define  IRQB_DDR   DDRD
#define  SS4        PD4
#define  SS5        PD5

#define  SS6        PD6
#define  SS0        PB0
#define  SS1        PB1
#define  SS2        PB2
#define  SS3        PB3
#define  SSA        PB4
#define  MOSI       PB5
#define  MISO       PB6
#define  SCK        PB7

#define  LOW  0
#define  HIGH  1
#define  SENSE( pin )  ( 0 << pin )
#define  DRIVE( pin )  ( 1 << pin )
#define  PULL_UP( pin )  ( 1 << pin )
#define  drive_low( port, pin )  port &= ~_BV( pin )
#define  drive_high( port, pin )  port |= _BV( pin )

#define  assert_RESB()  drive_low( RESB_PORT, RESB )
#define  release_RESB()  drive_high( RESB_PORT, RESB )
#define  assert_IRQB()  ( IRQB_DDR |= DRIVE( IRQB) )
#define  release_IRQB()  ( IRQB_DDR &= ~DRIVE( IRQB) )

