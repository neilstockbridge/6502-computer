
# project specific details

PROJECT = N6502R2-monitor
TARGET = atmega164pa
AVRDUDE_PART = m164p
SYS_CLOCK = 7372800

PARTS = main.o

#OPTIMIZE = -Os

LFUSE=0xf7# ATmega164PA full-swing crystal, slowly rising power, CKDIV8=no, CKOUT=disabled
HFUSE=0xd9# ATmega164PA OCD:no JTAG:no SPI:y WDT:no EEPROM:wipe BOOTLDR:0 RSTVEC:X

include ../../../AVR-Makefile

hfuse:
	avrdude $(AVRDUDE_OPTS) -U hfuse:w:$(HFUSE):m

