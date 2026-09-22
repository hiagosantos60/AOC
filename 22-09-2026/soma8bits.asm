
; Faça um programa que some duas variáveis de 8 bits

.INCLUDE <m328Pdef.inc>
.DSEG

; declaracao variáveis 8 bits
varA : .BYTE 1
varB : .BYTE 1
varC : .BYTE 1

.CSEG
.ORG 0x0000

start:  
    ; Faz a operacao de soma da variáveis 
    LDS	r16, varA
    LDS	r17, varB
    ADD r16, r17 ; r16 <- r16 + r17
    STS varC, r16

loop_infinito:
    RJMP loop_infinito