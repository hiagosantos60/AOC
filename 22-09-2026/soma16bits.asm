.INCLUDE <m328Pdef.inc>

.DSEG
varA: .BYTE 2
varB: .BYTE 2
varC: .BYTE 2

.CSEG
.ORG 0x0000

start:  
    ; Carrega 0x01FF na varA
    LDI R20, 0xFF
    STS varA, R20       ; Parte baixa
    LDI R20, 0x01
    STS varA+1, R20     ; Parte alta

    ; Carrega 0x0002 na varB
    LDI R20, 0x02
    STS varB, R20       ; Parte baixa
    LDI R20, 0x00
    STS varB+1, R20     ; Parte alta
    
    ; Lê as variáveis da memória
    LDS R16, varA       ; Parte baixa de A
    LDS R17, varB       ; Parte baixa de B
    LDS R18, varA+1     ; Parte alta de A
    LDS R19, varB+1     ; Parte alta de B
    
    ; Faz a soma de 16 bits
    ADD R16, R17        ; Soma as partes baixas (gera o carry)
    ADC R18, R19        ; Soma as partes altas + o carry
    
    ; Salva o resultado na memória
    STS varC, R16       ; Salva parte baixa
    STS varC+1, R18     ; Salva parte alta

    RJMP start