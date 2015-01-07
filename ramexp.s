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

REU_BANKS
	.byte 0

GEORAM_DETECT
.(
	ldx	#0
	lda	#0
	sta	GEOBUF_BANK
	sta	GEOBUF_PAGE	; GeoRAM $0000
L0	lda	GEOBUF_RAM,x
	sta	SCRATCH_RAM
	inx
	cpx	#0
	bne 	L0
	txa
L1	sta	GEOBUF_RAM,x	; write 190 bytes to GeoRAM
	lda	GEOBUF_RAM,x	; read,
	cmp	GEOBUF_RAM,x	; and compare ...
	bne	L2		; no good, we can't write
	inx
	cpx	#0
	bne	L1 
	lda	REU_PRESENT
	ora	#$02		; All good, GeoRAM is there
	sta	REU_PRESENT
L2	ldx	#0
L2a	lda	SCRATCH_RAM,x
	sta	GEOBUF_RAM,x
	inx
	cpx	#0
	bne	L2a
	rts
.)

REU_DETECT:
.(
        lda     #$55
        stx     REU_BANKS
        jsr     REU_CHECK_BANK          ; do we have bank 0?
        bcs     L1
        lda     #$AA
        ldx     #$01
        jsr     REU_CHECK_BANK          ; do we have bank 1?
        bcs     L1
        inc     REU_BANKS
        lda     #$FE
        ldx     #$02
        jsr     REU_CHECK_BANK          ; do we have bank 2?
        bcs     L1
        inc     REU_BANKS
        lda     #$BB
        ldx     #$03
        jsr     REU_CHECK_BANK          ; do we have bank 3
        bcs     L1
        inc     REU_BANKS
        lda     #$BA
        ldx     #$04
        jsr     REU_CHECK_BANK          ; do we have bank 4
        bcs     L1
        inc     REU_BANKS
        lda     #$B9
        ldx     #$05
        jsr     REU_CHECK_BANK          ; do we have bank 5
        bcs     L1
        inc     REU_BANKS
        lda     #$B8
        ldx     #$06
        jsr     REU_CHECK_BANK          ; do we have bank 6
        bcs     L1
        inc     REU_BANKS
        lda     #$B7
        ldx     #$07
        jsr     REU_CHECK_BANK          ; do we have bank 7
        bcs     L1
        inc     REU_BANKS
        lda     REU_PRESENT
        ora     #$01
        sta     REU_PRESENT
        sec
        rts
L1
        clc
        rts
.)

REU_CHECK_BANK:
.(
        stx     Z_VECTOR4
        sta     Z_TEMP1
L1      ldy     #$00
L2      sta     SECTOR_BUFFER,y
        iny
        bne     L2
        lda     #$00
        sta     REU_RBASE+1
        sta     REU_RBASE
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
        lda     #$FC
        sta     REU_COMMAND
        lda     #$00
        ldy     #$00
L3      sta     SECTOR_BUFFER,y
        iny
        bne     L3
        lda     #$00
        sta     REU_RBASE+1
        sta     REU_RBASE
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
        lda     #$FD
        sta     REU_COMMAND
        lda     Z_TEMP1
        ldy     #$00
L4      cmp     SECTOR_BUFFER,y
        bne     L5
        iny
        bne     L4
        clc
        rts
L5      sec
        rts
.)

IREU_FETCH:
.(
        lda     REU_PRESENT
        and     #$0f
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
        tya                             ; pla
        stx     REU_RBASE+2             ; REU bank (derived S_I+1)
        sta     REU_RBASE+1             ; REU page (derived S_I)
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
        tya                             ; pla
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
        tya                             ; pla
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
        ; do IEC needful here
        ; CK - A and X need to be offsets, and they're not here.
        ;tya
        ldy     #0
        jsr     UIEC_SEEK
        ldx     #5
        jsr     CHKIN
        ldy     #$00
L1:     jsr     CHRIN
        sta     SECTOR_BUFFER,y
        iny
        bne     L1
        jsr     CLRCHN
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
