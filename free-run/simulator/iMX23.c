
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/mman.h>

#include "iMX23.h"


void *peripheral_block( uint32_t address, uint32_t size )
{
  int        fd;
  uint32_t  *block;

  fd = open("/dev/mem", O_RDWR );
  if ( -1 == fd ) {
    perror("/dev/mem");
    return NULL;
  }

  block = mmap( NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, fd, address );
  if ( MAP_FAILED == block ) {
    perror("mmap");
    return NULL;
  }

  if ( -1 == close( fd ) )
    perror("close");

  return block;
}

