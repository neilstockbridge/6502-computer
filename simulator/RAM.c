
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#include "RAM.h"


uint8_t  memory[ 1 << 16 ];


uint8_t  read_from_RAM( uint16_t address )
{
  return memory[ address];
}


void  write_to_RAM( uint16_t address, uint8_t data )
{
  memory[ address] = data;
}


void  init_RAM( Device *d )
{
  for ( int  a = 0;  a < sizeof(memory);  a += 1 )
    memory[ a] = 0xea; // NOP
  memory[ 0xfffc] = 0x34;
  memory[ 0xfffd] = 0x12;

  d->read = read_from_RAM;
  d->write = write_to_RAM;
}


void load_prg_file( char *path_to_file )
{
  // A .prg file is a file where the first two bytes indicate the 16-bit
  // address at which to load the rest of the file
  //FILE  *f = fopen( path_to_file, "r");
  int  f = open( path_to_file, O_RDONLY );
  //if ( NULL == f ) {
  if ( -1 == f ) {
    perror("open");
    return;
  }
  uint16_t  target;
  ssize_t  bytes_read = read( f, &target, 2 );
  if ( bytes_read < 2 ) {
    fprintf( stderr, "%s: too short\n", path_to_file );
    return;
  }
  struct stat  st;
  stat( path_to_file, &st );
  int  size = st.st_size - 2;
  if ( 65536 < target + size )
  {
    fprintf( stderr, "%s: would overflow 64K\n", path_to_file );
    return;
  }
  bytes_read = read( f, &memory[ target], size );
  if ( bytes_read < size ) {
    fprintf( stderr, "%s: corrupt\n", path_to_file );
    return;
  }

  close( f );
}

