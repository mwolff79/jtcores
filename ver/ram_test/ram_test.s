	ORG $8000

	FILL $FF,$e000-$8000

	ORG $E000
RESET: 
	ORCC #$10
	LDU #0

	; Horizontal Scroll
	CLR	$3B08
	CLR $3B09

	; Vertical Scroll
	CLR	$3B0A
	CLR $3B0B

	; Red, Green Test
	LDA #$A5
	LDX #$3800
@LOOP:
	STA ,X
	CMPA ,X+
	BNE ERROR_RGRAM
	CMPX #$3900
	BNE @LOOP

	; Blue Test
	LDA #$A0
	LDX #$3900
@LOOP:
	STA ,X
	CMPA ,X+
	BNE ERROR_BRAM
	CMPX #$3A00
	BNE @LOOP

	BRA NO_ERROR

	; Scroll RAM test, 30ms
	LDA #$AA
	LDX #$2800
@LOOP:
	STA ,X
	CMPA ,X+
	BNE ERROR_CHRAM
	CMPX #$3000
	BNE @LOOP

	; Main RAM test, 105ms
	LDX #$0000
	LDA #$55
@LOOP:	
	STA ,X
	CMPA ,X+
	BNE ERROR_RAM
	CMPX #$2000
	BNE @LOOP

	; Character RAM test, 30ms
	LDA #$AA
	LDX #$2000
@LOOP:
	STA ,X
	CMPA ,X+
	BNE ERROR_CHRAM
	CMPX #$2800
	BNE @LOOP


NO_ERROR:
	LDU #0
	BRA NO_ERROR

ERROR_RAM:
	LDU #1
	BRA ERROR_RAM

ERROR_CHRAM:
	LDU #2
	BRA ERROR_CHRAM

ERROR_RGRAM:
	LDU #3
	BRA ERROR_RGRAM

ERROR_BRAM:
	LDU #4
	BRA ERROR_BRAM


	FILL $FF,$FFFE-*

	.WORD RESET