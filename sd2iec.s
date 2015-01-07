; $Id$

UIEC_SAVEROOT_TXT1
        .byte   "MD//INFOSAVE",0
UIEC_SAVEROOT_TXT2
        .byte   "CD//INFOSAVE",0
UIEC_SAVEROOT_TXT3
        .byte   "MD//INFOSAVE/:000.000000"
#define	UIEC_REL_OFFSET	14
UIEC_RESET_TXT
        .byte   "UI",$0d
UIEC_ID1_TXT
        .byte   "SD2IEC",0
UIEC_ID2_TXT
	.byte	"UIEC",0
;	.byte	"(C) ",0
UIEC_SEEK_TXT
	.byte	"P", 0, 0, 0, 0, 0

UIEC_BUFFER	= $0900		; sure, why not?

UIEC_SEEK
.(
	sta	UIEC_SEEK_TXT+3
	stx	UIEC_SEEK_TXT+4
	sty	UIEC_SEEK_TXT+5
	lda	#0
	sta	UIEC_SEEK_TXT+2

	lda	#5		; storyfile -- need to separate save channel
	sta	UIEC_SEEK_TXT+1
        ldx     #<UIEC_SEEK_TXT
        ldy     #>UIEC_SEEK_TXT
	lda	#6
	jsr	UIEC_COMMAND
	rts
.)
	

IEC_BIN_TO_HEX
.(
	jsr	UIEC_BIN_TO_DEC

	ldy	#0
	ldx	#0
U1	lda	UIEC_BCD,y
	pha
	and	#$f0
	asl
	asl
	asl
	asl
	clc
	adc	#$30
	sta	UIEC_SAVEROOT_TXT3+UIEC_REL_OFFSET,x
	inx
	pla
	and	#$0f
	clc
	adc	#$30
	sta     UIEC_SAVEROOT_TXT3+UIEC_REL_OFFSET+1,x
	inx
	inx
	iny
	cpy	#3
	bne	U1
.)

; stolen from http://forum.6502.org/viewtopic.php?p=7637

UIEC_BCD
	.byte 00, 00, 00

UIEC_BIN_TO_DEC			; xy=$POINTER
.(
	stx	CNVBIT+1
	inx
	stx	CNVBIT+4
	sty	CNVBIT+2
	sty	CNVBIT+5

BINBCD16:
	sed			; Switch to decimal mode
	lda	#0		; Ensure the result is clear
	sta	UIEC_BCD
	sta	UIEC_BCD+1
	sta	UIEC_BCD+2
	ldx	#16		; The number of source bits
       
CNVBIT:
	asl	$FFFE		; Shift out one bit
	rol	$FFFF
	lda	UIEC_BCD+2		; And add into result
	adc	UIEC_BCD+2
	sta	UIEC_BCD+2
	lda	UIEC_BCD+1	; propagating any carry
	adc	UIEC_BCD+1
	sta	UIEC_BCD+1
	lda	UIEC_BCD+0	; ... thru whole result
	adc	UIEC_BCD+0
	sta	UIEC_BCD+0
	dex			; And repeat for next bit
	bne	CNVBIT
	cld			; Back to binary

.)

UIEC_SWITCH_TO_MD
.(
	lda	#"M"
	sta	UIEC_SAVEROOT_TXT3
	rts
.)

UIEC_SWITCH_TO_CD
.(
	lda	#"C"
	sta	UIEC_SAVEROOT_TXT3
	rts
.)

UIEC_SCAN
.(
        lda     #8
        sta     FA

S1      jsr     UIEC_IDENTIFY
        bcc     S2

        rts             ; this one.  this one here.  signal with carry.

S2	inc     FA
        lda     FA
        cmp     #16
        bcc     S1

        lda     #8
        sta     FA
        clc
        rts
.)

UIEC_IDENTIFY
.(
	jsr	COMMAND_OPEN
	jsr	UIEC_SEND_RESET
	bcs	S0
	jsr	UIEC_READ_STATUS
	jsr	UIEC_CHECK_ID
	bcs	S1	; carry set means it's a UIEC

S0
	jsr	COMMAND_CLOSE
	clc
	rts
S1
	jsr	COMMAND_CLOSE
	sec
	rts
.)

UIEC_CHECK_ID
.(
        ldy     #0
U1      lda     UIEC_ID1_TXT,y
        beq     U3
U2      cmp     UIEC_BUFFER+3,y
        bne     U4
        iny
        bne     U1

U3      sec             ; found it!
        rts

U4	ldy	#0	; nope, try alternate ID
U5	lda	UIEC_ID2_TXT,y	
;	cmp	#0
	beq	U3
U6	cmp	UIEC_BUFFER+3,y
	bne	U7
	iny
	bne	U5

U7	clc
        rts
.)


UIEC_SEND_RESET
.(
        ldx     #<UIEC_RESET_TXT
        ldy     #>UIEC_RESET_TXT
	lda	#3
        jsr     UIEC_COMMAND
        rts
.)

UIEC_READ_STATUS
.(
        clc
        lda     #0
        tay
U0      sta     UIEC_BUFFER,y
        iny
        cpy     #$ff
        bne     U0

        ldx     #15
        jsr     CHKIN
        ldy     #0
U1      jsr     CHRIN
        bcs     U2
        cmp     #$0d
        beq     U2
        sta     UIEC_BUFFER,y
        iny
        bne     U1

U2
;	jsr	CLRCHN
	clc
	rts
.)

UIEC_COMMAND
.(
	stx	L1+1
	sty	L1+2
	tay
	ldx	#15
	jsr	CHKOUT
	ldx	#0
L1	lda	!$FFFF,x
	jsr	CHROUT
	inx
	dey
	bne	L1
	jsr	CLRCHN
	clc
	rts
.)
