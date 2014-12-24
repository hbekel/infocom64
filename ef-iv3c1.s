; $Id$

; This was mostly "borrowed" from skoe's excellent EasyFlash bank cartridge
; example.
;
; I altered it to use xa65, embed the interpreter and story files, 
; pad the size up to something acceptible by EasyFlash, and moved the bootstrap
; up to $FF00.  That's about it.

EASYFLASH_BANK    = $DE00
EASYFLASH_CONTROL = $DE02
EASYFLASH_LED     = $80
EASYFLASH_16K     = $07
EASYFLASH_KILL    = $04

* = $C000	; really $8000, but must accomodate EasyFlash convention

; =============================================================================
; 00:0:0000 (LOROM, bank 0)

bankStart_00_0:

; Interpreter at $8000

.bin	0, 0, "INTERPRETER"

; pad up to next 16k bank ($a000 from a PC perspective, effectively $e000)

;.dsb    $A000-*, $ff

; =============================================================================
; 00:1:0000 (HIROM, bank 0)

; we want this *way* high to deal with v5 large interpreter :)

.dsb	$F000-*, $ff

.bin	0, 0, "EF_MENU"

; EasyAPI goop

.dsb	$F800-*, $ff
.bin	2, 0, "eapi-am29f040-14"

.dsb	$FB00-*, $ff
.byte	$65, $66, $2d, $6e, $41, $4d, $45, $3a
.byte	"Infocom v3 Game", 0	; 16 max length

.dsb	$FC00-*, $FF

	.byte	1
	.byte	"STORY1_PRETTY", 0

.dsb	$FC20-*, $FF

	.byte	7
	.byte	"STORY2_PRETTY", 0

.dsb	$FC40-*, $FF

	.byte	13
	.byte	"STORY3_PRETTY", 0

.dsb	$FC60-*, $FF

	.byte	19
	.byte	"STORY4_PRETTY", 0

.dsb	$FC80-*, $FF

	.byte	26
	.byte	"STORY5_PRETTY", 0

.dsb	$FCA0-*, $FF

	.byte	33
	.byte	"STORY6_PRETTY", 0

.dsb	$FCC0-*, $FF

	.byte	41
	.byte	"STORY7_PRETTY", 0

.dsb	$FCE0-*, $FF

	.byte	48
	.byte	"STORY8_PRETTY", 0

.dsb	$FD00-*, $FF

	.byte	55
	.byte	"STORY9_PRETTY", 0

.dsb	$FF00-*, $ff

bankStart_00_1:

coldStart:
        ; === the reset vector points here ===
        sei
        ldx #$ff
        txs
        cld

        ; enable VIC (e.g. RAM refresh)
        lda #8
        sta $d016

        ; write to RAM to make sure it starts up correctly (=> RAM datasheets)
startWait:
        sta $0100, x
        dex
        bne startWait

        ; copy the final start-up code to RAM (bottom of CPU stack)
        ldx #(startUpEnd - startUpCode)
l1:
        lda startUpCode, x
        sta $0100, x
        dex
        bpl l1
        jmp $0100

startUpCode:
.(	; actually $0100 from here
        ; === this code is copied to the stack area, does some inits ===
        ; === scans the keyboard and kills the cartridge or          ===
        ; === starts the main application                            ===
        lda #EASYFLASH_16K + EASYFLASH_LED
        sta EASYFLASH_CONTROL

        ; Check if one of the magic kill keys is pressed
        ; This should be done in the same way on any EasyFlash cartridge!

        ; Prepare the CIA to scan the keyboard
        lda #$7f
        sta $dc00   ; pull down row 7 (DPA)

        ldx #$ff
        stx $dc02   ; DDRA $ff = output (X is still $ff from copy loop)
        inx
        stx $dc03   ; DDRB $00 = input

        ; Read the keys pressed on this row
        lda $dc01   ; read coloumns (DPB)

        ; Restore CIA registers to the state after (hard) reset
        stx $dc02   ; DDRA input again
        stx $dc00   ; Now row pulled down

        ; Check if one of the magic kill keys was pressed
        and #$e0    ; only leave "Run/Stop", "Q" and "C="
        cmp #$e0
        bne kill    ; branch if one of these keys is pressed

        ; same init stuff the kernel calls after reset
        ldx #0
        stx $d016
        jsr $ff84   ; Initialise I/O (aka $FDA3)

        ; These may not be needed - depending on what you'll do
        jsr $ff87   ; Initialise System Constants (aka $FD50)
        jsr $ff8a   ; Restore Kernal Vectors (aka $FD15)
        jsr $ff81   ; Initialize screen editor (aka $FF5B)

	lda #$02
	sta $fb
	lda $8000
	sta $fd
	lda #$80
	sta $fc
	lda $8001
	sta $fe
	ldx #$40
	ldy #$00
ckl1	lda ($fb),y
	sta ($fd),y
	iny
	bne ckl1
	inc $fc
	inc $fe
	dex
	bne ckl1

        ; start the application code
ckj1
	lda	#4
	sta	$02
	jsr	$b000
	jmp	($8000)

kill:
        lda	#EASYFLASH_KILL
        sta	EASYFLASH_CONTROL
        jmp	($fffc) ; reset
.)
startUpEnd:

        ; fill it up to $FFFA to put the vectors there
	.dsb    $FFFA-*, $ff

        .word reti        ; NMI
        .word coldStart   ; RESET

        ; we don't need the IRQ vector and can put RTI here to save space :)
reti:
        rti
        .byte 	$ff

; =============================================================================
; 01:0:0000 (LOROM, bank 1)
bankStart_01_0:
        ; from here on out, it's all story data :)

* = $0000

#ifdef	STORY1
.bin	0, 0, "STORY1"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY2
.bin	0, 0, "STORY2"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY3
.bin	0, 0, "STORY3"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY4
.bin	0, 0, "STORY4"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY5
.bin	0, 0, "STORY5"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY6
.bin	0, 0, "STORY6"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY7
.bin	0, 0, "STORY7"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY8
.bin	0, 0, "STORY8"
.dsb	$2000 - (* & $1FFF), $FF
#endif

#ifdef	STORY9
.bin	0, 0, "STORY9"
.dsb	$2000 - (* & $1FFF), $FF
#endif

