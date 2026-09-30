.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
num1:   .BYTE 4   ; Reservar 4 bytes (32 bits) na RAM
num2:   .BYTE 4   ; Reservar 4 bytes (32 bits) na RAM
res:    .BYTE 4   ; Reservar 4 bytes (32 bits) para o resultado

.CSEG
.ORG 0x0000

main:
    ; 1. Carregar os endereços Iniciais nos Ponteiros X, Y e Z
    LDI XL, LOW(num1)
    LDI XH, HIGH(num1)
    
    LDI YL, LOW(num2)
    LDI YH, HIGH(num2)
    
    LDI ZL, LOW(res)
    LDI ZH, HIGH(res)

    ; =========================================================
    ; BYTE 0 (Bits 0 a 7 - Byte Menos Significativo / LOW)
    ; =========================================================
    LD  R16, X+   ; R16 = num1[0] (avança X para byte 1)
    LD  R17, Y+   ; R17 = num2[0] (avança Y para byte 1)
    ADD R16, R17  ; Soma simples sem Carry (primeiro byte)
    ST  Z+, R16   ; res[0] = R16  (avança Z para byte 1)

    ; =========================================================
    ; BYTE 1 (Bits 8 a 15)
    ; =========================================================
    LD  R16, X+   ; R16 = num1[1] (avança X para byte 2)
    LD  R17, Y+   ; R17 = num2[1] (avança Y para byte 2)
    ADC R16, R17  ; Soma COM o Carry gerado pelo Byte 0
    ST  Z+, R16   ; res[1] = R16  (avança Z para byte 2)

    ; =========================================================
    ; BYTE 2 (Bits 16 a 23)
    ; =========================================================
    LD  R16, X+   ; R16 = num1[2] (avança X para byte 3)
    LD  R17, Y+   ; R17 = num2[2] (avança Y para byte 3)
    ADC R16, R17  ; Soma COM o Carry gerado pelo Byte 1
    ST  Z+, R16   ; res[2] = R16  (avança Z para byte 3)

    ; =========================================================
    ; BYTE 3 (Bits 24 a 31 - Byte Mais Significativo / HIGH)
    ; =========================================================
    LD  R16, X+   ; R16 = num1[3]
    LD  R17, Y+   ; R17 = num2[3]
    ADC R16, R17  ; Soma COM o Carry gerado pelo Byte 2
    ST  Z+, R16   ; res[3] = R16

fim:
    rjmp fim