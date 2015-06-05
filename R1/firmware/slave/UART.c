
#include "UART.h"

#include <avr/interrupt.h>
#include <avr/io.h>


#define  BAUD  115200


void  init_UART()
{
  // Set the baud rate
  #include <util/setbaud.h>
  UBRRH = UBRRH_VALUE;
  UBRRL = UBRRL_VALUE;

  // Configure the UART for point-to-point communications at single speed
  UCSRA = ( 0 << RXC)   // USART Receive Complete indicator
        | ( 0 << TXC)   // USART Transmit Complete indicator
        | ( 0 << UDRE)  // USART Data Register Empty indicator
        | ( 0 << FE)    // Always write 0 to the Frame Error indicator
        | ( 0 << DOR)   // Always write 0 to the Data OverRun indicator
        | ( 0 << UPE)   // Always write 0 to the Parity Error indicator
        | ( 0 << U2X)   // NO Double Transmission Speed
        | ( 0 << MPCM)  // NO Multi-processor Communication mode, i.e. point-to-point mode
        ;

  #define  FIVE_DATA_BITS   0
  #define  SIX_DATA_BITS    1
  #define  SEVEN_DATA_BITS  2
  #define  EIGHT_DATA_BITS  3
  #define  NINE_DATA_BITS   7

  // Enable the receiver and the transmitter, the RX interrrupt and set the format to 8N1
  UCSRB = ( 1 << RXCIE)                       // RX Complete Interrupt Enable
        | ( 0 << TXCIE)                       // TX Complete Interrupt Enable
        | ( 0 << UDRIE)                       // USART Data Register Empty Interrupt Enable
        | ( 1 << RXEN)                        // Receiver Enable
        | ( 1 << TXEN)                        // Transmitter Enable
        | ( (EIGHT_DATA_BITS >> 2) << UCSZ2)  //
        | ( 0 << RXB8)                        // Receive Data Bit 8
        | ( 0 << TXB8)                        // Transmit Data Bit 8
        ;

  #define  ASYNCHRONOUS_MODE  0

  #define  NO_PARITY        0
  #define  EVEN_PARITY      2
  #define  ODD_PARITY       3

  #define  ONE_STOP_BIT     0
  #define  TWO_STOP_BITS    1

  // set the frame format: 8 data bits, no parity, 1 stop bit
  UCSRC = ( ASYNCHRONOUS_MODE << UMSEL)       // USART Mode Select.  0:Asynchronous
        | ( NO_PARITY << UPM0)                // USART Parity Mode
        | ( ONE_STOP_BIT << USBS)             // USART Stop Bit Select
        | ( (EIGHT_DATA_BITS & 0x3) << UCSZ0) // Character Size
        | ( 0 << UCPOL)                       // Clock Polarity ( synchronous mode only)
        ;
}


ISR( USART_RX_vect)
{
  byte_received_via_UART( UDR);
}


bool  UART_is_ready_to_send()
{
  return (UCSRA >> UDRE) & 0x1;
}


// Sends a single character over the serial link.
//
void  send_byte_via_UART( uint8_t  data )
{
  // Wait for the transmit buffer to be ready
  loop_until_bit_is_set( UCSRA, UDRE);

  UDR = data;
}

