; =====================================================================
; C = A - B  (32 bits, little-endian, ponteiros com pós-incremento)
;
; Duas versões no mesmo arquivo, rodando em sequência:
;   1) Manual (sem loop)
;   2) Com loop
;
; Antes da versão 2, C é zerado, então dá para conferir que cada
; versão calcula o resultado sozinha.
;
; Teste: A = 0x12345678, B = 0x00117799  ->  C = 0x1222DEDF
; Gera borrow nos bytes 0 e 1, então o SBC é testado de verdade.
; =====================================================================

.INCLUDE <m328Pdef.inc>

.DSEG
.ORG SRAM_START             ; 0x0100
A: .BYTE 4                  ; 0x0100 a 0x0103
B: .BYTE 4                  ; 0x0104 a 0x0107
C: .BYTE 4                  ; 0x0108 a 0x010B

.CSEG
.ORG 0x0000

; --- Valores iniciais (little-endian) ---
setup:
    ; A = 0x12345678
    LDI  R16, 0x78
    STS  A,   R16
    LDI  R16, 0x56
    STS  A+1, R16
    LDI  R16, 0x34
    STS  A+2, R16
    LDI  R16, 0x12
    STS  A+3, R16

    ; B = 0x00117799
    LDI  R16, 0x99
    STS  B,   R16
    LDI  R16, 0x77
    STS  B+1, R16
    LDI  R16, 0x11
    STS  B+2, R16
    CLR  R16
    STS  B+3, R16


; =====================================================================
; VERSÃO 1: MANUAL (sem loop)
; =====================================================================
manual:
    LDI  XL, LOW(A)
    LDI  XH, HIGH(A)
    LDI  YL, LOW(B)
    LDI  YH, HIGH(B)
    LDI  ZL, LOW(C)
    LDI  ZH, HIGH(C)

    ; Byte 0: SUB (sem borrow de entrada)
    LD   R16, X+
    LD   R17, Y+
    SUB  R16, R17           ; 78 - 99 = DF, Carry = 1
    ST   Z+, R16

    ; Byte 1: SBC (subtrai também o borrow)
    LD   R16, X+
    LD   R17, Y+
    SBC  R16, R17           ; 56 - 77 - 1 = DE, Carry = 1
    ST   Z+, R16

    ; Byte 2
    LD   R16, X+
    LD   R17, Y+
    SBC  R16, R17           ; 34 - 11 - 1 = 22, Carry = 0
    ST   Z+, R16

    ; Byte 3 (MSB): sem "+", não há próximo byte
    LD   R16, X
    LD   R17, Y
    SBC  R16, R17           ; 12 - 00 - 0 = 12
    ST   Z, R16


; =====================================================================
; VERSÃO 2: COM LOOP
; =====================================================================
com_loop:
    ; Zera C para provar que esta versão calcula sozinha
    CLR  R16
    STS  C,   R16
    STS  C+1, R16
    STS  C+2, R16
    STS  C+3, R16

    LDI  XL, LOW(A)
    LDI  XH, HIGH(A)
    LDI  YL, LOW(B)
    LDI  YH, HIGH(B)
    LDI  ZL, LOW(C)
    LDI  ZH, HIGH(C)

    ; Byte 0 fora do loop: SUB (sem borrow de entrada), gera o Carry
    LD   R16, X+
    LD   R17, Y+
    SUB  R16, R17           ; 78 - 99 = DF, Carry = 1
    ST   Z+, R16

    LDI  R18, 3             ; contador: faltam 3 bytes (1, 2 e 3)

loop:
    LD   R16, X+            ; A[n]
    LD   R17, Y+            ; B[n]
    SBC  R16, R17           ; A[n] - B[n] - Carry
    ST   Z+, R16            ; C[n]
    DEC  R18                ; não altera o Carry
    BRNE loop               ; repete até o contador chegar a 0

fim:
    RJMP fim


; =====================================================================
; ACOMPANHAMENTO (vale para as duas versões)
;
;  Byte | A  | B  | Conta        | C  | Carry
;  -----+----+----+--------------+----+------
;    0  | 78 | 99 | 78 - 99      | DF |  1
;    1  | 56 | 77 | 56 - 77 - 1  | DE |  1
;    2  | 34 | 11 | 34 - 11 - 1  | 22 |  0
;    3  | 12 | 00 | 12 - 00 - 0  | 12 |  0
;
; SRAM no final de CADA versão:
;   0x0108 = DF   0x0109 = DE   0x010A = 22   0x010B = 12
;   -> C = 0x1222DEDF (little-endian)
;
; Notas:
;   - Na subtração, Carry = 1 significa "pediu emprestado" (borrow).
;   - LD, ST, DEC e BRNE não alteram o Carry; por isso ele passa de
;     um byte (ou iteração) para o outro. Por isso o contador usa DEC
;     e não SUBI, que mexeria no Carry.
;   - Breakpoints sugeridos: em "com_loop" (vê o resultado da manual)
;     e em "fim" (vê o resultado do loop).
; =====================================================================