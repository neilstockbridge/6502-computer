
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>

#include "RAM.h"


uint8_t  memory[ 1 << 16 ];


#define  ROM_FILE  "/tmp/ROM.prg"

// The mtime of the ROM loaded.  If the file changes then its new mtime won't
// match this and it must be reloaded.
time_t  loaded_file_version = 0;


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
  // Fill the RAM with NOPs
  for ( int  a = 0;  a < sizeof(memory);  a += 1 )
    memory[ a] = 0xea; // NOP
  // .except for the RESET vector, which points to $1234
  memory[ 0xfffc] = 0x34;
  memory[ 0xfffd] = 0x12;

  update_RAM();

  d->read = read_from_RAM;
  d->write = write_to_RAM;
}


// A .prg file is a file where the first two bytes indicate the 16-bit address
// at which to load the rest of the file.
//
void load_prg_file( char *path_to_file, uint32_t  bytes_in_file )
{
  uint16_t  base_address; // The address at which the data should be loaded
  ssize_t   bytes_read; // The number of bytes read by read()
  uint16_t  bytes_to_load = bytes_in_file - 2;

  int  file = open( path_to_file, O_RDONLY );
      if ( -1 == file ) { perror("open"); return; }

  // Read the first two bytes from the file, which indicate the address at
  // which to load the rest
  bytes_read = read( file, &base_address, 2 );
      if ( bytes_read < 2 ) {
        fprintf( stderr, "%s: too short\n", path_to_file );
        return;
      }
      if ( 65536 < base_address + bytes_to_load )
      {
        fprintf( stderr, "%s: would overflow 64K\n", path_to_file );
        return;
      }

  bytes_read = read( file, &memory[ base_address], bytes_to_load );
      if ( bytes_read < bytes_to_load ) {
        fprintf( stderr, "%s: corrupt\n", path_to_file );
        return;
      }

  close( file );
}


// Checks the mtime of the loaded .prg file and reloads it if changed, then
// resets the microprocessor.
//
// @return  0  if the ROM file had not changed, or 1 if it had and was reloaded
//
int update_RAM()
{
  struct stat  st;
  int          outcome;

  // Determine the size and mtime of ROM_FILE
  outcome = stat( ROM_FILE, &st );
      if ( outcome != 0 ) {
        perror( ROM_FILE );
        return 0;
      }

  // If the file has changed ( or not yet been loaded)
  if ( st.st_mtime != loaded_file_version )
  {
    sleep(1);
    load_prg_file( ROM_FILE, st.st_size );
    loaded_file_version = st.st_mtime;
    return 1;
  }

  return 0;
}

