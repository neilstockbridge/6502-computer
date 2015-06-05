/*

This is the slave AVR in R1 of my 6502 computer build.  It provides:

  - Management of RESB.  LOW at power-on and may be commanded HIGH or LOW via
    SPI

  - Management of IRQB.  The UART and the counters can be configured to
    interrupt

  - UART via SPI ( simulate MAX3100 or SPI-to-RS232-bridge?)
    - Either way, the protocol will have to coexist alongside the other uses of
      the communications channel, for example, indicating which device caused
      an interrupt?

  - Slave selects.  SPI commands to command which slave should be enabled.
    This firmware automatically releases the currently selected slave.  Future
    SPI commands could select more than one slave if this were ever useful

  - 1x 8-bit counter and 1x 16-bit counter

## Notes

  - Off-board SPI is between the master AVR and the particular SPI slave.  This
    AVR is merely commanded to select ( or release) the SPI devices

## SPI commands

  0x00  Poll ( No request so that the Master AVR can check if the Slave AVR
        wishes to send anything to the master - typically data received via the
        UART)

  0x01  Assert RESB ( drive it LOW)
  0x02  Release RESB ( drive it HIGH)

  0x10  Select slave 0 ( Drive /SS0 LOW).  Any currently selected slave will be
        released
  0x11  Select slave 1
  ..
  0x16  Select slave 6
  0x17  Release all /SS? lines ( drive them high. All except /SSA, which is
        driven by the master)

  0x40  Request UART status
          partity error, frame error, data available, data overrun
  0x40  Configure UART.  Maybe some configuration could be packed in to this request byte
         RXIE, character size, parity, stop bits, baud rate
  0x42  Send data via UART ( byte follows)
  0x40  Pump the UART.  Send at least once more

  0xfe  Reset queue statistics
  0xff  Status report ( Indicates if either of queues has overflowed or not
        since reset and what their maximum length was)

  TODO  Commands for interacting with the UART and timers


## MAX3100E features

  - TX/RX
  - Baud rate divisor ( 16 options, 300 to 115,200 with non-double XTAL)
  - Stop bit conf ( 1 or 2)
  - CTS ( GPIO input)
  - RTS ( GPIO output)
  - IrDA timing
  - data available indicator
  - framing error indicator
  - low power ( sleep) mode
  - IRQs: data available, TX buf empty, framing error/activity while asleep, parity error

To reproduce:

  v1:
    - TX/RX
    - IRQs
    - framing error indicator
    - data available indicator
    - queue
  v2:
    - Baud rate divisor
    - frame size ( 5, 6, 7, not 9), stop bits ( 1, 2)

*/


#include <stdbool.h>

#include <avr/interrupt.h>
#include <avr/sleep.h>

#include "Queue.h"
#include "UART.h"
#include "SPI.h"
#include "pinout.h"


typedef enum
{
  POLL,
  ASSERT_RESB,
  RELEASE_RESB,
  SELECT_SLAVE_0 = 0x10,
  //RELEASE_SLAVE= 0x17,
  SEND_VIA_UART = 0x42,
}
Request;


Queue  from_SPI; // Received via SPI and waiting for UART
Queue  from_UART; // Received via UART and waiting for SPI


#include <avr/pgmspace.h>

#define  send_str( s )  _send_str(PSTR(s))

#define  NUL  '\0'

// Sends the given message from program memory over the serial link.
//
void static  _send_str( char const *s )
{
  while ( true)
  {
    char  c = pgm_read_byte( s );
    send_byte_via_UART( c);
    if ( NUL == c)
      break;
    s += 1;
  }
}


// Sends the hexadecimal representation of the given byte over the serial link.
//
void static  send_byte_as_hex( uint8_t value)
{
  char  static  hex_digit_for[] = "0123456789abcdef";

  send_byte_via_UART( hex_digit_for[ value >> 4]);
  send_byte_via_UART( hex_digit_for[ value & 0x0f]);
}


void static  send_eol()
{
  send_byte_via_UART('\r');
  send_byte_via_UART('\n');
}


#define  report( aspect, value )  _report( PSTR( aspect), value )

void  _report( char const *aspect, uint8_t  value )
{
  _send_str( aspect );
  send_byte_as_hex( value );
  send_eol();
}


#define  report_bool( aspect, value )  _report_bool( PSTR( aspect), value )

void  _report_bool( char const *aspect, bool  value )
{
  _send_str( aspect);
  send_byte_via_UART( value ? 't' : 'f');
  send_eol();
}


void  send_status_report()
{
  Queue *qs[] = { &from_SPI, &from_UART };
  for(int i=0;i<2;i++)
  {
    Queue *q = qs[i];
    report("Queue #", i );
    report("  head:       ", q->head );
    report("  tail:       ", q->tail );
    // data?
    report_bool("  overflowed: ", q->overflowed );
    report("  max_length: ", q->max_length );
  }
}


void  byte_received_via_SPI( uint8_t  data )
{
  enqueue( &from_SPI, data );
}


void  byte_received_via_UART( uint8_t  data )
{
  enqueue( &from_UART, data );
}


// Dequeue with interrupts DISABLED otherwise an interrupt might manipulate the
// queue while we're halfway through a dequeue.  Because interrupts are
// disabled, dequeue as quickly as possible.
//
bool static inline  dequeued_safely( Queue *q, uint8_t *data )
{
  bool  data_is_valid;

  cli();

  if ( 0 < queue_length( q) )
  {
    *data = dequeue( q);
    data_is_valid = true;
  }
  else {
    data_is_valid = false;
  }

  sei();

  return data_is_valid;
}


void static  init()
{
  init_UART();
  init_SPI();
  init_queue( &from_SPI );
  init_queue( &from_UART );

  // Refer to "pinout.h"
  // The configuration of the UART automatically configures PD0 for sense and
  // PD1 for drive
  DDRD = DRIVE( RESB )
       | SENSE( IRQB )  // IRQB is Open Collector, so configured as SENSED ( High-Z) the external pull-up for IRQB will assert logic 1
       | DRIVE( SS4 )
       | DRIVE( SS5 )
       | DRIVE( SS6 )
       ;
  DDRB = SENSE( SCK )
       | DRIVE( MISO )
       | SENSE( MOSI )
       | SENSE( SSA )
       | DRIVE( SS3 )
       | DRIVE( SS2 )
       | DRIVE( SS1 )
       | DRIVE( SS0 )
       ;
  // All Slave Select signals should begin HIGH ( *not* asserted)
  PORTD = ( LOW << RESB ) // Begin in Reset
        | ( LOW << IRQB )   // LOW: IRQB asserted ( when configured as DRIVEN)
        | ( HIGH << SS4 )
        | ( HIGH << SS5 )
        | ( HIGH << SS6 )
        ;
  // Enable pull-ups on SCK, MOSI and /SS to prevent flapping when no SPI
  // master is connected
  PORTB = PULL_UP( SCK )
        | PULL_UP( MOSI )
        | PULL_UP( SSA )
        | ( HIGH << SS3 )
        | ( HIGH << SS2 )
        | ( HIGH << SS1 )
        | ( HIGH << SS0 )
        ;

  // Enable interrupts now that everything is configured
  sei();

  send_str("Initialization complete\r\n");
}


enum
{
  EXPECT_REQUEST,
  EXPECT_UART_TX_DATA,
}
state = EXPECT_REQUEST;


void static  loop()
{
  // Go to sleep to save power
  set_sleep_mode( SLEEP_MODE_IDLE);
  sleep_mode();

  uint8_t  data = 0x00;

  // If data has arrived via SPI
  // WARNING: -fshort-enums is required so that the enum consumes only a single byte!
  if ( dequeued_safely( &from_SPI, &data) )
  {
    report("RXSPI:", data );

    switch ( state )
    {
      case EXPECT_REQUEST:
        switch ( (Request)data )
        {
          case POLL:
            break;

          case ASSERT_RESB:
            assert_RESB();
            break;

          case RELEASE_RESB:
            release_RESB();
            break;

          case SELECT_SLAVE_0:
            break;

          case SEND_VIA_UART:
            state = EXPECT_UART_TX_DATA;
            break;
    /*
          case 0xff: // Status report
            send_byte_via_SPI( (from_SPI.overflowed ? 0x80 : 0x00) | (from_SPI.max_length & 0x7f) );
            send_byte_via_SPI( (from_UART.overflowed ? 0x80 : 0x00) | (from_UART.max_length & 0x7f) );
            break;

          case 0xfe: // Reset statistics
            from_SPI.overflowed = false;
            from_SPI.max_length = 0;
            from_UART.overflowed = false;
            from_UART.max_length = 0;
            break;
    */
          //default:
        }
        break;

      case EXPECT_UART_TX_DATA:
        send_byte_via_UART( data );
        state = EXPECT_REQUEST;
        break;
    }
  }

  if ( dequeued_safely( &from_UART, &data) )
  {
    send_status_report();
  }
}


int main( void)
{
  init();

  while ( true)
  {
    loop();
  }
}

