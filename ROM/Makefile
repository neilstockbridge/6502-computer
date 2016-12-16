
PROJECT = ROM

OUTDIR=/tmp

AFLAGS = --cpu 65C02 -D TEST=1
LDFLAGS = --target none -C linker.cfg -Ln $(OUTDIR)/$(PROJECT).lbl

#PARTS = prg_hdr.o UART.o micro.o
PARTS = prg_hdr.o UART.o SPI.o cycle_counter.o math.o zp_ptr.o stream.o zp_stack.o console.o SPI_flash.o monitor.o test.o

.S.o:
	ca65 $(AFLAGS) $< -o $@

.SILENT:
all: $(PARTS)
	cl65 $(LDFLAGS) -o $(OUTDIR)/$(PROJECT).prg $(PARTS)

clean:
	rm -f *.o *.map $(OUTDIR)/$(PROJECT).prg

