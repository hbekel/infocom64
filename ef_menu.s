; $Id$

#include "c64.inc"

* = $b000

EF_START_BANK =		$74
EF_BANK =		$75
EF_NONRES_PAGE_BASE =	$7A
EF_NONRES_BANK_BASE =	$7F
LAST_SCAN_KEY   = $02a7
VEC1		= $FB
VEC2		= $FD

; scan for valid datafiles
; check start of each bank for valid signature
; return carry clear if not found,
; return carry set if found, with x and y pointing to game data


SCAN_FOR_GAME
        lda     #$01
        sta     COLOR
        lda     #$0C
        sta     EXTCOL
        sta     BGCOL0
        lda     #147            ; clear screen
        jsr     CHROUT
        lda     #$0E            ; switch to lower case
        jsr     CHROUT
        lda     #$80
        sta     MODE

        ldx     #0
        ldy     #0
        clc
        jsr     PLOT

        ldy     #0
SGl0a   lda     BANNER1,y
        beq     SGl0b
        jsr     CHROUT
        iny
        bne     SGl0a

SGl0b

        ldy     #0
SGl0c   lda     BANNER2,y
        beq     SGl0d
        jsr     CHROUT
        iny
        bne     SGl0c

SGl0d
	lda	#$bc
	sta	VEC1+1
	sta	VEC2+1
	lda	#0
	sta	VEC1
	lda	#1
	sta	VEC2
        ldx     #0
SGl1a
	ldy	#0
	lda     (VEC1),y
        beq     SGl3a
        sta     EF_GAME_BANKS,x
        ldy     #13
SGl1a1  lda     #" "
        jsr     CHROUT
        dey
        bne SGl1a1
        txa
        clc
        adc     #$31
        jsr     CHROUT
        lda     #")"
        jsr     CHROUT
        lda     #" "
        jsr     CHROUT
        ldy     #0
SGl1b   lda     (VEC2),y
        cmp     #0
        beq     SGl1c
        jsr     CHROUT
        iny
        bne     SGl1b

SGl1c   lda     #$0d
        jsr     CHROUT
        clc
        lda     #$20
        adc     VEC1
        sta     VEC1
        lda     #$00
        adc     VEC1+1
        sta     VEC1+1

        clc
        lda     #$20
        adc     VEC2
        sta     VEC2
        lda     #$00
        adc     VEC2+1
        sta     VEC2+1

        inx
        cpx     #9
        bne     SGl1a

SGl3a   txa
        clc
        adc     #$30
        sta     BANNER3 + 30
        clc
        adc     #$01
        sta     SGL2b + 1

SGl3b   ldy     #0
        ldx     #13
        clc
        jsr     PLOT

        ldy     #0
SGl3c   lda     BANNER3,y

        beq     SGl2
        jsr     CHROUT
        iny
        bne     SGl3c


SGl2
        lda     #8              ; default to drive 8
        sta     FA
SGl2aa
        jsr     DISPLAY_DRIVE_SEL
SGl2a
        ldx     #0
        jsr     SCNKEY
        lda     LAST_SCAN_KEY
        stx     LAST_SCAN_KEY
        cmp     LAST_SCAN_KEY
        beq     SGl2a
        cpx     #$85            ; F1
        beq     INC_FORE_COLOR
        cpx     #$86            ; F3
        beq     INC_BACK_COLOR
        cpx     #$87            ; F5
        beq     INC_PROMPT_COLOR
        cpx     #$88            ; F7
        beq     INC_SAVE_DRIVE
        cpx     #$89            ; F2
        beq     DEC_FORE_COLOR
        cpx     #$8a            ; F4
        beq     DEC_BACK_COLOR
        cpx     #$8b            ; F6
        beq     DEC_PROMPT_COLOR
        cpx     #$8c            ; F8
        beq     DEC_SAVE_DRIVE

        cpx     #$31
        bcc     SGl2a
SGL2b   cpx     #$3a
        bcs     SGl2a

        txa
        sec
        sbc     #$31
        tay
        lda     EF_GAME_BANKS,y
        rts


INC_FORE_COLOR
DEC_FORE_COLOR
INC_BACK_COLOR
DEC_BACK_COLOR
INC_PROMPT_COLOR
DEC_PROMPT_COLOR
        jmp     SGl2aa

INC_SAVE_DRIVE
.(
        inc     FA
        lda     FA
        cmp     #16
        bcc     SGl2aa
        lda     #8
        sta     FA
        jmp     SGl2aa
.)

DEC_SAVE_DRIVE
.(
        dec     FA
        lda     FA
        cmp     #8
        bcs     SGl2aa
        lda     #15
        sta     FA
        jmp     SGl2aa
.)


DISPLAY_DRIVE_SEL
        ldy     #0
        ldx     #23
        clc
        jsr     PLOT

        ldy     #0
CRD1a   lda     CURDRVTXT,y
        beq     CRD1b
        jsr     CHROUT
        iny
        bne     CRD1a

CRD1b   lda     FA
        clc
        adc     #$30
        cmp     #$3a
        bcs     CRD1c           ; have to print two bytes :(
        jsr     CHROUT
        lda     #" "
        jsr     CHROUT
        jmp     CRD1d

CRD1c
        sec
        sbc     #$0a
        tay
        lda     #"1"
        jsr     CHROUT
        tya
        jsr     CHROUT
CRD1d
        rts

EF_GAME_BANKS = $c000

BANNER1 .byte   "    Infocom z4 EasyFlash Collection", $0d, 0
BANNER2 .byte   "          2014 Chris Kobayashi", $0d, $0d, 0
BANNER3 .byte   "        Please choose game (1-*)"   ; 30 splata
        .byte   $0d
        .byte   $0d
        .byte   " Press F1/F2 to cycle foreground colors", $0d
        .byte   " Press F3/F4 to cycle background colors", $0d
        .byte   " Press F5/F6 to cycle the prompt colors", $0d
        .byte   "Press F7/F8 to cycle save/restore device", $0d
;       .byte   "                                        "
        .byte   0
CURDRVTXT .byte "Save/restore Device: ", 0

