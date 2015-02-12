
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
#include "Queue.h"


#define  DEVICE   "/dev/ttyAMA0"

#define  BAUDRATE  B115200


int             port;
struct termios  oldtio;

/* Before these queues were corrected they were accidentally LIFOs, which
   caused this:
ER
YDAd
f008  lxd #fff
208  tsx
 8f  30dl a#bb
8f  50dl x#9f
08f  7sj rf769
8f  a0dl x#00
8f  c0dl y#0f
08f  esj rfc7b
*/
Queue  receive_queue;
Queue  send_queue;


void static  tidy_up()
{
  // Restore the configuration of the serial port:
  tcsetattr( port, TCSANOW, &oldtio );
  printf("RX Q max length: %u\n", receive_queue.max_length );
  printf("TX Q max length: %u\n", send_queue.max_length );
}


uint8_t  read_from_serial_port( uint16_t address )
{
  switch ( address & 0x1 )
  {
    case 0x00: // Register 0: Number of bytes available
      return queue_length( &receive_queue);
      break;

    case 0x01: // Register 1: Next byte
      if ( 0 < queue_length( &receive_queue) )
      {
        return dequeue( &receive_queue);
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
  if ( queue_length(&send_queue) < queue_capacity(&send_queue) )
  {
    enqueue( &send_queue, data );
  }
  else {
    fprintf( stderr, "TX buffer overflow\n");
  }
}


void  init_serial_port( Device *device )
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

  init_queue( &receive_queue);
  init_queue( &send_queue);

  device->read = read_from_serial_port;
  device->write = write_to_serial_port;
}


void  poll_serial_port()
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
    if ( queue_length(&receive_queue) < queue_capacity(&receive_queue) )
    {
      enqueue( &receive_queue, data );
    }
    else {
      fprintf( stderr, "RX buffer overflow\n");
    }
  }
  //else
    //printf("No data.\n");

  while ( 0 < queue_length(&send_queue) )
  {
    uint8_t  data = dequeue(&send_queue);
    outcome = write( port, &data, 1 );
  }
}

