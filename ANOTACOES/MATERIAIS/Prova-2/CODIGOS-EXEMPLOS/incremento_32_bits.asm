.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
var_A: .BYTE 4 ; Aloca 4 bytes (32 bits) para a variável

.CSEG
.ORG 0x0000

incremento_32_bits:
    ; --- SETUP: var_A = 0x00FFFFFF (little-endian: FF FF FF 00) ---
    LDI  R26, LOW(var_A)
    LDI  R27, HIGH(var_A)
    LDI  R16, 0x01
    ST   X+, R16             ; A[0] = 0x01
    ST   X+, R16             ; A[1] = 0x01
    ST   X+, R16             ; A[2] = 0x01
    CLR  R16
    ST   X, R16              ; A[3] = 0x01

    ; resultado esperado 0x00010102 em little endian
    
    
    ; Configura o ponteiro X para o endereço da variável (little-endian)
    LDI R26, LOW(var_A)
    LDI R27, HIGH(var_A)
    
    ; Prepara os registradores de operação
    LDI R18, 1   ; Registrador com o valor 1 para o incremento inicial
    CLR R19      ; Registrador zerado (0x00) para propagar o Carry
    
    ; --- Byte 0 (LSB) ---
    LD R16, X      ; Lê A[0]
    ADD R16, R18   ; R16 = A[0] + 1. Se passar de 255 vai para 0, o Carry vai a 1.
    ST X+, R16     ; Salva A[0] modificado e avança o ponteiro X
    
    ; --- Byte 1 ---
    LD R16, X      ; Lê A[1]
    ADC R16, R19   ; R16 = A[1] + 0 + Carry. Propaga o "vai-um" se ocorreu no Byte 0.
    ST X+, R16     ; Salva A[1] e avança X
    
    ; --- Byte 2 ---
    LD R16, X      ; Lê A[2]
    ADC R16, R19   ; R16 = A[2] + 0 + Carry. Propaga o "vai-um" do Byte 1.
    ST X+, R16     ; Salva A[2] e avança X
    
    ; --- Byte 3 (MSB) ---
    LD R16, X      ; Lê A[3]
    ADC R16, R19   ; R16 = A[3] + 0 + Carry. Propaga o "vai-um" do Byte 2.
    ST X, R16      ; Salva A[3]. Não é necessário pós-incremento no último byte.

fim:
    RJMP fim 