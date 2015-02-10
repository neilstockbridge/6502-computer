
#include <stdarg.h>
#include <stdio.h>


void  clear_screen()
{
  printf("\033[2J");
  fflush( stdout );
}


void  clrtoeol()
{
  printf("\033[K");
  fflush( stdout );
}


void  printfat( int line, int column, char *format, ... )
{
  va_list  arg_ptr;
  char     buf[80];
  va_start( arg_ptr, format );
  vsnprintf( buf, sizeof(buf), format, arg_ptr );
  printf("\033[%u;%uH%s", line, column, buf );
  fflush( stdout );
  va_end( arg_ptr);
}

