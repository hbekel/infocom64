; $Id$

UIEC_DRIVE_TXT
	.asc	"Drive ",0
UIEC_DRIVE_ISNT_TXT
	.asc	" not a"
UIEC_DRIVE_IS_TXT
	.asc	" SD2IEC/uIEC",0
UIEC_SAVEROOT_TXT1
        .asc	"md", $2f, $2f, "infosave",0
UIEC_SAVEROOT_TXT2
        .asc	"cd", $2f, $2f, "infosave",0
UIEC_SAVEROOT_TXT3
        .asc	"md", $2f, $2f, "infosave", $2f, ":000.000000"
#define	UIEC_REL_OFFSET	14
UIEC_RESET_TXT
        .asc	"ui"
UIEC_ID1_TXT
        .asc	"sd2iec",0
UIEC_ID2_TXT
	.asc	"uiec",0
UIEC_SEEK_TXT
	.asc	"p", 0, 0, 0, 0, 0

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
	jmp	UIEC_COMMAND
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
	rts
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
	lda	UIEC_BCD+2	; And add into result
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
	rts
.)

UIEC_SWITCH_TO_MD
.(
	lda	#"m"
	sta	UIEC_SAVEROOT_TXT3
	rts
.)

UIEC_SWITCH_TO_CD
.(
	lda	#"c"
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
        ldy     #0
        ldx     #23
        clc
        jsr     PLOT
	ldy	#0
L0	lda	UIEC_DRIVE_TXT,y
	cmp	#0
	beq	L1
	jsr	CHROUT
	iny
	bne	L0

L1	lda     FA
        clc
        adc     #$30
        cmp     #$3a
        bcs     CRD1c           ; have to print two bytes :(
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
	jsr	COMMAND_OPEN
	jsr	UIEC_SEND_RESET
	bcs	S0
	jsr	UIEC_READ_STATUS
	jsr	UIEC_CHECK_ID
	bcs	S1	; carry set means it's a UIEC

S0
	jsr	COMMAND_CLOSE
	ldy	#0
S0a	lda	UIEC_DRIVE_ISNT_TXT,y
	cmp	#0
	beq	S0b
	jsr	CHROUT
	iny
	bne	S0a
S0b	clc
	rts
S1
	jsr	COMMAND_CLOSE
	ldy	#0
S1a	lda	UIEC_DRIVE_IS_TXT,y
	cmp	#0
	beq	S1b
	jsr	CHROUT
	iny
	bne	S1a
S1b	sec
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
	lda	#2
        jmp	UIEC_COMMAND
.)

UIEC_READ_STATUS
.(
        clc
        lda     #0
        tay
U0      sta     UIEC_BUFFER,y
        iny
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

UIEC_ONLY
.(
	lda	REU_PRESENT
	and	#$0f
	cmp	#8
	beq	L1
	clc
	rts
L1	sec
	rts
.)
