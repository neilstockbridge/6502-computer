
#include <sys/types.h>
#include <sys/time.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include <termios.h>
#include <unistd.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>


bool streq (char *test, char *s)
{
  return 0 == strcmp( test, s );
}


uint16_t phex16 (char *s)
{
  uint16_t  value;
  int  items = sscanf (s, "%hx", &value);
  if (items != 1) {fprintf (stderr, "Expected 1 got %i", items); exit (1);}
  return value;
}


char *serial_device;


#define  ROM_FILE  "/tmp/ROM.prg"

// The mtime of the ROM loaded.  If the file changes then its new mtime won't
// match this and it must be reloaded.
time_t  loaded_file_version = 0;


int             port;
struct termios  oldtio;


void static  tidy_up ()
{
  // Restore the configuration of the serial port:
  tcsetattr (port, TCSANOW, &oldtio);
}


void  init ()
{
  struct termios  newtio;

  serial_device = getenv ("port");
  if (NULL == serial_device)
    serial_device = "/dev/ttyUSB0";

  port = open (serial_device, O_RDWR | O_NOCTTY);
      if (port < 0) { perror (serial_device); exit (-1); }

  tcgetattr (port , &oldtio); // save current port settings
  atexit (tidy_up);

  bzero (&newtio, sizeof(newtio));

  // Hacky, but BAUD_RATE env var not specified for R1, is for R2 but assume 115200
  int  baud_rate = getenv ("baud") ? B115200 : B38400;
  newtio.c_cflag = baud_rate | CS8 | CLOCAL | CREAD; // CS8 =>  8 bit characters, CLOCAL => ignore modem control lines
  newtio.c_iflag = IGNBRK | IGNPAR;
  newtio.c_oflag = 0;

  // set input mode (non-canonical, no echo,...)
  newtio.c_lflag = 0;

  newtio.c_cc [VTIME] = 0;   // inter-character timer unused
  newtio.c_cc [VMIN]  = 1;   // blocking read until 5 chars received

  tcflush (port, TCIFLUSH);
  tcsetattr (port, TCSANOW, &newtio);
}


void static  send (uint8_t data)
{
  ssize_t  bytes_written = write (port, &data, 1);
  if (bytes_written < 1) { printf ("write\n"); perror (serial_device); return; }
}


void  send16 (uint16_t data)
{
  send (data & 0xff);
  send (data >> 8);
}


// A .prg file is a file where the first two bytes indicate the 16-bit address
// at which to load the rest of the file.
//
void load_prg_file (char *path_to_file, uint32_t  bytes_in_file)
{
  uint16_t  base_address; // The address at which the data should be loaded
  ssize_t   bytes_read; // The number of bytes read by read()
  uint16_t  bytes_to_load = bytes_in_file - 2;

  int  file = open (path_to_file, O_RDONLY);
      if (-1 == file) {perror (path_to_file); return;}

  // Read the first two bytes from the file, which indicate the address at
  // which to load the rest
  bytes_read = read (file, &base_address, 2);
      if (bytes_read < 2) {
        fprintf (stderr, "%s: too short\n", path_to_file);
        return;
      }
      if (65536 < base_address + bytes_to_load)
      {
        fprintf (stderr, "%s: would overflow 64K\n", path_to_file);
        return;
      }

  // Begin the UPLOAD request
  send ('u');
  // Send the load_address
  send16 (base_address);
  // Send the number of bytes in the ROM
  send16 (bytes_to_load);

  while (0 < bytes_to_load)
  {
    uint8_t  data;

    if ((bytes_read & 0xff) == 0)
    {
      fprintf (stdout, ".");
      fflush (stdout);
    }

    bytes_read = read (file, &data, 1);
      if (bytes_read != 1) {
        fprintf (stderr, "%s: corrupt\n", path_to_file);
        return;
      }

    send (data);

    bytes_to_load -= 1;
  }

  close (file);
  printf ("done.\n");
}


void static  loop ()
{
  struct stat  st;
  int          outcome;

  // Determine the size and mtime of ROM_FILE
  outcome = stat (ROM_FILE, &st);
      if (outcome != 0) {perror (ROM_FILE); return;}

  // If the file has changed ( or not yet been loaded)
  if (st.st_mtime != loaded_file_version)
  {
    printf ("File change detected.  Uploading..\n");
    sleep (1);
    load_prg_file (ROM_FILE, st.st_size);
    printf ("Resetting\n");
    send ('r');
    loaded_file_version = st.st_mtime;
  }

  sleep (1);
}


uint8_t  read8 ()
{
  ssize_t  bytes_read;
  uint8_t  value;

  bytes_read = read (port, &value, 1);
      if (bytes_read != 1) { printf ("read8 %lu\n", bytes_read); perror (serial_device); exit (1); }

  return value;
}


uint16_t  read16 ()
{
  return read8 () | read8 () << 8;
}


void  copy_from_SBC_to_file (uint16_t base_address, uint16_t bytes_to_copy, char *path_to_file)
{
  ssize_t  bytes_read, bytes_written;

  int  file = open (path_to_file, O_CREAT|O_WRONLY|O_TRUNC, S_IRUSR|S_IWUSR);
      if (-1 == file) { perror (path_to_file); exit (1); }

  printf ("%u bytes at $%04x\n", bytes_to_copy, base_address);
  bytes_written = write (file, &base_address, 2);
    if (bytes_written != 2) { perror (path_to_file); exit (1); }
  while (0 < bytes_to_copy)
  {
    uint8_t  data;
    bytes_read = read (port, &data, 1);
      if (bytes_read != 1) { printf ("read\n"); perror (serial_device); exit (1); }
    bytes_written = write (file, &data, 1);
      if (bytes_written != 1) { perror (path_to_file); exit (1); }
    bytes_to_copy -= 1;
  }

  close( file );
}


//
void  download (char request, uint16_t base_address, uint16_t bytes_to_copy, char *path_to_file)
{
  send (request);
  // For the "master" AVR in R1.
  if (bytes_to_copy == 0)
  {
    base_address = read16 ();
    bytes_to_copy = read16 ();
  }
  // For the "debugger" AVR in R2.
  else {
    send16 (base_address);
    send16 (bytes_to_copy);
  }
  copy_from_SBC_to_file (base_address, bytes_to_copy, path_to_file);
}


void  usage ()
{
  fprintf (stderr, "Use: dude upload|(download rom|ram output-file)\n");
  exit (1);
}


int main (int argc, char *argv[])
{
  enum
  {
    UPLOAD_AND_WATCH,
    DOWNLOAD,
  }
  mode;
  char      request;
  uint16_t  base_address = 0x0000;
  uint16_t  bytes_to_copy = 0x0000;
  char     *output_file;

  if (argc < 2)
    usage ();

  else {
    init ();

    if (streq ("upload", argv [1]))
      mode = UPLOAD_AND_WATCH;

    else if (streq ("download", argv [1]))
    {
      mode = DOWNLOAD;
      if (streq ("rom", argv [2])) {
        request = 'd';
        output_file = argv [3];
      }
      else if (streq ("ram", argv [2]) ) {
        request = 'D';
        output_file = argv [3];
      }
      else {
        request = 'd';
        base_address = phex16 (argv [2]);
        bytes_to_copy = phex16 (argv [3]);
        output_file = argv [4];
      }
    }
    else
      usage ();
  }

  switch (mode)
  {
    case UPLOAD_AND_WATCH:
      while (true)
      {
        loop ();
      }
      break;

    case DOWNLOAD:
      download (request, base_address, bytes_to_copy, output_file);
      break;
  }
}

