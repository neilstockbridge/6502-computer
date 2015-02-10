
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <termios.h>
#include <unistd.h>


#include "serial_port.h"


#define  DEVICE   "/dev/ttyAMA0"

#define  BAUDRATE  B115200


int             port;
struct termios  oldtio;

uint8_t  received[16];
int      rx_cursor = 0;
uint8_t  to_send[16];
int      tx_cursor = 0;


void  tidy_up()
{
  // Restore the configuration of the serial port:
  tcsetattr( port, TCSANOW, &oldtio );
}


uint8_t  read_from_serial_port( uint16_t address )
{
  switch ( address & 0x1 )
  {
    case 0x00: // Register 0: Number of bytes available
      return rx_cursor;
      break;

    case 0x01: // Register 1: Next byte
      if ( 0 < rx_cursor )
      {
        return received[ --rx_cursor ];
      }
      else {
        fprintf( stderr, "Attempt to read non-existent data\n");
        return 0xff;
      }
      break;
  }
  return 0;
}


void  write_to_serial_port( uint16_t address, uint8_t data )
{
  if ( tx_cursor < sizeof(to_send) )
  {
    to_send[ tx_cursor] = data;
    tx_cursor += 1;
  }
  else {
    fprintf( stderr, "TX buffer overflow\n");
  }
}


void init_serial_port( Device *device )
{
  struct termios  newtio;

  port = open( DEVICE, O_RDWR | O_NOCTTY );
  if ( port < 0 ) { perror(DEVICE); exit(-1); }

  tcgetattr( port , &oldtio ); /* save current port settings */
  atexit( tidy_up );

  bzero( &newtio, sizeof(newtio));
  newtio.c_cflag = BAUDRATE | CS8 | CLOCAL | CREAD; // CS8 =>  8 bit characters, CLOCAL => ignore modem control lines
  newtio.c_iflag = IGNBRK | IGNPAR;
  newtio.c_oflag = 0;

  /* set input mode (non-canonical, no echo,...) */
  newtio.c_lflag = 0;

  newtio.c_cc[VTIME] = 0;   /* inter-character timer unused */
  newtio.c_cc[VMIN]  = 1;   /* blocking read until 5 chars received */

  tcflush( port, TCIFLUSH );
  tcsetattr( port, TCSANOW, &newtio );
}


void poll_serial_port()
{
  fd_set          rfds;
  struct timeval  timeout = { tv_sec:0, tv_usec:0 };
  int             outcome;
  uint8_t         data;

  FD_ZERO( &rfds );
  FD_SET( port, &rfds );

  outcome = select( port+1, &rfds, NULL, NULL, &timeout );

  if ( outcome == -1 )
    perror("select()");

  else if ( outcome )
  {
    outcome = read( port, &data, 1 );
    if ( rx_cursor < sizeof(received) )
    {
      received[ rx_cursor] = data;
      rx_cursor += 1;
    }
    else {
      fprintf( stderr, "RX buffer overflow\n");
    }
  }
  //else
    //printf("No data.\n");

  while ( 0 < tx_cursor )
  {
    outcome = write( port, &to_send[--tx_cursor], 1 );
  }
}

