/*

# PLAN

  - Checksum for EEPROM upload

  - Avoid writing to EEPROM: Don't write if already has the value required

  - Store some ROM in program memory.  The memory map could be:
    $0000..$3bff  15K RAM ( Leaves 1K of AVR RAM for its variables and stack)
    $3c00..$3fff  1K 256 mirrored copies of the 65SPI.  Use only the lowest
    $4000..$4fff  4K EEPROM ( Could even be written by the 6502 itself as a tiny non-volatile storage area in the absence of an SD card)
    $5000..$ffff  44K ROM served from program memory ( may only be changed by flashing the AVR)

  - "Turbo": drops in to a code path on the AVR that just toggles the clock for
    256 cycles ( or even N cycles, perhaps where N is configurable) assuming
    that no I/O or address decoding is required ( RAM stays enabled)

Looks like the maximum speed ( at least with C and -O2) would be 250 kHz
          ____ ____
    PB0 [|  1 U 40 |] PA0
    PB1 [|  2   39 |] PA1
    PB2 [|  3   38 |] PA2
    PB3 [|  4   37 |] PA3
    PB4 [|  5   36 |] PA4
    PB5 [|  6   35 |] PA5
    PB6 [|  7   34 |] PA6
    PB7 [|  8   33 |] PA7
 /RESET [|  9   32 |] AREF
    VCC [| 10   31 |] GND
    GND [| 11   30 |] AVCC
  XTAL2 [| 12   29 |] PC7
  XTAL1 [| 13   28 |] PC6
    PD0 [| 14   27 |] PC5
    PD1 [| 15   26 |] PC4
    PD2 [| 16   25 |] PC3
    PD3 [| 17   24 |] PC2
    PD4 [| 18   23 |] PC1
    PD5 [| 19   22 |] PC0
    PD6 [|_20___21_|] PD7

*/

#include <stdbool.h>

#include <avr/io.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#define BAUD 38400
#include <util/setbaud.h>

#include "Request.h"


//#define  _SPI_DEBUG
#define  _EEPROM_DEBUG


#define  A0    PA0
#define  A1    PA1
#define  A2    PA2
#define  A3    PA3
#define  A4    PA4
#define  A5    PA5
#define  A6    PA6
#define  A7    PA7
#define  A8    PB0
#define  A9    PB1
#define  PHI2  PB2
#define  RWB   PB3
#define  SSA   PB4
#define  MOSI  PB5
#define  MISO  PB6
#define  SCK   PB7
#define  D0    PC0
#define  D1    PC1
#define  D2    PC2
#define  D3    PC3
#define  D4    PC4
#define  D5    PC5
#define  D6    PC6
#define  D7    PC7
#define  RX    PD0
#define  TX    PD1
#define  A10   PD2
#define  A11   PD3
#define  A12   PD4
#define  A13   PD5
#define  A14   PD6
#define  A15   PD7

#define  PHI2_PORT  PORTB
#define  RWB_PORT   PINB
#define  SS_PORT    PORTB


#define  LOW  0
#define  HIGH  1
#define  INPUT  0
#define  OUTPUT  1
#define  WRITE  0
#define  READ  1
#define  ALL_INPUTS  0x00
#define  ALL_OUTPUTS  0xff

#define  level_at( port, pin )  ( (port >> pin) & 0x1 )
#define  drive_low( port, pin )  port &= ~_BV( pin )
#define  drive_high( port, pin )  port |= _BV( pin )

#define  drive_clock( clock )   if ( LOW == clock ) drive_low( PHI2_PORT, PHI2 ); else drive_high( PHI2_PORT, PHI2 )
#define  decoded_address_lo()   PINA
#define  decoded_address_hi()   ( (PIND & 0xfc) | (PINB & 0x03) )
#define  level_at_RWB()         level_at( PINB, RWB )
// Configure the data bus pins as OUTPUTs only *after* the data has been loaded
// in to the PORT to prevent them changing value momentarily
#define  drive_data_bus( data)  PORTC = data; DDRC = ALL_OUTPUTS
// Configure all data bus pins as INPUT ( High-Z )
// Enable pull-ups rather than only for pins where data was last driven 1
#define  release_data_bus()     PORTC = 0xff; DDRC = ALL_INPUTS

/* For ATmega32
#define  UCSR0A  UCSRA
#define  UCSR0B  UCSRB
#define  UCSR0C  UCSRC
#define  UDRE0    UDRE
#define  UDR0    UDR
#define  RXC0    RXC
#define  TXC0    TXC
#define  U2X0    U2X
#define  MPCM0    MPCM
#define  RXCIE0    RXCIE
#define  TXCIE0    TXCIE
#define  UDRIE0    UDRIE
#define  RXEN0    RXEN
#define  TXEN0    TXEN
#define  UCSZ02    UCSZ2
#define  UMSEL00    UMSEL0
#define  UPM00    UPM0
#define  USBS0    USBS
#define  UCSZ00    UCSZ0
#define  UMSEL0    UMSEL
#define  UCPOL0    UCPOL
*/

typedef struct
{
  // these functions used to have an "address" parameter but "address" is now
  // global for performance ( need not be pushed on stack.  Often only LO byte
  // is used anyway).
  uint8_t  (*read)();
  void  (*write)( uint8_t data );
}
Device;

uint8_t   address_hi = 0x00;
uint8_t   address_lo = 0x00;
#define  address  ( (uint16_t)address_hi << 8 | address_lo )


#define  NO_SLAVE_SELECTED  7

uint8_t volatile  selected_slave_id = NO_SLAVE_SELECTED;

bool  debug_spi = false;


// --------------------------------------------------------------- simulated RAM

uint8_t  ram[ 1024 * 8 ];


uint8_t  read_from_RAM()
{
  return ram[ address]; // RAM isn't mirrored so there's no need for a mask.  In it's 15K state a mask wouldn't work anyway
}


void  write_to_RAM( uint8_t data )
{
  ram[ address] = data;
}


void static  init_RAM( Device *d )
{
  // Fill the simulated RAM with NOPs
  for ( int  a = 0;  a < sizeof(ram);  a += 1 )
    ram[ a] = 0xea; // NOP

  d->read = read_from_RAM;
  d->write = write_to_RAM;
}


// --------------------------------------------------------------- simulated ROM

uint8_t  rom[ 1024 * 4 ]; // Totally minimal but writable via UART.  Can hold bootstrap to RAM code until I finalise the ROM enough to go in to program memory

#define  ROM_ADDRESS_MASK  ( sizeof( rom) - 1 )


uint8_t  read_from_ROM()
{
  return rom[ address & ROM_ADDRESS_MASK];
}


void  write_to_ROM( uint8_t data )
{
  rom[ address & ROM_ADDRESS_MASK] = data;
}


void static  init_ROM( Device *d )
{
  uint16_t  rom_start = 0xff00;
  // Fill the simulated ROM with NOPs
  for ( int  a = 0;  a < sizeof(rom);  a += 1 )
    rom[ a] = 0xea; // NOP
  // .except for the RESET vector, which points to `rom_start`
  rom[ 0xfffc & ROM_ADDRESS_MASK] = rom_start & 0xff;
  rom[ 0xfffd & ROM_ADDRESS_MASK] = rom_start >> 8;
  // The IRQ and NMI vectors should be initialized for good measure
  rom[ 0xfffa & ROM_ADDRESS_MASK] = rom_start & 0xff;
  rom[ 0xfffb & ROM_ADDRESS_MASK] = rom_start >> 8;
  rom[ 0xfffe & ROM_ADDRESS_MASK] = rom_start & 0xff;
  rom[ 0xffff & ROM_ADDRESS_MASK] = rom_start >> 8;
  // Put an infinite loop at the beginning of the ROM until the real ROM is
  // loaded via UART.
  rom[ rom_start & ROM_ADDRESS_MASK] = 0x4c; // JMP
  rom[ (rom_start+1) & ROM_ADDRESS_MASK] = rom_start & 0xff;
  rom[ (rom_start+2) & ROM_ADDRESS_MASK] = rom_start >> 8;

  d->read = read_from_ROM;
  d->write = write_to_ROM;
}


// --------------------------------------------------------- Master control UART

char    received[ 16]; // A place to hold a line received over the serial link
uint8_t rx_cursor = 0; // Where the next character received should go in "received"
bool    line_too_long = false; // Indicates that the line received was too long and has been truncated
bool    echo = 1; // Indicates whether characters should be echoed back over the link
#define  NUL  '\0'


void static  send_byte( uint8_t data )
{
  // Wait for the transmit buffer to be ready
  loop_until_bit_is_set( UCSR0A, UDRE0);

  UDR0 = data;
}


bool static inline  byte_has_been_received()
{
  return (UCSR0A >> RXC0) & 0x1;
}


uint8_t static  receive_byte()
{
  while ( ! byte_has_been_received() );
  return UDR0;
}


uint16_t static  receive_int16()
{
  return receive_byte() | (uint16_t)receive_byte() << 8;
}


/*
// Provides the value of a digit given its hexadecimal representation, or -1 on
// error
//
int8_t static value_of_hex_digit( char digit_representation)
{
  if ( '0' <= digit_representation  &&  digit_representation <= '9')
  {
    return digit_representation - '0';
  }
  else if ( 'a' <= digit_representation  &&  digit_representation <= 'f')
  {
    return 10 + digit_representation - 'a';
  }
  else {
    return -1;
  }
}


uint8_t static value_of_hex_byte( char *data, int offset)
{
  return ( value_of_hex_digit( data[offset]) << 4) |
         value_of_hex_digit( data[offset+1]);
}


uint16_t static  gethex16()
{
  return value_of_hex_digit(receive_byte()) << 12
       | value_of_hex_digit(receive_byte()) << 8
       | value_of_hex_digit(receive_byte()) << 2
       | value_of_hex_digit(receive_byte())
       ;
}
*/

// Sends a single character over the serial link.
//
void static inline  send_char( char c)
{
  // Automatically turn LF characters into CRLF combos
  if ('\n' == c) {
    send_byte('\r');
  }
  send_byte( c );
}


#define  send_str( s )  _send_str(PSTR(s))

// Sends the given message from program memory over the serial link.
//
void static  _send_str( char const *s )
{
  while ( true)
  {
    char  c = pgm_read_byte( s );
    send_char( c);
    if ( NUL == c)
      break;
    s += 1;
  }
}


void static  send_eol()
{
  send_char('\n');
}


void static  send_hex4 (uint8_t value)
{
  // This uses 18!? bytes less RAM *and* 22 bytes less program memory
  char static const hex_digit_for[] PROGMEM = "0123456789abcdef";
  send_char (pgm_read_byte (&hex_digit_for [value]));
}


// Sends the hexadecimal representation of the given byte over the serial link.
//
void static  send_hex8 (uint8_t value)
{
  send_hex4 (value >> 4);
  send_hex4 (value & 0xf);
}


void static  send_bool (bool value)
{
  send_byte (value ? 't' : 'f');
}


void static  send_level( uint8_t logic_level )
{
  send_byte( logic_level ? 'H' : 'L');
}


/*
void static  db( char *msg, uint8_t value )
{
  send_msg_P( msg);
  send_char(' ');
  send_hex8( value );
  send_eol();
}
*/

void static  init_Master_UART()
{
  UCSR0A = ( USE_2X << U2X0 )
         | ( 0 << MPCM0)
         ;
  // 3: 8-bit
  #define  CHARACTER_SIZE  3
  UCSR0B = ( 0 << RXCIE0 )  // 1:Enable RX interrupts
         | ( 0 << TXCIE0 )
         | ( 0 << UDRIE0 )
         | ( 1 << RXEN0 )   // 1:Enable RX
         | ( 1 << TXEN0 )   // 1:Enable TX
         | ( (CHARACTER_SIZE >> 2) << UCSZ02 )
         ;
  UCSR0C = ( (0 & 0x3) << UMSEL00 )  // 0:Asynchronous UART, 1:Synchronous UART, 2:Reserved, 3:Master SPI
         | ( (0 & 0x3) << UPM00 )   // 0:No parity
         | ( 0 << USBS0 )   // 0:1 STOP bit
         | ( (CHARACTER_SIZE & 0x3) << UCSZ00 )
         | ( 0 << UCPOL0 )  // Ignore in asynchronous mode
         ;
  UBRR0 = UBRR_VALUE;
  /* This is different for the ATmega32 and the ATmega1284P
  UCSR0C = ( 1 << URSEL )
         | ( 0 << UMSEL0 )  // 0:Asynchronous UART, 1:Synchronous UART
         | ( (0 & 0x3) << UPM0 )   // 0:No parity
         | ( 0 << USBS )   // 0:1 STOP bit
         | ( (CHARACTER_SIZE & 0x3) << UCSZ0 )
         | ( 0 << UCPOL )  // Ignore in asynchronous mode
         ;
  UBRRH = UBRRH_VALUE;
  UBRRL = UBRRL_VALUE;
         */
}


// --------------------------------------------------------------- simulated SPI

// @return  The data received
//
uint8_t  spi_exchange( uint8_t  data_to_send )
{
  #ifdef _SPI_DEBUG
  send_str("SPIX ");
  send_hex8( data_to_send );
  send_eol();
  #endif

  // Select the Slave AVR
  drive_low( SS_PORT, SSA );
  // Give the slave time to synchronize ( reset its SPI bit counter).  Guess 2 + 16 + 3 + 3 + 4 + 17 instructions for ISR?
  // Assume 80 cycles at 18 MHz ~ 90 cycles at 20 MHz
  _delay_loop_1( 30 * 2); // 3 cycles per iteration ( doesn't include setup).  * 2 for safety.  FIXME: Tune by reducing until unstable then backing off
  // Initiate the transfer
  SPDR = data_to_send;
  // Wait until the transfer has finished
  loop_until_bit_is_set( SPSR, SPIF );
  // Take a copy of the data received
  uint8_t  data_received = SPDR;
  // Release the Slave AVR
  drive_high( SS_PORT, SSA );

  return data_received;
}


uint8_t  SPI_read()
{
  uint8_t  data;

  #ifdef _SPI_DEBUG
  send_str("SPI.read ");
  send_hex8( address_lo );
  send_byte('>');
  #endif

  switch ( address_lo & 0x3 ) // & to simulate only low-order address lines being connected to Register Select lines
  {
    case 0x00: // Data
      data = SPDR;
      break;

    case 0x01: // Status and Control
      {
      uint8_t  mode = SPCR;
      uint8_t  status = SPSR;
      data = level_at(status, SPIF) << 7 // TC
           | ( 0 << 6 ) // IER
           | ( 1 << 5 ) // BSY
           | ( 0 << 4 ) // FRX
           | ( 0 << 3 ) // TMO
           | ( 0 << 2 ) // ECE
           | ( level_at(mode,CPOL) << 1 ) // CPOL
           | ( level_at(mode,CPHA) << 0 ) // CPHA
           ;
      }
      break;

    case 0x02: // Clock rate
      data = 0xff; // Write-only at this time
      break;

    case 0x03: // Slave select
      data = 0xff; // Write-only at this time
      break;

    default:
      data = 0xff;
  }

  #ifdef _SPI_DEBUG
  send_hex8( data);
  send_eol();
  #endif

  return data;
}


void  SPI_write( uint8_t data )
{
  #ifdef _SPI_DEBUG
  send_str("SPI.write ");
  send_hex8( address_lo );
  send_byte(',');
  send_hex8( data );
  send_str(", SPCR:");
  send_hex8( SPCR );
  send_eol();
  #endif

  switch ( address_lo & 0x3 ) // & to simulate only low-order address lines being connected to Register Select lines
  {
    case 0x00: // Data
      SPDR = data;
      break;

    case 0x01: // Status and Control
      if ( (data >> 1 & 0x1) == 1 ) // CPOL
        SPCR |= 1 << CPOL;
      else
        SPCR &= ~(1 << CPOL);

      if ( (data >> 0 & 0x1) == 1 ) // CPHA
        SPCR |= 1 << CPHA;
      else
        SPCR &= ~(1 << CPHA);

      break;

    case 0x02: // Clock rate
      {
        // FIXME: If the 6502 changes the clock rate then it affects inter-AVR
        // exchanges too.  Perhaps maintain a set of shadow registers for the
        // 6502's configuration of the Master AVR's SPI peripheral
        uint8_t  divisor = data & 0x7;
        uint8_t  spr;
        bool     dbl;
        switch ( divisor )
        {
          case 1: dbl=true;  spr=0; break;
          case 2: dbl=false; spr=0; break;
          case 3: dbl=true;  spr=1; break;
          case 4: dbl=false; spr=1; break;
          case 5: dbl=true;  spr=2; break; // 2**5 is 32
          case 6: dbl=false; spr=2; break;
          case 7: dbl=false; spr=3; break;
          default: dbl=false, spr=3; break;
        }
        SPCR = (SPCR & ~(0x3 << SPR0)) | ( spr << SPR0);
        if ( dbl )
          SPSR |= SPI2X;
        else
          SPSR &= ~SPI2X;
      }
      break;

    case 0x03: // Slave select
      {
      uint8_t  slave_id = data & 0x7;
      if (debug_spi)
      {
        send_char ('S');
        send_hex8 ((selected_slave_id << 4) | slave_id);
      }
      // Currently the 6502 does not communicate directly with the Slave AVR,
      // so Slave#7 can be used to indicate that no slave should be selected
      //spi_exchange( (slave_id < 7) ? (SELECT_SLAVE_0 + slave_id) : RELEASE_SLAVE );
      // Optimised ( because RELEASE_SLAVE is the same as SELECT_SLAVE_0 + 7)
      spi_exchange( SELECT_SLAVE_0+ slave_id );

      // Remember which slave is selected ( if any) so that UART operations
      // ( and any other in future that involve communication with the slave
      // AVR) may be buffered
      selected_slave_id = slave_id;
      }
      break;
  }
}


void static  init_SPI( Device *device )
{
  // CPOL | CPHA | SPI mode
  //    0 |    0 |        0
  //    0 |    1 |        1
  //    1 |    0 |        2
  //    1 |    1 |        3
  SPCR = ( 0 << SPIE ) // 1:Interrupts
       | ( 1 << SPE )  // 1:Enable
       | ( 0 << DORD ) // 0:MSB first
       | ( 1 << MSTR ) // 1:Master 0:Slave
       | ( 0 << CPOL ) // 0:SCK is low at rest 1:SCK is high at rest
       | ( 0 << CPHA ) // For CPOL:0, 0:Data sampled on rising edge and changed on falling edge, 1:Opposite.  For CPOL:1, the other way around
       | ( (3 & 0x3) << SPR0 ) // 0..3 to divide F_CPU by 4, 16, 64, 128 or half these if SPI2X is 1
       ;
  // The Slave AVR is clocked at 18.432 MHz and the SPI clock must not be
  // faster than 18.432 / 4
  SPSR = ( 0 << SPIF ) // 1:Exchange complete
       | ( 0 << WCOL )  // 1:Write collision
       | ( 0 << SPI2X ) // 1:Double clock speed
       ;

  // NOTE: PB4 MUST be configured as an output when in SPI master mode
  // otherwise if it goes low ( even in SPI master mode) then the SPI system
  // will revert to slave mode!

  // Process:
  //  - Configure
  //  - Write to SPDR
  //  - Wait for SPIF:1
  //  - Read from SPSR ( Done already when checked SPIF)
  //  - Read from SPDR

  device->read = SPI_read;
  device->write = SPI_write;
}


// -------------------------------------------------------------- simulated UART
/*
// Simulated register file:
//  00  Status:
//        Bit#0: 0:No data received, 1:Data received.  Read from register 01
//        Bit#1: 0:Busy.  Please wait.  1:Ready.  Please send with register 01
//  01  Data:
//        Read: Provides the data received.  Undefined if no data has been received
//        Write: Accepts data to send.  Behaviour undefined if already busy sending
//
uint8_t  UART_read()
{
  switch ( address_lo & 0x1 ) // & to simulate only low-order address lines being connected to Register Select lines
  {
    case 0x00:
      {
      uint8_t  status = UCSR0A;
      return  level_at(status, UDRE0) << 1 | level_at(status, RXC0);
      }

    case 0x01:
      return UDR0;

    default:
      return 0xff;
  }
}


void  UART_write( uint8_t  data )
{
  switch ( address_lo & 0x1 ) // & to simulate only low-order address lines being connected to Register Select lines
  {
    case 0x00:
      // Error: Nothing to write in the Status register at the moment
      break;

    case 0x01:
      UDR0 = data;
  }
}
*/

// Simulated register file:
//  00  Status:
//        Bit#0: 0:No data received, 1:Data received.  Read from register 01
//        Bit#1: 0:Busy.  Please wait.  1:Ready.  Please send with register 01
//  01  Data:
//        Read: Provides the data received.  Undefined if no data has been received
//        Write: Accepts data to send.  Behaviour undefined if already busy sending
//
uint8_t  UART_read()
{
  // FIXME: Buffer all access to the UART if an off-board slave is selected
  switch ( address_lo & 0x1 ) // & to simulate only low-order address lines being connected to Register Select lines
  {
    case 0x00:
      spi_exchange( QUERY_UART_STATUS );
      return spi_exchange( POLL );

    // The Slave doesn't have a way to interrupt the Master, and the master doesn't poll, so the slave queues.  it might:
    //  a) interrupt the 6502, in which case would 115,200 be enough to ever result in a queue length > 1?
    //  b) not interrupt, in which case the 6502 polls and queueing is definitely required ( probably good.  10 Hz is enough for UI update)
    case 0x01:
      spi_exchange( DEQUEUE_UART_DATA );
      return spi_exchange( POLL );
  }
  return 0xff; // Will never happen but compiler doesn't know that
}

void  UART_write( uint8_t  data )
{
  // FIXME: Buffer all access to the UART if an off-board slave is selected
  switch ( address_lo & 0x1 ) // & to simulate only low-order address lines being connected to Register Select lines
  {
    case 0x00:
      // Error: Nothing to write in the Status register at the moment
      break;

    case 0x01:
      spi_exchange( SEND_VIA_UART );
      spi_exchange( data );
  }
}


void static  init_UART( Device *device )
{
  device->read = UART_read;
  device->write = UART_write;
}


// ----------------------------------------------------------- simulated EEPRROM

uint8_t  read_from_EEPROM()
{
  uint8_t  data = 0xea; // NOP
  #ifdef _EEPROM_DEBUG
  send_str("EEPROM.read ");
  send_hex8( address_lo );
  send_byte('>');
  #endif

  // FIXME: Implement

  #ifdef _EEPROM_DEBUG
  send_hex8( data);
  send_eol();
  #endif

  return data;
}


void  write_to_EEPROM( uint8_t data )
{
  #ifdef _EEPROM_DEBUG
  send_str("EEPROM.write ");
  send_hex8( address_hi );
  send_hex8( address_lo );
  send_byte(',');
  send_hex8( data );
  send_eol();
  #endif

  // FIXME: Implement
}


void static  init_EEPRROM( Device *d )
{
  d->read = read_from_EEPROM;
  d->write = write_to_EEPROM;
}


// ----------------------------------------------------------------- application

uint8_t   clock = 0; // 0 or 1
uint8_t   operation_requested = 0; // 0:Write or 1:Read
uint8_t   latched_data = 0x00;
uint8_t   data_to_drive = 0xea;
bool      should_run = false; // Single-stepping or Free-running
bool      slow_mode = true; // Whether the status of the address lines should be sent to the UART at the end of each half cycle


typedef enum
{
  RAM,
  ROM,
  UART,
  SPI,
  EEPROM,
}
DeviceId;

DeviceId  addressed_device_id;

Device  devices[5];

void static inline  init_devices()
{
  init_RAM( &devices[0]);
  init_ROM( &devices[1]);
  init_UART( &devices[2]);
  init_SPI( &devices[3]);
  init_EEPRROM( &devices[4]);
}

Device *addressed_device;


void static  report()
{
  send_str("PHI2: "); send_level( clock);
  //send_str(", RESB: "); send_level( level_at_RESB()); // FIXME: Show what we expect RESB *should* be based on the last requested level
  send_str(", ADDR: "); send_hex8( address_hi); send_hex8( address_lo);
  send_str(", RWB: "); send_level( operation_requested);
  send_str(", DATA: "); send_hex8( operation_requested == READ ? data_to_drive : latched_data );
  send_eol();
}


void static inline  half_cycle()
{
  // If the clock is about to RISE
  if ( clock == HIGH )
  {
    // Latch the address and RWB lines now because the AVR might not be fast
    // enough to do so after the clock rises
    address_lo = decoded_address_lo();
    address_hi = decoded_address_hi();
    operation_requested = level_at_RWB();
    // If the 6502 has indicated that it wished to WRITE then it will begin
    // driving the data bus lines at some point before the clock falls and so
    // the AVR should configure its data bus pins as inputs NOW in order to
    // avoid bus contention
    // The ONLY scenario in which the data bus should be driven is when an
    // internal device is addressed and a READ is requested
    //if ( ! ( addressed_device_id != RAM  && operation_requested == READ ) ) // FIXME: Re-enable with external RAM
    if ( operation_requested == WRITE )
    {
      release_data_bus();
    }
    // The 16-bit address space is divided in to 256 256-byte pages.  This is a
    // lookup table keyed by page number to determine which device is mapped to
    // that page.  Each row is 4K = 256*16
    DeviceId static  DEVICE_IN_PAGE[256] = {
      RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, // $0000
      RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, // $1000
      //RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, // $2000
      //RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, RAM, SPI, SPI, SPI, SPI, // $3000
      SPI, UART, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, // $2000
      SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, SPI, // $3000
      EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, EEPROM, // $4000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $5000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $6000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $7000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $8000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $9000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $a000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $b000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $c000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $d000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $e000
      ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, ROM, // $f000
    };
    addressed_device_id = DEVICE_IN_PAGE[ address_hi];
    /*
    if ( address_15 == 0 )
      addressed_device_id = RAM;
    else {
      addressed_device_id = address < 0x4 ? SPI : address < 0x6 ? UART : ROM;
    }
    */
    addressed_device = &devices[ addressed_device_id];
  }
  // If the clock is about to FALL..
  else {
    // ..and the 6502 wishes to WRITE then then the data lines should be
    // latched because the 6502 will only keep the data bus lines valid for a
    // short time after the clock falls and that might not be long enough for
    // software to latch them
    if ( operation_requested == WRITE )
      latched_data = PINC;
  }

  // The clock should be toggled
  drive_clock( clock );

  // If the clock has RISEN
  if ( clock == HIGH )
  {
    // If the RAM was addressed then enable the RAM chip
    /*
    if ( RAM == addressed_device_id  &&  false ) // FIXME: Remove "&& false" when using external RAM
    {
      enable_RAM();
    }
    // If an internal device was adressed then:
    else {
      //  - Disable the RAM chip
      disble_RAM();
    */
      // If the 6502 is READING then
      if ( operation_requested == READ )
      {
        //  - Read the specified address / register from the addressed device
        data_to_drive = addressed_device->read();
        //data_to_drive = 0xea;
        //  - Drive the data bus with the value read
        drive_data_bus( data_to_drive);
      }
    //}
  }
  else {  // the clock has FALLEN
    // If the 6502 is writing and the addressed device is internal ( i.e. not the RAM chip) then:
    //  - Write the latched data to the address / register of the device
    //if ( addressed_device != RAM  &&  operation_requested == WRITE )
    if ( operation_requested == WRITE ) // FIXME: Not if the external RAM is enabled
    {
      addressed_device->write( latched_data );
    }
  }

  if ( slow_mode )
  {
    report();

    _delay_ms( 500);
  }

  clock ^= 1;
}


// This is separate from half_cycle() so that half_cycle() does not have to
// check if currently resetting during normal operation.  Real peripherals
// would have their RESB inputs LOW during reset, so no peripherals should
// respond.
//
void static  half_cycle_during_reset()
{
  // If the clock is about to RISE
  if ( clock == HIGH )
  {
    // Latch the address and RWB lines now because the AVR might not be fast
    // enough to do so after the clock rises
    address_lo = decoded_address_lo();
    address_hi = decoded_address_hi();
    operation_requested = level_at_RWB();
    // If the 6502 has indicated that it wished to WRITE then it will begin
    // driving the data bus lines at some point before the clock falls and so
    // the AVR should configure its data bus pins as inputs NOW in order to
    // avoid bus contention
    if ( operation_requested == WRITE )
    {
      release_data_bus();
    }
  }

  // The clock should be toggled
  drive_clock( clock );

  // If the clock has RISEN
  if ( clock == HIGH )
  {
    // If the 6502 is READING then
    if ( operation_requested == READ )
    {
      drive_data_bus( 0xea); // NOP
    }
  }

  if ( slow_mode )
  {
    report();

    _delay_ms( 500);
  }

  clock ^= 1;
}


void static  wait( uint8_t cycles )
{
  for ( ;  0 < cycles;  cycles -= 1 )
  {
    half_cycle_during_reset();
    half_cycle_during_reset();
  }
}


void static  reset()
{
  // "The RESB signal must be held low for at least two clock cycles after VDD
  // reaches operating voltage."
  drive_clock( HIGH ); _delay_ms( 1);
  // request RESB low: NO-op since begins low on slave
  spi_exchange( ASSERT_RESB );
  wait( 2);
  spi_exchange( RELEASE_RESB );
  // "When a positive edge is detected, there will be a reset sequence lasting
  // seven clock cycles."
  wait( 6); // If this is 7, the microprocessor JMPs to $ffea instead of $ff00 because the ROM wasn't being simulated yet
}


void static  init()
{
  // Configure pins.  0:Input, 1:Output
  DDRA = ( INPUT << A0 )
       | ( INPUT << A1 )
       | ( INPUT << A2 )
       | ( INPUT << A3 )
       | ( INPUT << A4 )
       | ( INPUT << A5 )
       | ( INPUT << A6 )
       | ( INPUT << A7 )
       ;
  DDRB = ( INPUT << A8 )
       | ( INPUT << A9 )
       | ( OUTPUT << PHI2 )
       | ( INPUT << RWB )
       | ( OUTPUT << SSA )
       | ( OUTPUT << MOSI )
       | ( INPUT << MISO )
       | ( OUTPUT << SCK )
       ;
  DDRC = ( OUTPUT << D0 )
       | ( OUTPUT << D1 )
       | ( OUTPUT << D2 )
       | ( OUTPUT << D3 )
       | ( OUTPUT << D4 )
       | ( OUTPUT << D5 )
       | ( OUTPUT << D6 )
       | ( OUTPUT << D7 )
       ;
  DDRD = ( INPUT <<  RX )
       | ( INPUT <<  TX )  // Not required as OUTPUT because UART alternative function configured
       | ( INPUT << A10 )
       | ( INPUT << A11 )
       | ( INPUT << A12 )
       | ( INPUT << A13 )
       | ( INPUT << A14 )
       | ( INPUT << A15 )
       ;

  // Activate pull-ups on all input pins to avoid flapping if disconnected.  Pull-ups are weak anyway (47k)
  PORTA = 0xff;
  PORTB = _BV( A8) | _BV( A9) | _BV( RWB) | _BV( MISO) | _BV( SSA); // SS is not an input but should be HIGH by default
  PORTD = _BV( RX) | _BV( TX) | _BV( A10) | _BV( A11) | _BV( A12) | _BV( A13) | _BV( A14) | _BV( A15);

  init_Master_UART();

  // Registers to consider initializing ( if only for low-power mode)
  // TWI
  // ADC
  // Don't bother for now: that's polish.  get it working first
  init_devices();

  send_str("Initialization in progress..\n");

  // TODO: Reset sequence.  hmm what if timing (2+7 cycles) is different? maybe
  // better to have in main loop.  CPU can't possibly pull RWB low during Reset
  // or random would happen in all systems ( unless all bus devices have RESET
  // too?)
  drive_data_bus( 0xea); // NOP
  drive_clock( HIGH );

  reset();
}


// This "sink" concept isn't really used and could be simplified but is left
// here to remind me of the technique of dispatching received bytes depending
// on state.
//
void static  main_sink( uint8_t request_type );


void  (*data_sink)( uint8_t value ) = &main_sink;


void static  upload_ROM()
{
  // 16-bit target
  uint16_t  write_head = receive_int16();
  // 16-bit length
  uint16_t  bytes = receive_int16();
  // bytes
  while ( 0 < bytes )
  {
    rom[ write_head & ROM_ADDRESS_MASK] = receive_byte();
    write_head += 1;
    bytes -= 1;
  }
}


void static  download( uint8_t *data, uint16_t bytes, uint16_t base_address )
{
  // 16-bit target
  send_byte( base_address & 0xff );
  send_byte( base_address >> 8 );
  // 16-bit length
  send_byte( bytes & 0xff );
  send_byte( bytes >> 8 );
  // Send the data
  for ( uint16_t  a = 0;  a < bytes;  a += 1 )
  {
    send_byte( data[a] );
  }
}


void static  main_sink( uint8_t request_type )
{
  switch ( request_type )
  {
    case 's': // single step
      slow_mode = true;
      should_run = false;
      half_cycle();
      break;

    case 't': // trace
      debug_spi ^= true;
      send_str ("debug_spi:");  send_bool (debug_spi);
      break;

    case 'f': // fast
      should_run = true;
      slow_mode = false;
      break;

    case 'c': // continue
      should_run = true;
      break;

    case 'p': // pause
      should_run = false;
      break;

    case 'u': // upload
      upload_ROM();
      break;

    case 'd': // download ROM
      download( rom, sizeof(rom), 65536 - sizeof(rom) );
      break;

    case 'D': // download RAM
      download( ram, sizeof(ram), 0x0000 );
      break;

    case 'r': // reset
      reset();
      break;
  }
}


void static  poll_UART()
{
  if ( byte_has_been_received() )
  {
    data_sink( receive_byte() );
  }
}


void static inline  loop()
{
  // TODO: inline after reset is proven
  if ( should_run )
    half_cycle();
  // FIXME: Don't poll the serial so often.  20 MHz, 38,400 baud ~52 cycles between characters
  poll_UART();
}


int main()
{
  init();

  while ( true)
  {
    loop();
  }
}

