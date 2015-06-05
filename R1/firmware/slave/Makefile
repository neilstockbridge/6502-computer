
# project specific details

PROJECT = 6502-R1-slave
TARGET = attiny2313
AVRDUDE_PART = t2313
SYS_CLOCK = 18432000

PARTS = Queue.o UART.o SPI.o main.o

OPTIMIZE = -Os
DEVICE = $(TARGET)

# details common across projects

CC = avr-gcc
OBJCOPY = avr-objcopy

DEFINES = -DF_CPU=$(SYS_CLOCK)
CFLAGS = -std=c99 -mmcu=$(TARGET) $(OPTIMIZE) -fshort-enums $(DEFINES) -Wall $(DEBUG)
#PROGRAMMER = usbasp
PROGRAMMER = usbtiny
AVRDUDE_OPTS = -c $(PROGRAMMER) -p $(AVRDUDE_PART) -q
COMPILE=$(CC) $(CFLAGS) $(INCLUDES)

# don't echo commands issued by make
.SILENT:

# Generic rule for compiling C files:
.c.o:
	$(COMPILE) -c $< -o $@

# Generic rule for assembling Assembler source files:
.S.o:
	$(COMPILE) -x assembler-with-cpp -c $< -o $@
# "-x assembler-with-cpp" should not be necessary since this is the default
# file type for the .S (with capital S) extension. However, upper case
# characters are not always preserved on Windows. To ensure WinAVR
# compatibility define the file type manually.


# Targets...

all: $(PARTS)

$(PROJECT).elf: $(PARTS)
	$(CC) $(CFLAGS) -o $(PROJECT).elf -Wl,-Map,$(PROJECT).map $(PARTS)
	/usr/bin/size $(PROJECT).elf | tail -1 | awk '{print "flash: "$$1+$$2" bytes"; print "RAM:   "$$2+$$3" bytes"}'

dis: $(PROJECT).elf
	avr-objdump --source $(PROJECT).elf

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -O ihex $(PROJECT).elf $(PROJECT).hex

$(PROJECT).bin: $(PROJECT).elf
	$(OBJCOPY) -O binary $(PROJECT).elf $(PROJECT).bin

identify: $(PROJECT).hex
	avrdude $(AVRDUDE_OPTS) identify

console:
	avrdude $(AVRDUDE_OPTS) -t

fuses:
	avrdude $(AVRDUDE_OPTS) -U lfuse:w:0xff:m  # ATtiny2313 crystal 8+MHz, slowly rising power, CKDIV8=no, CKOUT=disabled
	avrdude $(AVRDUDE_OPTS) -U hfuse:w:0x9f:m  # ATtiny2313 default but don't erase EEPROM on flash

upload: $(PROJECT).hex
	avrdude $(AVRDUDE_OPTS) -U flash:w:$(PROJECT).hex

verify: $(PROJECT).hex
	avrdude $(AVRDUDE_OPTS) -U flash:v:$(PROJECT).hex

clean:
	rm -f *.o *.elf *.map *.hex *.bin $(PROJECT)

