.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
var_A: .BYTE 4              ; Aloca 4 bytes (32 bits) para a variável

.CSEG
.ORG 0x0000

incremento_32_bits:
    ; --- SETUP: var_A = 0x00FFFFFF (little-endian: FF FF FF 00) ---
    LDI  R26, LOW(var_A)    ; XL = byte baixo do endereço de var_A (0x00)
    LDI  R27, HIGH(var_A)   ; XH = byte alto do endereço de var_A (0x01) -> X = 0x0100
    LDI  R16, 0xFF
    ST   X+, R16            ; A[0] = 0xFF, X passa a apontar para 0x0101
    ST   X+, R16            ; A[1] = 0xFF, X passa a apontar para 0x0102
    ST   X+, R16            ; A[2] = 0xFF, X passa a apontar para 0x0103
    CLR  R16                ; R16 = 0x00
    ST   X, R16             ; A[3] = 0x00 (sem incremento, é o último byte)

    ; Resultado esperado: 0x00FFFFFF + 1 = 0x01000000
    ; Na SRAM (little-endian): 0x0100=00, 0x0101=00, 0x0102=00, 0x0103=01

    ; --- Volta o ponteiro X para o início de var_A ---
    ; (o setup deixou X em 0x0103, então é preciso recarregar)
    LDI  R26, LOW(var_A)    ; XL = 0x00
    LDI  R27, HIGH(var_A)   ; XH = 0x01 -> X = 0x0100

    ; --- Registradores auxiliares ---
    LDI  R18, 1             ; R18 = 1, valor a somar no byte menos significativo
    CLR  R19                ; R19 = 0, usado nos ADC só para propagar o carry

    ; --- Byte 0 (LSB) ---
    LD   R16, X             ; Lê A[0]
    ADD  R16, R18           ; R16 = A[0] + 1. Se passar de 255, vira 0 e Carry = 1
    ST   X+, R16            ; Salva A[0] e avança X (LD/ST não alteram o Carry)

    ; --- Byte 1 ---
    LD   R16, X             ; Lê A[1]
    ADC  R16, R19           ; R16 = A[1] + 0 + Carry. Propaga o "vai-um" do byte 0
    ST   X+, R16            ; Salva A[1] e avança X

    ; --- Byte 2 ---
    LD   R16, X             ; Lê A[2]
    ADC  R16, R19           ; R16 = A[2] + 0 + Carry. Propaga o "vai-um" do byte 1
    ST   X+, R16            ; Salva A[2] e avança X

    ; --- Byte 3 (MSB) ---
    LD   R16, X             ; Lê A[3]
    ADC  R16, R19           ; R16 = A[3] + 0 + Carry. Propaga o "vai-um" do byte 2
    ST   X, R16             ; Salva A[3]. Sem pós-incremento: é o último byte

fim:
    RJMP fim                ; Loop infinito para parar a execução

; =====================================================================
; ACOMPANHAMENTO NO SIMULADOR
;
;  Byte  | Antes | Conta          | Depois | Carry | X depois do ST
;  ------+-------+----------------+--------+-------+---------------
;  A[0]  |  FF   | FF + 1         |   00   |   1   | 0x0101
;  A[1]  |  FF   | FF + 0 + 1     |   00   |   1   | 0x0102
;  A[2]  |  FF   | FF + 0 + 1     |   00   |   1   | 0x0103
;  A[3]  |  00   | 00 + 0 + 1     |   01   |   0   | 0x0103 (não avança)
;
; Resultado na SRAM: 0x0100=00  0x0101=00  0x0102=00  0x0103=01
; ou seja, 0x01000000 em little-endian.
; =====================================================================