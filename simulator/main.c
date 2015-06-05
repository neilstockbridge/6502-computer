/*

# PLAN

*/


#include <signal.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h> // for exit()
#include <time.h>
#define __USE_BSD
#include <unistd.h> // for usleep()

#include "iMX23.h"
#include "ANSI.h"
#include "RAM.h"
#include "serial_port.h"


#define  LOW   0
#define  HIGH  1

#define  PINCTRL_BASE  0x80018000
#define  PINCTRL_SIZE  ( 0x80019FFF - 0x80018000 + 1 )

HW_PINCTRL_t  *pinctrl_block;
#define  HW_PINCTRL  ( *pinctrl_block )

// Pins have so many names and numbers:
// bank 0 pin 7 is GPMI data 7 / LCD D15 / proc pin 28, pin#25 on CON1

// bank = pin >> 5, level:0=low,1=high, /4 because addresses and offsets in
// datasheet are in bytes yet pinctrl_block is indexed in 32-bit increments
#define  drive_pin( pin, level )  if (level) HW_PINCTRL.DOUT[ (pin) >> 5 ].SET = 1 << ((pin)&0x1f); else HW_PINCTRL.DOUT[ (pin) >> 5 ].CLR = 1 << ((pin)&0x1f)
#define  level_at_pin( pin )  ( (( HW_PINCTRL.DIN[ (pin) >> 5 ].BASE >> ((pin)&0x1f) ) & 0x1) != 0 ? HIGH : LOW )


// A map from CONnector ( 1 or 2 mapped to 0 or 1) and pin on that connector
// ( 1 through 25 mapped to 0 through 24) to logical pin ( 0-based, packed bank
// number, 0 through 95 or -1 if the CONnector pin doesn't correspond to a GPIO
// pin).
//
#define  _CP( bank_number, pin_number)  ( (bank_number) << 5 | (pin_number) )

int8_t _CON_PIN[][30] = {
  {
    -1, // +5V
    -1, // GND
    -1, // +3V3
    -1, // _CP( 1, 0), // CON1.4  don't seem to work
    -1, // _CP( 1, 1), // CON1.5   "
    //_CP( 1, 0), // CON1.4  don't seem to work.  maybe bad solder joint?
    //_CP( 1, 1), // CON1.5   "
    _CP( 1, 2), // CON1.6
    _CP( 1, 3), // CON1.7
    _CP( 1, 4), // CON1.8
    _CP( 1, 5), // CON1.9
    _CP( 1, 6), // CON1.10
    _CP( 1, 7), // CON1.11
    _CP( 0, 0), // CON1.12
    _CP( 0, 1), // CON1.13
    _CP( 0, 2), // CON1.14
    -1,         // CON1.15
    -1,         // CON1.16
    -1,         // CON1.17
    -1,         // CON1.18
    -1,         // CON1.19
    -1,         // CON1.20
    _CP( 0, 3), // CON1.21
    _CP( 0, 4), // CON1.22
    _CP( 0, 5), // CON1.23
    _CP( 0, 6), // CON1.24
    _CP( 0, 7), // CON1.25
    _CP( 0, 16), // CON1.26
    -1, // _CP( 0, 17), // CON1.27  USB_EN ( removes power from pin#1 of USB socket)
    _CP( 1, 25), // CON1.28
    _CP( 1, 24), // CON1.29  SDA
    _CP( 1, 23), // CON1.30  SCL
    //-1, //_CP( 1, 24), // CON1.29  SDA.  Hopefully Linux I2C driver will not interfere with GPIO because it's an alternate fn disabled in PINCTRL
    //-1, //_CP( 1, 23), // CON1.30  SCL
  },
  {
    -1, // +5VEXT
    -1, // GND
    -1, // +3V3_REG
    -1, // _CP( 1, 26), // CON2.4  DEBUG UART RX
    -1, // _CP( 1, 27), // CON2.5  DEBUG UART TX
    -1,          // CON2.6
    -1,          // CON2.7
    -1,          // CON2.8
    -1,          // CON2.9
    -1,          // CON2.10
    -1,          // CON2.11
    -1,          // CON2.12
    -1,          // CON2.13
    -1,          // CON2.14
    -1,          // CON2.15
    -1,          // CON2.16
    -1,          // CON2.17
    -1,          // CON2.18
    -1,          // CON2.19
    -1,          // CON2.20
    _CP( 2, 28), // CON2.21
    _CP( 2, 27), // CON2.22
    _CP( 0, 23), // CON2.23
    _CP( 0, 25), // CON2.24
    _CP( 1, 28), // CON2.25
    _CP( 1, 21), // CON2.26
    _CP( 1, 19), // CON2.27
    _CP( 1, 20), // CON2.28
    _CP( 1, 18), // CON2.29
    _CP( 1, 22), // CON2.30
  },
};
#define  CON_PIN( connector_number, pin_number ) \
    _CON_PIN[ (connector_number) - 1][ (pin_number) - 1]

#define  RESB   CON_PIN(2,23) // maps to bank 0 pin 23
#define  CLK    CON_PIN(2,24) // maps to bank 0 pin 25
#define  A0     CON_PIN(1,6)  // A0..5 maps to bank 1, pins 2..7
#define  A1     CON_PIN(1,7)
#define  A2     CON_PIN(1,8)
#define  A3     CON_PIN(1,9)
#define  A4     CON_PIN(1,10)
#define  A5     CON_PIN(1,11)
#define  A6     CON_PIN(2,29) // A6..13 map to bank 1 pins 18..25
#define  A7     CON_PIN(2,27)
#define  A8     CON_PIN(2,28)
#define  A9     CON_PIN(2,26)
#define  A10    CON_PIN(2,30)
#define  A11    CON_PIN(1,30)
#define  A12    CON_PIN(1,29)
#define  A13    CON_PIN(1,28)
#define  A14    CON_PIN(2,22) // maps to bank 2 pin 27
#define  A15    CON_PIN(2,21) // maps to bank 2 pin 28
#define  DDR    CON_PIN(2,25) // maps to bank 1 pin 28
#define  D0     CON_PIN(1,12) // D0..7 map to bank 0, pins 0..7
#define  D1     CON_PIN(1,13)
#define  D2     CON_PIN(1,14)
#define  D3     CON_PIN(1,21)
#define  D4     CON_PIN(1,22)
#define  D5     CON_PIN(1,23)
#define  D6     CON_PIN(1,24)
#define  D7     CON_PIN(1,25)
#define  IRQB   CON_PIN(1,26) // maps to bank 0 pin 16

// A* and DDR should be input, all others output


uint16_t static  address()
{
  uint32_t  bank1pins = HW_PINCTRL.DIN[1].BASE;

  return (HW_PINCTRL.DIN[2].BASE >> 27 & 0x3) << 14
       | (bank1pins >> 18 & 0xff) << 6
       | (bank1pins >> 2 & 0x3f) << 0
       ;
}


void static  sense_the_data_bus()
{
  HW_PINCTRL.DOE[ 0].CLR = 0xff;
}


void static  drive_the_data_bus()
{
  HW_PINCTRL.DOE[ 0].SET = 0xff;
}


uint8_t static  data()
{
  return HW_PINCTRL.DIN[0].BASE & 0xff;
}


void static  write_data( uint8_t data )
{
  HW_PINCTRL.DOUT[0].CLR = 0xff;
  HW_PINCTRL.DOUT[0].SET = data;
}


uint8_t static  data_direction()
{
  return level_at_pin( DDR);
}


uint8_t static  reset()
{
  return level_at_pin( RESB);
}


uint8_t static  clock_line()
{
  return level_at_pin( CLK);
}


uint8_t static  irq()
{
  return level_at_pin( IRQB);
}


void  printsig( int line, int column, char *name, int level, char *low_meaning, char *high_meaning )
{
  printfat( line, column, "%s", name );
  printfat( line, column+8, "%s ( %s)", (level ? "high" : "low"), (level ? high_meaning : low_meaning) );
  clrtoeol();
}


bool static  is_input( int8_t  packed_pin )
{
  uint8_t  INIT_INPUT[] = { A0, A1, A2, A3, A4, A5, A6, A7, A8, A9, A10, A11, A12, A13, A14, A15, DDR };

  for ( int  i = 0;  i <= 16;  i += 1 )
    if ( INIT_INPUT[i] == packed_pin )
      return true;
  return false;
}


// in microseconds:
uint32_t  half_cycle_period = 500 * 1000; // 1 Hz

bool      currently_resetting = true;
uint32_t  half_cycles = 0;
uint16_t  current_address = 0x0000;
uint8_t   latched_data = 0x00;
bool      this_device_is_addressed = true;
enum
{
  WRITING,
  READING,
}
microprocessor_is = READING;

FILE *log_file = NULL;


Device  RAM;
Device  serial_port;
Device *addressed_device;


// Prints:
//  - State of the /RESET line
//  - State of the CLK line
//  - State of the /IRQ line
//  - Address line ( as 16-bit address in hex)
//  - Data bus ( as 8-bit data in hex)
//  - Who's driving the data bus ( RWB)
//
void  print_status()
{
  printsig( 2, 2, "/RESET", reset(), "resetting", "running");
  printfat( 4, 2, "ADDR    $%04x ", address() );
  printsig( 5, 2, "DDR",   data_direction(), "MCU writing", "MCU reading");
  printfat( 6, 2, "DATA    $%02x ", data() );
  printsig( 7, 2, "/IRQ",  irq(), "interrupted", "not interrupting");
  printfat( 8, 2, "creset  %i ", currently_resetting );
  printfat( 3, 2, "CLK     %s ", clock_line() ? "HIGH" : "LOW" );
}


void static  half_cycle()
{
  if ( 0 < half_cycle_period )
    usleep( half_cycle_period );
  // If the clock is about to RISE..
  //  - The microprocessor may be about to drive the data bus lines so the
  //    simulator should set its data bus pin to High-Z ( INPUT)
  if ( ! currently_resetting )
  {
    // The comparison to 1 below is slightly confusing.  half_cycles has
    // already been incremented but the CLK line has not yet been driven HIGH
    bool  clock_is_about_to_rise = (half_cycles & 0x1) == 1;
    if ( clock_is_about_to_rise )
    {
      // Read the DDR and Address bus lines *before* the clock rises because
      // this software may not be fast enough to sample them after the clock
      // rises
      current_address = address();
      microprocessor_is = data_direction() == HIGH ? READING : WRITING;
      if ( ! ( this_device_is_addressed && microprocessor_is == READING) )
        sense_the_data_bus();
      this_device_is_addressed = true;  // FIXME: Change this when there are external peripherals too
      addressed_device = 0xe000 == (current_address & 0xfffe) ? &serial_port : &RAM;
    }
    else {
      if ( microprocessor_is == WRITING )
        latched_data = data();
    }
  }

  drive_pin( CLK, half_cycles & 1 ? HIGH : LOW );
  // If the clock has RISEN
  //  - The address bus and DDR lines are now stable and should be read
  //  - If peripherals inside this simulator have been addressed and the
  //    microprocessor is READING then the simulator should DRIVE the data bus
  //  - If the microprocessor is WRITING then it will drive the data bus
  // If the clock has FALLEN
  //  - If the microprocessor is READING then shortly the microprocessor will
  //    read the data bus but the simulator will keep on driving it until just
  //    prior to the next rising edge of the clock
  //  - If the microprocessor is WRITING then the addresses peripheral should
  //    read the data bus now
  if ( ! currently_resetting )
  {
    bool  clock_has_risen = (half_cycles & 0x1) == 1;
    if ( clock_has_risen )
    {
      if ( this_device_is_addressed  &&  microprocessor_is == READING )
      {
        write_data( addressed_device->read( current_address) );
        drive_the_data_bus();
      }
    }
    else { // FALLEN
      if ( this_device_is_addressed  &&  microprocessor_is == WRITING )
      {
        addressed_device->write( current_address, latched_data );
      }
    }
  }

  if ( 1000 <= half_cycle_period ) // 500 Hz
  {
    fprintf( log_file,
      "%04i reset:%i clk:%i addr:%04x ddr:%i, data:%02x, da:%i, mi:%i, ca:%04x\n",
      half_cycles, reset(), clock_line(), address(), data_direction(), data(),
      this_device_is_addressed, microprocessor_is == READING, current_address );
  }
  if ( 50*1000 <= half_cycle_period ) // 10 Hz
  {
    print_status();
  }

  half_cycles += 1;
}


void static  wait( uint8_t cycles )
{
  for ( ;  0 < cycles;  cycles -= 1 )
  {
    half_cycle();
    half_cycle();
  }
}


void static  perform_reset()
{
  currently_resetting = true;
  // "The RESB signal must be held low for at least two clock cycles after VDD
  // reaches operating voltage."
  drive_pin( CLK, HIGH ); usleep( 1000); // Delay to allow MCU to notice.  Unsure if required.  iMX-233 can toggle at 4.8 MHz
  drive_pin( RESB, LOW ); usleep( 1000);
  wait( 2);
  drive_pin( RESB, HIGH ); usleep( 1000);
  // "When a positive edge is detected, there will be a reset sequence lasting
  // seven clock cycles."
  currently_resetting = false;
  wait( 7);
}


void  int_handler( int signal )
{
  // By exiting "normally", atexit handlers will be invoked
  exit( 0 );
}


void static  tidy_up()
{
  fclose( log_file );
}


void init()
{
  // Install a handler for SIGINT ( Ctrl-C)
  signal( SIGINT, int_handler );
  atexit( tidy_up );

  init_serial_port( &serial_port );

  pinctrl_block = peripheral_block( PINCTRL_BASE, PINCTRL_SIZE );
  if ( NULL == pinctrl_block )
  {
    fprintf( stderr, "FATAL: Could not map PINCTRL block\n");
    exit(1);
  }

  if ( 50*1000 <= half_cycle_period ) // 10 Hz
    clear_screen();

  // Configure the GPIO pins
  for ( int  c = 1;  c <= 2;  c += 1 )
  {
    for ( int  p = 1;  p <= 30;  p += 1 )
    {
      int8_t  packed_pin = CON_PIN( c, p );
      if ( packed_pin != -1 )
      {
        uint8_t  msr = packed_pin >> 4; // MUXSEL register 0..5
        uint8_t  pos = (packed_pin & 0xf) << 1; // bit position within MUXSEL register of the bit pair that control the function of the pin
        // Configure the pin for GPIO rather that any of its alternate functions
        HW_PINCTRL.MUXSEL[ msr].SET = 0x3 << pos; // 0x3 means "GPIO"
        uint8_t  bank = packed_pin >> 5;
        //printf("Configuring CON%i pin%i as ", c, p );
        // Enable pull-ups on all pins, which includes: RESET, CLK, D*, and IRQ
        HW_PINCTRL.PULL[ bank].SET = _BV( packed_pin & 0x1f );

        if ( is_input( packed_pin) )
        {
          //printf("input\n");
          HW_PINCTRL.DOE[ bank].CLR = _BV( packed_pin & 0x1f );
        }
        else {
          //printf("output\n");
          HW_PINCTRL.DOE[ bank].SET = _BV( packed_pin & 0x1f );
        }
      }
    }
  }

  log_file = fopen("/tmp/simulator.log", "a");

  init_RAM( &RAM );
  drive_pin( RESB, 0 );
  write_data( 0xea ); // NOP
  drive_pin( CLK, 0 );
  drive_pin( IRQB, 1 );

  perform_reset();
}


void loop()
{
  // to assert IRQ:
  //drive_pin( IRQB, LOW );
  // once the MCU has acknowledged the interrupt at the peripheral that caused it:
  //drive_pin( IRQB, HIGH );
  half_cycle();

  // This could work, even with other devices on the buses.  As long as the
  // clock is controlled here then:
  //  - If this device is currently driving the D* lines then because it
  //    controls the clock then the D* lines can be tri-stated *before* the
  //    system clock rises, so no matter how fast a real ( hardware) device
  //    notices that it has been addessed and begins driving the data bus,
  //    there will be no fighting
  //  - When the system clock is due to rise and this device has been addressed
  //    then it waits until *after* the clock has risen in order to give the
  //    previously addressed hardware device a chance to tri-state its data bus
  //    drivers.  There could even be a delay, although this may not stricyly
  //    be necessary since this is software and therefore slow

  // To speed things up ( even though it will result in an irregular clock),
  // only check to updates to the ROM periodically, not even half cycle
  time_t static  when_last_updated = 0;
  time_t  now = time( NULL );
  uint32_t static  previous_half_cycle_count = 0;
  if ( when_last_updated < now )
  {
    int  reloaded = update_RAM();
    if ( reloaded ) {
      perform_reset();
    }
    fprintf( log_file, "%u Hz\n", (half_cycles - previous_half_cycle_count) >> 1 );
    previous_half_cycle_count = half_cycles;
    when_last_updated = now;
  }
  uint32_t static  when_last_polled = 0; // in half cycles
  if ( when_last_polled + 1000 < half_cycles )
  {
    poll_serial_port();
    when_last_polled = half_cycles;
  }
}


int main( int argc, char *argv[])
{
  // The first argument if present specifies the target frequency in Hz.
  // Specify over 500,000 for fastest operation ( about 12 kHz), or omit for 1
  // Hz operation.
  uint32_t  target_frequency = 1;
  if ( 1 < argc )
  {
    target_frequency = atoi( argv[1] );
  }
  half_cycle_period = 500*1000 / target_frequency;
  printf("Target frequency: %u Hz, half_cycle_period:%u\n", target_frequency, half_cycle_period );

  init();

  while( true )
  {
    loop();
  }

  return 0;
}

