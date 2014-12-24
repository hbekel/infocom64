; $Id$

;---------------------------------------------
;  "newmodem.src" - 64 mode.
;  @128 = changes for 128 mode.
;---------------------------------------------
rstkey  =$fe56         ;@128 $fa4b
norest  =$fe72         ;@128 $fa5f
return  =$febc         ;@128 $ff33
oldout  =$f1ca         ;@128 $ef79
oldchk  =$f21b         ;@128 $f10e
findfn  =$f30f         ;@128 $f202
devnum  =$f31f         ;@128 $f212
nofile  =$f701         ;@128 $f682
;---------------------------------------------
; *       =$ce00         ;@128 $1a00
;---------------------------------------------
xx00    jmp setup
xx03    jmp inable
xx06    jmp disabl
xx09    jmp rsget
xx0c    jmp rsout
        nop
strt24  .word $01cb    ; 459 start-bit times
strt12  .word $0442    ;1090
strt03  .word $1333    ;4915
full24  .word $01a5    ; 421 full-bit times
full12  .word $034d    ; 845
full03  .word $0d52    ;3410
;---------------------------------------------
232setup	lda #<NMI64    ;@128 #<NMI128
	        ldy #>NMI64    ;@128 #>NMI128
	        sta NMINV
	        sty NMINV+1
	        lda #<CHKIN_232
	        ldy #>CHKIN_232
	        sta ICHKIN
	        sty ICHKIN+1
	        lda #<CHROUT_232
	        ldy #>CHROUT_232
	        sta IBSOUT
	        sty IBSOUT+1
	        rts
;---------------------------------------------
NMI64   pha            ;new nmi handler
        txa
        pha
        tya
        pha
NMI128  cld
        ldx TI2BHI      ;sample timer b hi byte
        lda #$7f       ;disable cia nmi's
        sta CI2ICR
        lda CI2ICR      ;read/clear flags
        bpl notcia     ;(restore key)
        cpx TI2BHI      ;tb timeout since 3060?
        ldy $dd01      ;(sample pin c)
        bcs mask       ;no
        ora #$02       ;yes, set flag in acc.
        ora CI2ICR      ;read/clear flags again
mask    and ENABL      ;mask out non-enabled
        tax            ;these must be serviced
        lsr            ;timer a? (bit 0)
        bcc ckflag     ;no
        lda $dd00      ;yes, put bit on pin m
        and #$fb
        ora $b5
        sta $dd00
ckflag  txa
        and #$10       ;*flag nmi? (bit 4)
        beq nmion      ;no
strtlo  lda #$42       ;yes, start-bit to tb
        sta TI2BLO
strthi  lda #$04
        sta TI2BHI
        lda #$11       ;start tb counting
        sta CI2CRB
        lda #$12       ;*flag nmi off, tb on
        eor ENABL      ;update mask
        sta ENABL
        sta CI2ICR      ;enable new config.
fulllo  lda #$4d       ;change reload latch
        sta TI2BLO      ;  to full-bit time
fullhi  lda #$03
        sta TI2BHI
        lda #$08       ;# of bits to receive
        sta $a8
        bne chktxd     ;branch always
notcia  ldy #$00
        jmp rstkey     ;or jmp norest
nmion   lda ENABL      ;re-enable nmi's
        sta CI2ICR
        txa
        and #$02       ;timer b? (bit 1)
        beq chktxd     ;no
        tya            ;yes, sample from 3120
        lsr
        ror $aa        ;rs232 is lsb first
        dec $a8        ;byte finished?
        bne txd        ;no
        ldy RIDBE      ;yes, byte to buffer
        lda $aa
        sta (RIBUF),y  ;(no overrun test)
        inc RIDBE
        lda #$00       ;stop timer b
        sta CI2CRB
        lda #$12       ;tb nmi off, *flag on
switch  ldy #$7f       ;disable nmi's
        sty CI2ICR      ;twice
        sty CI2ICR
        eor ENABL      ;update mask
        sta ENABL
        sta CI2ICR      ;enable new config.
txd     txa
        lsr            ;timer a?
chktxd  bcc exit       ;no
        dec $b4        ;yes, byte finished?
        bmi char       ;yes
        lda #$04       ;no, prep next bit
        ror $b6        ;(fill with stop bits)
        bcs store
low     lda #$00
store   sta $b5
exit    jmp return     ;restore regs, rti
char    ldy RODBS
        cpy RODBE      ;buffer empty?
        beq txoff      ;yes
getbuf  lda (ROBUF),y  ;no, prep next byte
        inc RODBS
        sta $b6
        lda #$09       ;# bits to send
        sta $b4
        bne low        ;always - do start bit
txoff   ldx #$00       ;stop timer a
        stx CI2CRA
        lda #$01       ;disable ta nmi
        bne switch     ;always
;---------------------------------------------
disabl  pha            ;turns off modem port
test    lda ENABL
        and #$03       ;any current activity?
        bne test       ;yes, test again
        lda #$10       ;no, disable *flag nmi
        sta CI2ICR
        lda #$02
        and ENABL      ;currently receiving?
        bne test       ;yes, start over
        sta ENABL      ;all off, update mask
        pla
        rts
;---------------------------------------------
CHROUT_232  pha            ;new bsout
        lda $9a
        cmp #$02
        bne notmod
        pla
rsout   sta $9e        ;output to modem
        sty $97
point   ldy RODBE
        sta (ROBUF),y  ;not official till 5120
        iny
        cpy RODBS      ;buffer full?
        beq fulbuf     ;yes
        sty RODBE      ;no, bump pointer
strtup  lda ENABL
        and #$01       ;transmitting now?
        bne ret3       ;yes
        sta $b5        ;no, prep start bit,
        lda #$09
        sta $b4        ;  # bits to send,
        ldy RODBS
        lda (ROBUF),y
        sta $b6        ;  and next byte
        inc RODBS
        lda BAUDOF     ;full tx bit time to ta
        sta TI2ALO
        lda BAUDOF+1
        sta TI2AHI
        lda #$11       ;start timer a
        sta CI2CRA
        lda #$81       ;enable ta nmi
change  sta CI2ICR      ;nmi clears flag if set
        php            ;save irq status
        sei            ;disable irq's
        ldy #$7f       ;disable nmi's
        sty CI2ICR      ;twice
        sty CI2ICR
        ora ENABL      ;update mask
        sta ENABL
        sta CI2ICR      ;enable new config.
        plp            ;restore irq status
ret3    clc
        ldy $97
        lda $9e
        rts
fulbuf  jsr strtup
        jmp point
notmod  pla            ;back to old bsout
        jmp oldout
;---------------------------------------------
CHKIN_232  jsr findfn     ;new chkin
        bne nosuch
        jsr devnum
        lda $ba
        cmp #$02
        bne back
        sta $99
inable  sta $9e        ;enable rs232 input
        sty $97
baud    lda BAUDOF+1   ;set receive to same
        and #$06       ;  baud rate as xmit
        tay
        lda strt24,y
        sta strtlo+1   ;overwrite value @ 3270
        lda strt24+1,y
        sta strthi+1
        lda full24,y
        sta fulllo+1
        lda full24+1,y
        sta fullhi+1
        lda ENABL
        and #$12       ;*flag or tb on?
        bne ret1       ;yes
        sta CI2CRB      ;no, stop tb
        lda #$90       ;turn on flag nmi
        jmp change
nosuch  jmp nofile
back    lda $ba
        jmp oldchk
;---------------------------------------------
rsget   sta $9e        ;input from modem
        sty $97
        ldy RIDBS
        cpy RIDBE      ;buffer empty?
        beq ret2       ;yes
        lda (RIBUF),y  ;no, fetch character
        sta $9e
        inc RIDBS
ret1    clc            ;cc = char in acc.
ret2    ldy $97
        lda $9e
last    rts            ;cs = buffer was empty
