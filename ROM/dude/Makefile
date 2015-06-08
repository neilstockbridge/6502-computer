
PROJECT = dude

SRC = main.c
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

main.o: Makefile  main.c

clean:
	rm -f $(PROJECT) *.o

