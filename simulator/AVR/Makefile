
# project specific details

PROJECT = 6502-heart
TARGET = atmega1284p
AVRDUDE_PART = m1284p
#SYS_CLOCK = 20000000
SYS_CLOCK = 7372800

PARTS = main.o

OPTIMIZE = -Os

DEVICE = $(TARGET)

# details common across projects

CC = avr-gcc
OBJCOPY = avr-objcopy

DEFINES = -DF_CPU=$(SYS_CLOCK)
CFLAGS = -std=c99 -mmcu=$(TARGET) $(OPTIMIZE) -fshort-enums $(DEFINES) -Wall $(DEBUG)
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

$(PROJECT).hex: $(PROJECT).elf
	$(OBJCOPY) -O ihex $(PROJECT).elf $(PROJECT).hex

$(PROJECT).bin: $(PROJECT).elf
	$(OBJCOPY) -O binary $(PROJECT).elf $(PROJECT).bin

dis: $(PROJECT).elf
	avr-objdump --source $(PROJECT).elf

identify: $(PROJECT).hex
	avrdude $(AVRDUDE_OPTS) identify

console:
	avrdude $(AVRDUDE_OPTS) -t

fuses:
	avrdude $(AVRDUDE_OPTS) -U lfuse:w:0xd7:m  # ATmega1284 7:CKDIV8=no,6:CKOUT=no, 4-5:SUT,0-3:CKSEL. CKSEL3..1 3:Full-swing XTAL, CKSEL0=1,SUT=1: 20M XTAL+BOD
	avrdude $(AVRDUDE_OPTS) -U hfuse:w:0xd1:m  # ATmega1284 Default but disabled JTAG to regain use of PC3..5 and disable EEPROM wipe on flash
	avrdude $(AVRDUDE_OPTS) -U efuse:w:0xfc:m  # ATmega1284 BODLEVEL ~4.3V

upload: $(PROJECT).hex
	avrdude $(AVRDUDE_OPTS) -U flash:w:$(PROJECT).hex

verify: $(PROJECT).hex
	avrdude $(AVRDUDE_OPTS) -U flash:v:$(PROJECT).hex

clean:
	rm -f *.o *.elf *.map *.hex *.bin $(PROJECT)

