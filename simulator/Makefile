
PROJECT=simulator

SRC = Queue.c  ANSI.c  iMX23.c  RAM.c  serial_port.c  main.c
OBJ = $(SRC:.c=.o)

CFLAGS = --std=c99 -Wall -O2

.SILENT:

# Generic rule for compiling C files:
.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

#Targets
all: $(PROJECT)

$(PROJECT): $(OBJ)
	$(CC) $(CFLAGS) -o $(PROJECT) $(OBJ)

Queue.o: Makefile  Queue.h  Queue.c
iMX23.o: Makefile  iMX23.h  iMX23.c
serial_port.o: Makefile Queue.h serial_port.c
RAM.o: Makefile  device.h  RAM.h  RAM.c
main.o: Makefile  iMX23.h  device.h  RAM.h  main.c

clean:
	rm -f $(PROJECT) *.o

