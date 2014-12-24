# $Id$

DATE =		$(shell date '+%Y/%m/%d')

all:		infocom3 infocom4 infocom5 config ef_menu

infocom3:	i-v3
		exomizer sfx 0x0e00 i-v3 -o infocom3

infocom4:	i-v4
		exomizer sfx 0x1000 i-v4 -o infocom4

infocom5:	i-v5
		exomizer sfx 0x1000 i-v5 -o infocom5

i-v3:		i-v3.s
		xa65 -M -DCUR_DATE="$(DATE)" -o i-v3 i-v3.s

i-v4:		i-v4.s
		xa65 -M -DCUR_DATE="$(DATE)" -o i-v4 i-v4.s

i-v5:		i-v5.s
		xa65 -M -DCUR_DATE="$(DATE)" -o i-v5 i-v5.s

ef_menu:	ef_menu.s
		xa65 -M -O PETSCII -o ef_menu ef_menu.s

config:		config.bas
		petcat -w config.bas > config

bin2efcrt:	bin2efcrt.o

clean:
		rm -f i-v[345] infocom[345] config ef_menu bin2efcrt
