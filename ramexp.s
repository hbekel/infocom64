; $Id$

; uses code from http://www.cbmhardware.de/georam/index.php

REU_CMD_STASH = 	%11111100
REU_CMD_FETCH =		%11111101
SCRATCH_RAM =		$C000
GEOBUF_RAM =		$DE00
GEOBUF_PAGE =		$DFFE
GEOBUF_BANK =		$DFFF	; each bank is 16k, *not* 64k!

				;  512k = $00-$1f
				; 1024k = $00-$3f
				; 2048k = $00-$7f 

GEORAM_SIZE
	.byte 0

GEORAM_TEMP
	.byte 0

REU_BITS
	.byte 7
REU_BANKS
	.byte 0

GEORAM_DETECT
.(
	lda	#0
	tax
	sta	GEOBUF_BANK
	sta	GEOBUF_PAGE	; GeoRAM $0000
L0	lda	GEOBUF_RAM,x
	sta	SCRATCH_RAM
	inx
	bne 	L0
	txa
L1	sta	GEOBUF_RAM,x	; write 190 bytes to GeoRAM
	lda	GEOBUF_RAM,x	; read,
	cmp	GEOBUF_RAM,x	; and compare ...
	bne	L2		; no good, we can't write
	inx
	bne	L1 
	lda	REU_PRESENT
	ora	#$02		; All good, GeoRAM is there
	sta	REU_PRESENT
L2	ldx	#0
L2a	lda	SCRATCH_RAM,x
	sta	GEOBUF_RAM,x
	inx
	bne	L2a
	rts
.)

DET_TXT	.byte "Detected a ",0
REUk_TXT .byte "k REU",0
GEO_TXT .byte "k Geo/NeoRAM",0
C128_TXT		.byte " 128"
C128A_TXT	.byte " 256"
C128B_TXT	.byte " 512"
C128C_TXT	.byte "1024"
C128D_TXT	.byte "2048"
C128E_TXT	.byte "4096"
C128F_TXT	.byte "8192"
C128G_TXT	.byte "16384"

REU_DETECT:	; 2c75
.(
	ldy	#$ff
L0	jsr     REU_SETUP_BANK          ; do we have bank 0?
	jsr	REU_CHECK_BANK
	bcc	L1
	dec	REU_BITS
	clc
	tya
	lsr
	tay
	bne 	L0

L1	sty	REU_BANKS
	cpy	#00
	beq	L1
	lda	REU_PRESENT
        ora     #$01
	sta	REU_PRESENT
	ldy	#5
	ldx	#5
	clc
	jsr	PLOT
	ldy	#0
L1a	lda	DET_TXT,y
	cmp	#0
	beq L1a1
	jsr	CHROUT
	iny
	bne 	L1a
L1a1	lda	REU_BITS
	asl				; x2
	asl				; x4
	tay
	ldx	#0
L1b	lda	C128_TXT,y
	jsr	CHROUT
	inx
	iny
	cpx	#4
	bne	L1b
	ldy	#0
L1b1	lda	REUk_TXT,y
	cmp #0
	beq L1b1a
	jsr	CHROUT
	iny
	bne 	L1b1
L1b1a	sec
	rts

L2	lda     REU_PRESENT
	and	#$FE
        sta     REU_PRESENT
        clc
        rts
.)

REU_SETUP_BANK:	; 2c59
.(
        sty     Z_TEMP1			; bank number we're probing
					; see if we already probed this bank
L1      ldx     #$00
	lda	#$bb
L2      sta     SECTOR_BUFFER,x
        inx
        bne     L2

        lda     #$00
        sta     REU_RBASE+1
        sta     REU_RBASE
        sta     REU_INT
        sta     REU_ACR
        sta     REU_TLEN
        lda     #$01
        sta     REU_TLEN+1
        lda     Z_TEMP1
        sta     REU_RBASE+2
        lda     #>SECTOR_BUFFER
        sta     REU_CBASE+1
        lda     #<SECTOR_BUFFER
        sta     REU_CBASE
        lda     #%11111100		; CBM -> REU
        sta     REU_COMMAND
	rts
.)

REU_CHECK_BANK:
.(
	sty	Z_TEMP1
        lda     #$00
        sta     REU_RBASE+1
        sta     REU_RBASE
        sta     REU_INT
        sta     REU_ACR
        sta     REU_TLEN
        lda     #1
        sta     REU_TLEN+1
        lda     Z_TEMP1
        sta     REU_RBASE+2
        lda     #>SECTOR_BUFFER
        sta     REU_CBASE+1
        lda     #<SECTOR_BUFFER
        sta     REU_CBASE
        lda     #%11111101		; REU -> CBM
        sta     REU_COMMAND
	lda	SECTOR_BUFFER
	cmp	#$bb
	beq	L2
	sec
	rts
L2	clc
	rts
.)

IREU_FETCH:
.(
        lda     REU_PRESENT
        and     #$07
        cmp     #1
        bne	L1
	jsr	CBM_REU_FETCH
	rts
L1	cmp     #2
        bne	L2
	jsr	GEORAM_FETCH
	rts
L2	cmp     #4
        bne	L3
	jsr	EASYFLASH_FETCH
	rts
L3
DIE	jmp     DIE
.)

CBM_REU_FETCH
.(
        stx     REU_RBASE+2             ; REU bank (derived S_I+1)
        sty     REU_RBASE+1             ; REU page (derived S_I)
        lda     #$00
        sta     REU_RBASE               ; always 0
        sta     REU_INT
        sta     REU_ACR
        sta     REU_TLEN
        lda     #$01
        sta     REU_TLEN+1
        lda     #>SECTOR_BUFFER
        sta     REU_CBASE+1
        lda     #<SECTOR_BUFFER
        sta     REU_CBASE
        lda     #%11111101
        sta     REU_COMMAND
        rts
.)

GEORAM_FETCH
.(
        tya
        jsr     SHIFT_ADDRESS
        stx     GEORAM_PAGE
        sta     GEORAM_BANK

        ldy     #0
L1	lda     GEORAM_RAM,y
        sta     SECTOR_BUFFER,y
        iny
        bne     L1
        rts
.)

EASYFLASH_FETCH
.(
        tya
        jsr     SHIFT_ADDRESS
        sta     EF_BANK
        txa
        adc     EF_NONRES_PAGE_BASE
        cmp     #$C0                    ; past ROM page?
        bcc     L1

        inc     EF_BANK                 ; bump up the EasyFlash bank
        sec
        sbc     #$40                    ; and compensate the address

L1	sta     L2+2

        clc
        lda     EF_BANK
        adc     EF_NONRES_BANK_BASE
        sta     EASYFLASH_BANK          ; bank should already be set?
        lda     #EASYFLASH_16K + EASYFLASH_LED
        sta     EASYFLASH_CONTROL
        lda     R6510
        pha
        sei
        lda     #$37
        sta     R6510

        ldy     #0
L2	lda     !$0000,y
        sta     SECTOR_BUFFER,y
        iny
        bne     L2
        pla
        sta     R6510
        lda     #EASYFLASH_KILL
        sta     EASYFLASH_CONTROL
        cli
        rts
.)

IEC_FETCH
.(
        ldy     #0
        jsr     UIEC_SEEK
        ldx     #5
	clc
        jsr     CHKIN
	bcc	L0
	jmp	UIEC_READ_PAGE_ERROR
L0      ldy     #0
L1:     jsr     CHRIN
        sta     SECTOR_BUFFER,y
        iny
        bne     L1
        jsr     CLRCHN
	clc
	rts
.)

IREU_STASH:
.(
        lda     REU_PRESENT
        and     #%00000011
        cmp     #1
        beq     CBM_REU_STASH
        cmp     #2
        beq     GEORAM_STASH
DIE	jmp     DIE
.)

GEORAM_STASH
.(
        lda     Z_VECTOR2+1
        ldx     Z_VECTOR4
        jsr     SHIFT_ADDRESS
        stx     GEORAM_PAGE
        sta     GEORAM_BANK

        ldy     #0
L1      lda     SECTOR_BUFFER,y
        sta     GEORAM_RAM,y
        iny
        bne     L1
        rts
.)

CBM_REU_STASH
.(
        lda     Z_VECTOR2+1
        sta     REU_RBASE+1
        lda     Z_VECTOR2
        sta     REU_RBASE
        lda     #$00
        sta     REU_INT
        sta     REU_ACR
        sta     REU_TLEN
        lda     #$01
        sta     REU_TLEN+1
        lda     Z_VECTOR4
        sta     REU_RBASE+2
        lda     #>SECTOR_BUFFER
        sta     REU_CBASE+1
        lda     #<SECTOR_BUFFER
        sta     REU_CBASE
        lda     #REU_CMD_STASH          ; % 1111 1100
        sta     REU_COMMAND             ; from RAM to REU
	rts
.)
