
PROJECT=simulator

SRC = iMX23.c RAM.c main.c
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

iMX23.o: Makefile  iMX23.h
RAM.o: Makefile RAM.h
main.o: Makefile  iMX23.h  RAM.h

clean:
	rm -f $(PROJECT) *.o

