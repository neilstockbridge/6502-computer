
PROJECT = ROM

AFLAGS = --cpu 65C02
LDFLAGS = -C linker.cfg -Ln /tmp/$(PROJECT).lbl

PARTS = asm.o

.S.o:
	ca65 $(AFLAGS) $< -o $@

.SILENT:
all: $(PARTS)
	cl65 $(LDFLAGS) -o /tmp/$(PROJECT).prg $(PARTS)

clean:
	rm -f *.o *.map /tmp/$(PROJECT).prg

