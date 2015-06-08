
PROJECT = ROM

OUTDIR=/tmp

AFLAGS = --cpu 65C02
LDFLAGS = -C linker.cfg -Ln $(OUTDIR)/$(PROJECT).lbl

#PARTS = prg_hdr.o UART.o micro.o
PARTS = prg_hdr.o UART.o monitor.o

.S.o:
	ca65 $(AFLAGS) $< -o $@

.SILENT:
all: $(PARTS)
	cl65 $(LDFLAGS) -o $(OUTDIR)/$(PROJECT).prg $(PARTS)

clean:
	rm -f *.o *.map $(OUTDIR)/$(PROJECT).prg

