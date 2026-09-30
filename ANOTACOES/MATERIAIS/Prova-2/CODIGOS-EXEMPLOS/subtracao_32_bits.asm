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
	
	
==========================================================================================
FAZER SEM LOOP, SOMENTE NA MÃO:

.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
num1:   .BYTE 4   ; 32 bits (Minuendo)
num2:   .BYTE 4   ; 32 bits (Subtraendo)
res:    .BYTE 4   ; 32 bits (Diferença)

.CSEG
.ORG 0x0000

main:
    ; Configurar ponteiros X (num1), Y (num2) e Z (res)
    LDI XL, LOW(num1)
    LDI XH, HIGH(num1)
    
    LDI YL, LOW(num2)
    LDI YH, HIGH(num2)
    
    LDI ZL, LOW(res)
    LDI ZH, HIGH(res)

    ; =========================================================
    ; BYTE 0 (Bits 0 a 7 - LOW)
    ; =========================================================
    LD  R16, X+   ; R16 = num1[0]
    LD  R17, Y+   ; R17 = num2[0]
    SUB R16, R17  ; Subtrai SEM Borrow (R16 = R16 - R17). Pode gerar Carry=1.
    ST  Z+, R16   ; Salva res[0]

    ; =========================================================
    ; BYTE 1 (Bits 8 a 15)
    ; =========================================================
    LD  R16, X+   ; R16 = num1[1]
    LD  R17, Y+   ; R17 = num2[1]
    SBC R16, R17  ; Subtrai COM Borrow (R16 = R16 - R17 - C)
    ST  Z+, R16   ; Salva res[1]

    ; =========================================================
    ; BYTE 2 (Bits 16 a 23)
    ; =========================================================
    LD  R16, X+   
    LD  R17, Y+   
    SBC R16, R17  ; Subtrai COM Borrow
    ST  Z+, R16   

    ; =========================================================
    ; BYTE 3 (Bits 24 a 31 - HIGH)
    ; =========================================================
    LD  R16, X+   
    LD  R17, Y+   
    SBC R16, R17  ; Subtrai COM Borrow final
    ST  Z+, R16   

fim:
    rjmp fim	