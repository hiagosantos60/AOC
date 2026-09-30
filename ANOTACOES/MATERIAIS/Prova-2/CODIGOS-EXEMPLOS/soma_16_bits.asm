.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
num1:   .BYTE 2             ; 16 bits (0x0100 e 0x0101)
num2:   .BYTE 2             ; 16 bits (0x0102 e 0x0103)
res:    .BYTE 2             ; 16 bits (0x0104 e 0x0105)

.CSEG
.ORG 0x0000

    ; --- SETUP: valores iniciais (little-endian) ---
    ; num1 = 0x01FF -> FF 01
    LDI  R16, 0xFF
    STS  num1,   R16        ; num1[0] = 0xFF
    LDI  R16, 0x01
    STS  num1+1, R16        ; num1[1] = 0x01

    ; num2 = 0x0001 -> 01 00
    LDI  R16, 0x01
    STS  num2,   R16        ; num2[0] = 0x01
    LDI  R16, 0x00
    STS  num2+1, R16        ; num2[1] = 0x00

    ; Resultado esperado: 0x01FF + 0x0001 = 0x0200
    ; Na SRAM (little-endian): 0x0104 = 00, 0x0105 = 02

main:
    ; --- Aponta cada ponteiro para o primeiro byte da variável ---
    LDI XL, LOW(num1)       ; X = 0x0100
    LDI XH, HIGH(num1)

    LDI YL, LOW(num2)       ; Y = 0x0102
    LDI YH, HIGH(num2)

    LDI ZL, LOW(res)        ; Z = 0x0104
    LDI ZH, HIGH(res)

    ; --- Byte baixo (LSB) ---
    LD  R16, X+             ; Lê num1[0] e avança X
    LD  R17, Y+             ; Lê num2[0] e avança Y
    ADD R16, R17            ; FF + 01 = 0x100 -> R16 = 00, Carry = 1
    ST  Z+, R16             ; res[0] = 00 e avança Z

    ; --- Byte alto (MSB) ---
    LD  R16, X              ; Lê num1[1] (último byte, sem incremento)
    LD  R17, Y              ; Lê num2[1] (último byte, sem incremento)
    ADC R16, R17            ; 01 + 00 + Carry(1) = 02, Carry = 0
    ST  Z, R16              ; res[1] = 02 (último byte, sem incremento)

loop:
    RJMP loop               ; Loop infinito para parar a execução

; =====================================================================
; ACOMPANHAMENTO NO SIMULADOR
;
;  Byte  | num1 | num2 | Conta        | res | Carry
;  ------+------+------+--------------+-----+------
;  Baixo |  FF  |  01  | FF + 01      | 00  |  1
;  Alto  |  01  |  00  | 01 + 00 + 1  | 02  |  0
;
; Ponteiros ao final: X = 0x0101, Y = 0x0103, Z = 0x0105
; (cada um no último byte da sua variável)
;
; Resultado na SRAM: 0x0104 = 00, 0x0105 = 02 -> res = 0x0200
; =====================================================================