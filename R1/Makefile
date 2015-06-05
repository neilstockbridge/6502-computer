
# project specific details

BOARD = R1

FOOTPRINTS=~/files/gEDA-footprints
TEMP_FILE = /tmp/bill-of-materials.tsv

# don't echo commands issued by make
.SILENT:


pcb:
	gsch2pcb --elements-dir $(FOOTPRINTS) $(BOARD).sch
	gnetlist -q -g partslist3 -o $(TEMP_FILE) $(BOARD).sch
	tr \\11 , < $(TEMP_FILE) > $(BOARD).csv
	rm $(TEMP_FILE)

# Export to gerber from within pcb first, then:
gerbers:
	# For http://smart-prototyping.com/
	mv /tmp/$(BOARD).top.gbr            /tmp/$(BOARD).GTL
	mv /tmp/$(BOARD).bottom.gbr         /tmp/$(BOARD).GBL
	mv /tmp/$(BOARD).topmask.gbr        /tmp/$(BOARD).GTS
	mv /tmp/$(BOARD).bottommask.gbr     /tmp/$(BOARD).GBS
	mv /tmp/$(BOARD).topsilk.gbr        /tmp/$(BOARD).GTO
	mv /tmp/$(BOARD).outline.gbr        /tmp/$(BOARD).GML
	mv /tmp/$(BOARD).plated-drill.cnc   /tmp/$(BOARD).TXT
	zip /tmp/$(BOARD).zip  /tmp/$(BOARD).G??  /tmp/$(BOARD).TXT

clean:
	rm -f *~ *.log *.net *.cmd *.new.pcb $(BOARD).csv

