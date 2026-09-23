.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
    
; variáveis
A: .BYTE 4
B: .BYTE 4
C: .BYTE 4
    
.CSEG
.ORG 0x0000
    
setup:
    ; Inicializa os valores na SRAM para teste
    ; A = 0x12345678
    LDI R26, LOW(A)
    LDI R27, HIGH(A)
    LDI R16, 0x78 ; LSB
    ST X+, R16
    LDI R16, 0x56
    ST X+, R16
    LDI R16, 0x34
    ST X+, R16
    LDI R16, 0x12 ; MSB
    ST X, R16
    
    ; B = 0x00112233
    LDI R26, LOW(B)
    LDI R27, HIGH(B)
    LDI R16, 0x33 ; LSB
    ST X+, R16
    LDI R16, 0x22
    ST X+, R16
    LDI R16, 0x11
    ST X+, R16
    LDI R16, 0x00 ; MSB
    ST X, R16
    
    ; O resultado esperado é 0x12233445

; subtracao de 32 bits: C = A-B com variável de 32 bits em little endian e pós incremento
subtracao_pos_incremento_manual:
    ; carregar valores para os ponteiros
    LDI R26, LOW(A)
    LDI R27, HIGH(A)
    
    LDI R28, LOW(B)
    LDI R29, HIGH(B)
    
    LDI R30, LOW(C)
    LDI R31, HIGH(C)
    
    ; operar a subtracao 
    LD R16, X+ ; coloca o valor de A[0] apontado e incrementa X
    LD R17, Y+ ; coloca o valor de B[0] apontado e incrementa Y
    SUB R16, R17 ; faz a operacao de subtracao com carry
    ST Z+, R16 ; armazena o valor em C[0]
    
    LD R16, X+ ; coloca o valor de A[0] apontado e incrementa X
    LD R17, Y+ ; coloca o valor de B[0] apontado e incrementa Y
    SBC R16, R17 ; faz a operacao de subtracao com carry
    ST Z+, R16 ; armazena o valor em C[0]
    
    LD R16, X+ ; coloca o valor de A[0] apontado e incrementa X
    LD R17, Y+ ; coloca o valor de B[0] apontado e incrementa Y
    SBC R16, R17 ; faz a operacao de subtracao com carry
    ST Z+, R16 ; armazena o valor em C[0]
    
    LD R16, X+ ; coloca o valor de A[0] apontado e incrementa X
    LD R17, Y+ ; coloca o valor de B[0] apontado e incrementa Y
    SBC R16, R17 ; faz a operacao de subtracao com carry
    ST Z+, R16 ; armazena o valor em C[0]
    
    
; Se fosse fazer com loop
subtracao_loop:
    ; Carrega valores para os ponteiros
    LDI R26, LOW(A)
    LDI R27, HIGH(A)
    
    LDI R28, LOW(B)
    LDI R29, HIGH(B)
    
    LDI R30, LOW(C)
    LDI R31, HIGH(C)
    
    ; Configura o loop
    LDI R18, 4     ; Contador de iterações (4 bytes = 32 bits)
    CLC            ; Limpa a flag de Carry (Carry = 0) para o primeiro byte

loop_subtracao_inicio:
    LD R16, X+     ; Carrega A[n] e incrementa X
    LD R17, Y+     ; Carrega B[n] e incrementa Y
    
    SBC R16, R17   ; R16 = A[n] - B[n] - Carry
    ST Z+, R16     ; Armazena C[n] e incrementa Z
    
    DEC R18        ; Decrementa o contador
    BRNE loop_subtracao_inicio ; Se o contador não for zero (Z=0), repete o loop
    
fim:
    rjmp fim                    