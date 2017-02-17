# $Id$

XA =		xa
XAFLAGS =	-M -O PETSCII 
XAFLAGS +=      -DDATE=$(shell date '+%Y/%m/%d')

PRELOADED ?=     0
XAFLAGS  +=      -DPRELOADED=$(PRELOADED)

INCLUDES =	common.s ramexp.s sd2iec.s

.PHONY: all clean zork zork.d64 trinity borderzone

all:		infocom3 infocom4 infocom5 config ef_menu

infocom3:	i-v3
		exomizer sfx 0x0e00 i-v3 -o infocom3

infocom4:	i-v4
		exomizer sfx 0x1000 i-v4 -o infocom4

infocom5:	i-v5
		exomizer sfx 0x1000 i-v5 -o infocom5

i-v3:		i-v3.s $(INCLUDES)
		$(XA) $(XAFLAGS) -l i-v3.label -o i-v3 i-v3.s

i-v4:		i-v4.s $(INCLUDES)
		$(XA) $(XAFLAGS) -l i-v4.label -o i-v4 i-v4.s

i-v5:		i-v5.s $(INCLUDES)
		$(XA) $(XAFLAGS) -l i-v5.label -o i-v5 i-v5.s

ef_menu:	ef_menu.s
		$(XA) $(XAFLAGS) -o ef_menu ef_menu.s

config:		config.bas
		petcat -w config.bas > config

bin2efcrt:	bin2efcrt.o

clean:
		rm -f i-v[345] infocom[345] config ef_menu bin2efcrt i-v[345].label
		rm -f {zork,trinity,borderzone}.{prg,reu,res,d64}
		rm -f *.bin
		rm -f colors.h

colors.h: i-v3.s i-v4.s i-v5.s
	make PRELOADED=1 clean i-v3 i-v4 i-v5
	./colors > $@

zork.prg: i-v3 zork.res
	cat i-v3 zork.res > $@

zork.res: zork.dat
	dd if=$< of=$@ bs=256 count=79

zork.reu: zork.dat
	dd if=/dev/zero of=$@ bs=1024 count=512
	dd if=$< of=$@ bs=256 skip=79 conv=notrunc

i-v3.bin: i-v3
	dd if=$< of=$@ bs=1 skip=1537

zork: 
	make PRELOADED=1 clean zork.prg zork.reu 
	x64sc -reu -reusize 512 -reuimage zork.reu zork.prg

zork.d64:
	make PRELOADED=0 clean infocom3
	c1541 -format zork,84 d64 $@ 8 \
		-write infocom3 \
		-write zork.dat story.dat

trinity.prg: i-v4 trinity.res
	cat i-v4 trinity.res > $@

trinity.res: trinity.dat
	dd if=$< of=$@ bs=256 count=175 

trinity.reu: trinity.dat
	dd if=/dev/zero of=$@ bs=1024 count=512
	dd if=$< of=$@ bs=256 skip=175 conv=notrunc

i-v4.bin: i-v4
	dd if=$< of=$@ bs=1 skip=2049

trinity: 
	make PRELOADED=1 clean trinity.prg trinity.reu 
	x64sc -reu -reusize 512 -reuimage trinity.reu trinity.prg

borderzone.prg: i-v5 borderzone.res
	cat i-v5 borderzone.res > $@

borderzone.res: borderzone.dat
	dd if=$< of=$@ bs=256 count=175

borderzone.reu: borderzone.dat
	dd if=/dev/zero of=$@ bs=1024 count=512
	dd if=$< of=$@ bs=256 skip=175 conv=notrunc

i-v5.bin: i-v5
	dd if=$< of=$@ bs=1 skip=2049

borderzone: 
	make PRELOADED=1 clean borderzone.prg borderzone.reu 
	x64sc -reu -reusize 512 -reuimage borderzone.reu borderzone.prg
