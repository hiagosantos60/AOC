.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
    
A : .BYTE 4 ; 32 BITS 
B: .BYTE 4
C: .BYTE 4
    
.CSEG
.ORG 0x0000

main:
    ; Inicializa a pilha (PARA USAR O RCALL / RET)
    ; Essa parte é boa prática, o microcontrolador sabe onde é
    LDI  R16, HIGH(RAMEND)
    OUT  SPH, R16
    LDI  R16, LOW(RAMEND)
    OUT  SPL, R16
 
    ; ---------------------------------------------------------------
    ; PASSO 1: init_32bits em A com 0x00020000 (little-endian: 00 00 02 00)
    ; ---------------------------------------------------------------
    LDI  XL, LOW(A)
    LDI  XH, HIGH(A)
    LDI  R16, 0x00
    LDI  R17, 0x00
    LDI  R18, 0x02
    LDI  R19, 0x00
    RCALL init_32bits
    ; Esperado: 0x0100 = 00 00 02 00      X = 0x0100
 
    ; ---------------------------------------------------------------
    ; PASSO 2: init_32bits em B com 0x00000001 (little-endian: 01 00 00 00)
    ; ---------------------------------------------------------------
    LDI  XL, LOW(B)
    LDI  XH, HIGH(B)
    LDI  R16, 0x01
    LDI  R17, 0x00
    LDI  R18, 0x00
    LDI  R19, 0x00
    RCALL init_32bits
    ; Esperado: 0x0104 = 01 00 00 00
    ; ATENÇÃO: a sub-rotina termina com X = A (0x0100), não B.
    ; O main recarrega o X antes de cada chamada, então não atrapalha.
 
    ; ---------------------------------------------------------------
    ; PASSO 3: enche C com 0xFFFFFFFF, para provar que o zera funciona
    ; ---------------------------------------------------------------
    LDI  XL, LOW(C)
    LDI  XH, HIGH(C)
    LDI  R16, 0xFF
    LDI  R17, 0xFF
    LDI  R18, 0xFF
    LDI  R19, 0xFF
    RCALL init_32bits
    ; Esperado: 0x0108 = FF FF FF FF
 
    ; ---------------------------------------------------------------
    ; PASSO 4: zera_32bits em C
    ; ---------------------------------------------------------------
    LDI  XL, LOW(C)
    LDI  XH, HIGH(C)
    RCALL zera_32bits
    ; Esperado: 0x0108 = 00 00 00 00
    ; Ponteiros: X = 0x010B (último byte de C), Y = 0x0104 (mexido pela sub-rotina)
 
    ; ---------------------------------------------------------------
    ; PASSO 5: sub_32bits  ->  C = A - B
    ; ---------------------------------------------------------------
    LDI  XL, LOW(A)
    LDI  XH, HIGH(A)
    LDI  YL, LOW(B)
    LDI  YH, HIGH(B)
    LDI  ZL, LOW(C)
    LDI  ZH, HIGH(C)
    RCALL sub_32bits
    ; Esperado: 0x0108 = FF FF 01 00  (0x0001FFFF)
    ; Ponteiros: X = 0x0100, Y = 0x0104, Z = 0x0108 (restaurados por LDI)
 
loop:
    RJMP loop               ; Loop infinito para parar a execução
    
;=========================================================================    
;  O PROGRAMADOR PRECISA INSTANCIAR OS VALORES QUE DESEJA NO MAIN
;  ANTES DE CHAMAR A SUB ROTINA 
;    LDI XL, LOW(A)
;    LDI XH, HIGH(A)
;    LDI R16, 0x4D
;    LDI R17, 0xC3
;    LDI R18, 0xB2
;    LDI R19, 0xA1
;=========================================================================
init_32bits:
    ; CARREGAR PARA X OS VALORES
    ST X+, R16
    ST X+, R17
    ST X+, R18
    ST X, R19
    
    ; RETORNA O PONTEIRO PARA A PRIMEIRA POSIÇÃO
    LDI XL, LOW(A)
    LDI XH, HIGH(A)
    RET

;=========================================================================
; O PROGRAMADOR DEVE CARREGAR O VALOR DA VARIÁVEL EM X ANTES DE
; USAR A SUB - ROTINA:     
;    LDI XL, LOW(A)
;    LDI XH, HIGH(A)
;=========================================================================
zera_32bits:
    ; CARREGA O VALOR ZERO NA VARIÁVEL INDICADA
    LDI R16, 0x0
    ST X+, R16
    ST X+, R16
    ST X+, R16
    ST X, R16
    
    ; VOLTA O VALOR PARA O INICIO DE Y
    LDI YL, LOW(B)
    LDI YH, HIGH(B)
    
    RET
    
;=========================================================================
; O PROGRAMADOR DEVE CARREGAR O VALOR DA VARIÁVEL EM X, Y e Z ANTES DE
; USAR A SUB - ROTINA PARA REALIZAR O DECREMENTO 
;    LDI XL, LOW(A)
;    LDI XH, HIGH(A)
;    
;    LDI YL, LOW(B)
;    LDI YH, HIGH(B)
;    
;    LDI ZL, LOW(C)
;    LDI ZH, HIGH(C)
;=========================================================================
sub_32bits:
    ; =========================================================
    ; BYTE 0 (Bits 0 a 7 - LOW)
    ; =========================================================
    LD  R16, X+   ; R16 = A[0]
    LD  R17, Y+   ; R17 = B[0]
    SUB R16, R17  ; SUBTRAI SEM CARRY (R16 = R16 - R17). PODE GERAR CARRY.
    ST  Z+, R16   ; SALVA C[0]

    ; =========================================================
    ; BYTE 1 (Bits 8 a 15)
    ; =========================================================
    LD  R16, X+   ; R16 = A[1]
    LD  R17, Y+   ; R17 = B[1]
    SBC R16, R17  ; SUBTRAI COM CARRY (R16 = R16 - R17 - C)
    ST  Z+, R16   ; SALVA C[1]

    ; =========================================================
    ; BYTE 2 (Bits 16 a 23)
    ; =========================================================
    LD  R16, X+   
    LD  R17, Y+   
    SBC R16, R17  
    ST  Z+, R16   

    ; =========================================================
    ; BYTE 3 (Bits 24 a 31 - HIGH)
    ; =========================================================
    LD  R16, X+   
    LD  R17, Y+   
    SBC R16, R17 
    ST  Z+, R16  
    
    LDI XL, LOW(A)
    LDI XH, HIGH(A)
    LDI YL, LOW(B)
    LDI YH, HIGH(B)
    LDI ZL, LOW(C)
    LDI ZH, HIGH(C)
    
    RET
   
