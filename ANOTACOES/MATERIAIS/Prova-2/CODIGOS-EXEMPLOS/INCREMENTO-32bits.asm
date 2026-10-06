; var_A = var_A + 1  (32 bits, little-endian, pós-incremento)
; Teste: 0x00FFFFFF + 1 = 0x01000000

.INCLUDE <m328Pdef.inc>

.DSEG
.ORG SRAM_START
var_A: .BYTE 4              ; 0x0100 a 0x0103

.CSEG
.ORG 0x0000

setup:                      ; var_A = 0x00FFFFFF -> FF FF FF 00
    LDI  R16, 0xFF
    STS  var_A,   R16
    STS  var_A+1, R16
    STS  var_A+2, R16
    CLR  R16
    STS  var_A+3, R16

main:
    LDI  XL, LOW(var_A)
    LDI  XH, HIGH(var_A)
    LDI  R18, 1             ; valor somado ao byte 0
    CLR  R19                ; zero, só para propagar o Carry

    LD   R16, X             ; byte 0
    ADD  R16, R18           ; FF + 1 = 00, Carry = 1
    ST   X+, R16

    LD   R16, X             ; byte 1
    ADC  R16, R19           ; FF + 0 + 1 = 00, Carry = 1
    ST   X+, R16

    LD   R16, X             ; byte 2
    ADC  R16, R19           ; FF + 0 + 1 = 00, Carry = 1
    ST   X+, R16

    LD   R16, X             ; byte 3 (MSB)
    ADC  R16, R19           ; 00 + 0 + 1 = 01, Carry = 0
    ST   X, R16

fim:
    RJMP fim

; SRAM final: 0x0100 = 00, 0x0101 = 00, 0x0102 = 00, 0x0103 = 01