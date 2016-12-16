/*

Neil's 6502 R2, "monitor" AVR (for writing directly to SRAM from a PC).

Lines shared between FPGA and monitor:
- A*, D*, RESB, RWB, STOP GO PHI2

*/

#include <stdbool.h>
#include <stdint.h>

#include <avr/io.h>
#include <avr/pgmspace.h>
#include <util/delay.h>
#define BAUD 115200
#include <util/setbaud.h>

#include "wiring.h"


// ------------------------------------------------------------------------ UART

char    received [16]; // A place to hold a line received over the serial link
uint8_t rx_cursor = 0; // Where the next character received should go in "received"
bool    line_too_long = false; // Indicates that the line received was too long and has been truncated
bool    echo = 1; // Indicates whether characters should be echoed back over the link
#define  NUL  '\0'


void static  setup_UART ()
{
  UCSR0A = (USE_2X << U2X0)
         | (0 << MPCM0)
         ;
  // 3: 8-bit
  #define  CHARACTER_SIZE  3
  UCSR0B = (0 << RXCIE0)  // 1:Enable RX interrupts
         | (0 << TXCIE0)
         | (0 << UDRIE0)
         | (1 << RXEN0)   // 1:Enable RX
         | (1 << TXEN0)   // 1:Enable TX
         | ((CHARACTER_SIZE >> 2) << UCSZ02)
         ;
  UCSR0C = ((0 & 0x3) << UMSEL00)  // 0:Asynchronous UART, 1:Synchronous UART, 2:Reserved, 3:Master SPI
         | ((0 & 0x3) << UPM00)   // 0:No parity
         | (0 << USBS0)   // 0:1 STOP bit
         | ((CHARACTER_SIZE & 0x3) << UCSZ00)
         | (0 << UCPOL0)  // Ignore in asynchronous mode
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


bool static inline  byte_has_been_received ()
{
  //return (UCSR0A >> RXC0) & 0x1;
  return bit_is_set (UCSR0A, RXC0);
}


void static  send_byte (uint8_t data)
{
  // Wait for the transmit buffer to be ready
  loop_until_bit_is_set (UCSR0A, UDRE0);

  UDR0 = data;
}



uint8_t static  receive_byte ()
{
  while (! byte_has_been_received());
  return UDR0;
}


uint16_t static  receive_int16 ()
{
  return receive_byte() | (uint16_t)(receive_byte() << 8);
}


// Provides the value of a digit given its hexadecimal representation, or -1 on
// error
//
int8_t static  value_of_hex_digit (char digit_representation)
{
  if ('0' <= digit_representation  &&  digit_representation <= '9')
  {
    return digit_representation - '0';
  }
  else if ('a' <= digit_representation  &&  digit_representation <= 'f')
  {
    return 10 + digit_representation - 'a';
  }
  else {
    return -1;
  }
}


uint8_t static  value_of_hex_byte (char *data, int offset)
{
  return (value_of_hex_digit (data [offset]) << 4) |
         value_of_hex_digit (data [offset + 1]);
}

/*
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
void static inline  send_char (char c)
{
  // Automatically turn LF characters into CRLF combos
  if ('\n' == c) {
    send_byte('\r');
  }
  send_byte( c );
}


#define  send_str( s)  _send_str (PSTR (s))

// Sends the given message from program memory over the serial link.
//
void static  _send_str (char const *s)
{
  while (true)
  {
    char  c = pgm_read_byte (s);
    send_char (c);
    if (NUL == c)
      break;
    s += 1;
  }
}


void static  send_eol ()
{
  send_char ('\n');
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


// Sends the hexadecimal representation of the given 16-bit value over the serial link.
//
void static  send_hex16 (uint16_t value)
{
  send_hex8 (value >> 8);
  send_hex8 (value & 0xff);
}

/*
void static  send_bool (bool value)
{
  send_byte (value ? 't' : 'f');
}
*/


void static  send_level (uint8_t logic_level)
{
  send_byte (logic_level ? 'H' : 'L');
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

void static  setup ()
{
  // Configure pins
  /*
  DDRA = (INPUT << A8)
       | (INPUT << A9)
       | (INPUT << A10)
       | (INPUT << A11)
       | (INPUT << A12)
       | (INPUT << A13)
       | (INPUT << A14)
       | (INPUT << A15)
       ;
  DDRB = (INPUT << A0)
       | (INPUT << A1)
       | (INPUT << A2)
       | (INPUT << A3)
       | (INPUT << A4)
       | (INPUT << A5)
       | (INPUT << A6)
       | (INPUT << A7)
       ;
  DDRC = (INPUT << D0)
       | (INPUT << D1)
       | (INPUT << D2)
       | (INPUT << D3)
       | (INPUT << D4)
       | (INPUT << D5)
       | (INPUT << D6)
       | (INPUT << D7)
       ;
  */
  release_address_bus ();
  release_data_bus ();
  DDRD = (INPUT <<  RX)
       | (INPUT <<  TX)  // Not required as OUTPUT because UART alternative function configured
       | (OUTPUT <<  RESB)
       | (INPUT <<  RWB)  // Driven when 6502 disabled
       | (OUTPUT <<  STOP)
       | (OUTPUT <<  GO)
       | (OUTPUT <<  BE)
       | (INPUT <<  PHI2)
       ;

  // Activate pull-ups on all input pins to avoid flapping if disconnected.  Pull-ups are weak anyway (47k)
  PORTD = _BV (RX) | _BV (TX) | _BV (RWB) | _BV (GO) | _BV (PHI2);

  setup_UART();

  send_str("Initialization in progress..\n");
}


void static  release_buses ()
{
  // PHI2 should be low before A* and RWB are released (to an unknown state
  // since the 6502 is not yet reconnected)
  drive_PHI2_low();
  release_data_bus ();    // To be driven by 6502 or weakly pulled HIGH (0xff) by Monitor
  release_RWB ();         // To be driven by 6502 or weakly pulled HIGH (READ) by Monitor
  release_address_bus (); // To be driven by 6502 or weakly pulled HIGH (0xffff) by Monitor
  reconnect_6502_to_bus ();
}


uint8_t static  read_from_address (uint16_t address)
{
  // PHI2 must be low prior to disconnecting the 6502 from the bus because A*
  // and RWB may be in any state, which could cause random writes.  Reads of
  // I/O can have unwanted effects as well.
  drive_PHI2_low (); // While change address
  disconnect_6502_from_bus ();
  // Double-check that the data bus is not being driven before driving RWB HIGH
  // (meaning that a bus device will begin driving the data bus)
  release_data_bus ();
  RWB_read ();
  drive_address_bus (address);
  drive_RWB ();
  _delay_us (1);

  // PHI2 should be HIGH for SRAM to be selected
  drive_PHI2_high ();
  _delay_us (1);

  uint8_t  data = value_on_data_bus ();
  drive_PHI2_low ();
  return data;
}


void static  write_to_address (uint16_t address, uint8_t data)
{
  // PHI2 must be low prior to disconnecting the 6502 from the bus because A*
  // and RWB may be in any state, which could cause random writes.  Reads of
  // I/O can have unwanted effects as well.
  drive_PHI2_low (); // While change address
  disconnect_6502_from_bus ();
  // Double-check that the data bus is not being driven before driving RWB HIGH
  // (meaning that a bus device will begin driving the data bus)
  drive_address_bus (address);
  RWB_write ();
  drive_data_bus (data);
  drive_RWB ();
  _delay_us (1);

  // PHI2 should be HIGH for SRAM to be selected
  drive_PHI2_high ();
  _delay_us (1);  // Allow RAM to capture data

  drive_PHI2_low ();
}


void static  test_RAM ()
{
  disconnect_6502_from_bus ();

  // Write
  for (uint16_t  address = 0;;)
  {
    send_byte ('\r');
    send_hex16 (address);

    uint8_t  expected = (address & 1) == 0 ? (address & 0xff) : (address >> 8);
    write_to_address (address, expected);

    address += 1;
    if (address == 0)
      break;
  }

  // Verify
  for (uint16_t  address = 0;;)
  {
    send_byte ('\r');
    send_hex16 (address);

    uint8_t  expected = (address & 1) == 0 ? (address & 0xff) : (address >> 8);

    uint8_t  got = read_from_address (address);
    if (got != expected)
    {
      send_byte ('E');
      send_hex8 (got);
      send_eol ();
      break;
    }

    address += 1;
    if (address == 0)
      break;
  }

  release_buses ();
}


void static  fill_RAM_with_NOP ()
{
  disconnect_6502_from_bus ();

  for (uint16_t  address = 0;;)
  {
    write_to_address (address, 0xea);

    address += 1;
    if (address == 0)
      break;
  }

  release_buses ();
}


void static  dump_RAM (uint8_t addr_hi)
{
  disconnect_6502_from_bus ();

  for (uint16_t  address = addr_hi << 8;  address != (addr_hi << 8) + 512;  address += 1)
  {
    uint8_t  data = read_from_address (address);
    // FORMAT:
    // 0030  43 6c 61 73 73 65 73 00  5f 5f 54 4d 43 5f 45 4e
    if ((address & 0x0f) == 0)
    {
      send_hex16 (address);
      send_byte (' ');
      send_byte (' ');
    }

    send_hex8 (data);

    if ((address & 0x0f) != 0xf)
    {
      send_byte (' ');
      if ((address & 0x0f) == 0x7)
      {
        send_byte (' ');
      }
    }
    else {
      send_eol ();
    }
  }

  release_buses ();
}


void static  read_from_RAM ()
{
  // Read the rest of the request, which includes the base address from which
  // to begin reading and the number of bytes to read
  uint16_t  read_from_address = receive_int16 ();
  uint16_t  bytes_to_read = receive_int16 ();
  // PHI2 must be low prior to disconnecting the 6502 from the bus because A*
  // and RWB may be in any state, which could cause random writes.  Reads of
  // I/O can have unwanted effects as well.
  drive_PHI2_low ();
  disconnect_6502_from_bus ();
  // Double-check that the data bus is not being driven before driving RWB HIGH
  // (meaning that a bus device will begin driving the data bus)
  release_data_bus ();
  RWB_read ();
  drive_RWB ();
  drive_address_bus (0xfffc); // Should be safe to read from $fffc when PHI2 goes high
  // Send the data
  // PHI2 should be HIGH for SRAM to be selected
  drive_PHI2_high ();
  for (;  0 < bytes_to_read;  read_from_address += 1, bytes_to_read -= 1)
  {
    drive_address_bus (read_from_address);
    uint8_t  data = value_on_data_bus ();
    send_byte (data);
  }

  release_buses ();
}


void static  write_to_RAM ()
{
  // Read the rest of the request, which includes the base address at which to
  // write and the number of bytes to write
  uint16_t  write_to_address = receive_int16 ();
  uint16_t  bytes_to_write = receive_int16 ();
  // bytes
  release_data_bus (); // Shouldn't really be required
  drive_PHI2_low ();
  disconnect_6502_from_bus ();
  RWB_read ();
  drive_RWB ();
  drive_address_bus (0xfffc); // Should be safe to read from $fffc when PHI2 goes high
  drive_PHI2_high ();
  while (0 < bytes_to_write)
  {
    uint8_t  data = receive_byte ();
    drive_PHI2_low (); // Otherwise would write previous data to new address straight away
    drive_address_bus (write_to_address);
    RWB_write ();
    drive_data_bus (data);
    drive_PHI2_high ();
    write_to_address += 1;
    bytes_to_write -= 1;
  }

  release_buses ();
}


#define  report_level( label, level)  _report_level (PSTR (label), level);
void static _report_level (char const *label, bool level)
{
  _send_str (label);
  send_byte (':');
  send_level (level);
}


void static show_status ()
{
  report_level ("RESB", level_at (PIND, RESB));
  send_byte (' ');
  // The monitor does not have PHI2 wired, although PD7 is free, so
  // potentially it could, but then maybe SYNC or /CE0 might be more
  // useful?
  //report_level ("PHI2", level_at (PIND, PHI2));
  //send_byte (' ');
  // PHI2 <= GO for testing
  report_level ("PHI2", level_at (PIND, GO));
  send_byte (' ');
  report_level ("BE", level_at (PIND, BE));
  send_byte (' ');
  report_level ("STOP", level_at (PIND, STOP));
  send_byte (' ');
  send_str ("ADDR:");
  send_hex8 (PINA);
  send_hex8 (PINB);
  send_byte (' ');
  report_level ("RWB", level_at (PIND, RWB));
  send_byte (' ');
  send_str ("DATA:");
  send_hex8 (PINC);
  send_eol ();
}


void static  poll_UART ()
{
  // FIXME: Down side of this is that no commands should use hex 'a' .. f
  char static  previous [3];
  uint16_t static  latched_address = 0;

  if (byte_has_been_received())
  {
    uint8_t  request = receive_byte ();
    switch (request)
    {
      case 'A': // Latch address
        latched_address = (((uint16_t)value_of_hex_digit (previous [0]) << 8) | value_of_hex_byte (previous, 1));
        send_byte ('A');
        send_hex16 (latched_address);
        send_eol ();
        break;

      case 'B': // Test BE
        toggle (PORTD, BE);
        show_status ();
        break;

      case 'w': // Write data to latched address
        write_to_address (latched_address, value_of_hex_byte (previous, 1));
        show_status ();
        break;

      case 'F':
        // FIXME: This writes 0xea to I/O devices!
        fill_RAM_with_NOP ();
        send_str ("OK\n");
        break;

      case 'C': // Clock
        //DDRD ^= _BV (GO);
        //drive_low (PORTD, STOP);  // Doesn't work because it makes RDY 0
        toggle( PORTD, GO);
        show_status ();
        break;
      /*
      case 's': // single step
        slow_mode = true;
        should_run = false;
        half_cycle();
        break;

      case 'f': // fast
        should_run = true;
        slow_mode = false;
        break;

      case 'c': // continue
        should_run = true;
        break;

      case 'p': // pause
        //should_run = false;
        break;
      */
      case 'D': // Download from RAM
        read_from_RAM ();
        break;

      case 'r':
        //reset();
        drive_RESB_low ();
        show_status ();
        release_RESB (); // The FPGA should now hold RESB low for two cycles of PHI2
        show_status ();
        break;

      case 'T': // Test RAM
        test_RAM ();
        break;

      case 'E': // dump RAM
        dump_RAM (value_of_hex_byte (previous, 1));
        break;

      case 'u': // Upload
        write_to_RAM ();
        break;

      case 'z': // Disconnect (don't drive A*, RWB and D*)
        release_buses ();
        show_status ();
        break;
    }
    previous [0] = previous [1];
    previous [1] = previous [2];
    previous [2] = request;
  }
}


void static  loop ()
{
  poll_UART ();
  /* For testing lines between FPGA and Monitor AVR:
  uint8_t static  go_prior = 0;
  // if GO has changed
  uint8_t  go_now = level_at (PIND, GO);
  if (go_now != go_prior)
  {
    show_status ();
  }
  */
}


int  main()
{
  setup ();

  while (true)
  {
    loop ();
  }
}

