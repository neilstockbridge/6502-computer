
PROJECT=simulator

SRC = iMX23.c main.c
OBJ = $(SRC:.c=.o)

CFLAGS = --std=c99 -Wall

.SILENT:

# Generic rule for compiling C files:
.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

#Targets
all: $(PROJECT)

$(PROJECT): $(OBJ)
	$(CC) $(CFLAGS) -o $(PROJECT) $(OBJ)

main.o: Makefile  iMX23.h
iMX23.o: Makefile  iMX23.h

clean:
	rm -f $(PROJECT) *.o

