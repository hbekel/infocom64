# $Id$

XA =		xa
XAFLAGS =	-M -O PETSCII
DATE =		$(shell date '+%Y/%m/%d')
INC_STUFF =	common.s ramexp.s sd2iec.s
HIGHMEM =       79

all:		infocom3 infocom4 infocom5 config ef_menu

infocom3:	i-v3
		exomizer sfx 0x0e00 i-v3 -o infocom3

infocom4:	i-v4
		exomizer sfx 0x1000 i-v4 -o infocom4

infocom5:	i-v5
		exomizer sfx 0x1000 i-v5 -o infocom5

i-v3:		i-v3.s $(INC_STUFF)
		$(XA) $(XAFLAGS) -l i-v3.label -DCUR_DATE="$(DATE)" -o i-v3 i-v3.s

i-v4:		i-v4.s $(INC_STUFF)
		$(XA) $(XAFLAGS) -l i-v4.label -DCUR_DATE="$(DATE)" -o i-v4 i-v4.s

i-v5:		i-v5.s $(INC_STUFF)
		$(XA) $(XAFLAGS) -l i-v5.label -DCUR_DATE="$(DATE)" -o i-v5 i-v5.s

ef_menu:	ef_menu.s
		$(XA) $(XAFLAGS) -o ef_menu ef_menu.s

config:		config.bas
		petcat -w config.bas > config

bin2efcrt:	bin2efcrt.o

clean:
		rm -f i-v[345] infocom[345] config ef_menu bin2efcrt i-v[345].label
		rm -f zork.{prg,reu,res} *.bin

zork.prg: i-v3 zork.res
	cat i-v3 zork.res > $@

zork.res: zork.dat
	dd if=$< of=$@ bs=256 count=$(HIGHMEM)

zork.reu: zork.dat
	dd if=/dev/zero of=$@ bs=1024 count=512
	dd if=$< of=$@ bs=256 skip=$(HIGHMEM) conv=notrunc

i-v3.bin: i-v3
	dd if=$< of=$@ bs=1 skip=1537

test: zork.prg zork.reu
	x64sc -reu -reusize 512 -reuimage zork.reu zork.prg
