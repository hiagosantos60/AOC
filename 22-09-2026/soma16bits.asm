VERIFICAR
; Faça um programa que some duas variáveis de 16 bits
; Agora é necessário verificar o carry

.INCLUDE <m328Pdef.inc>
.DSEG

; declaracao variáveis 16 bits
varA : .BYTE 2
varB : .BYTE 2
varC : .BYTE 2

.CSEG
.ORG 0x0000

start:  
    ; Faz a operacao de soma da variáveis com parte altas e partes baixas
    LDS R16, varA	    ;AL
    LDS R17, varB	    ;BL
    LDS R18, varA+1	    ;AH
    LDS R19, varB+1	    ;BH
    
    ADD R16, R17	    ; AL+BL
    ADC R18, R19	    ; AH+BH+C
    
    STS varC, R16
    STS varC+1, R18

    RJMP start
