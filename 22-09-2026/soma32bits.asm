.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
A: .BYTE 4
B: .BYTE 4
C: .BYTE 4

.CSEG
.ORG 0x0000
    
; CARREGANDO VALORES DE 32 BITS PARA TESTE
; Carrega a variável A = 0x010203FF
    LDI R20, 0xFF      ; Byte 0 (Menos significativo)
    STS A, R20
    LDI R20, 0x03      ; Byte 1
    STS A+1, R20
    LDI R20, 0x02      ; Byte 2
    STS A+2, R20
    LDI R20, 0x01      ; Byte 3 (Mais significativo)
    STS A+3, R20

; Carrega a variável B = 0x04050602
    LDI R20, 0x02      ; Byte 0 (Menos significativo)
    STS B, R20
    LDI R20, 0x06      ; Byte 1
    STS B+1, R20
    LDI R20, 0x05      ; Byte 2
    STS B+2, R20
    LDI R20, 0x04      ; Byte 3 (Mais significativo)
    STS B+3, R20

modo_direto:  
    LDS R16, A
    LDS R17, B
    ADD R16, R17     ; Soma e gera carry
    STS C, R16

    LDS R16, A+1
    LDS R17, B+1
    ADC R16, R17     ; Soma com carry do byte anterior
    STS C+1, R16

    LDS R16, A+2
    LDS R17, B+2
    ADC R16, R17     ; Soma com carry do byte anterior
    STS C+2, R16

    LDS R16, A+3
    LDS R17, B+3
    ADC R16, R17     ; Soma com carry do byte anterior
    STS C+3, R16

modo_indireto_pos_incremento:
; ACESSO INDIRETO SEM INCREMENTAR, FAZENDO NA MÃO

    ; Configuracao os ponteiros X, Y e Z
    LDI XL, LOW(A)
    LDI XH, HIGH(A)
    LDI YL, LOW(B)
    LDI YH, HIGH(B)
    LDI ZL, LOW(C)
    LDI ZH, HIGH(C)

    LD R16, X        ; Carrega apontado por X
    LD R17, Y        ; Carrega apontado por Y
    ADD R16, R17
    ST Z, R16        ; Salva no apontado por Z

    ; avance os ponteiros
    ADIW X, 1
    ADIW Y, 1
    ADIW Z, 1

    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16

    ADIW X, 1
    ADIW Y, 1
    ADIW Z, 1

    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16

    ADIW X, 1
    ADIW Y, 1
    ADIW Z, 1

    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16
    
modo_indireto_pos_incremento:
    ; Configura os ponteiros X, Y e Z
    LDI XL, LOW(A)
    LDI XH, HIGH(A)
    LDI YL, LOW(B)
    LDI YH, HIGH(B)
    LDI ZL, LOW(C)
    LDI ZH, HIGH(C)

    LD R16, X+
    LD R17, Y+  
    ADD R16, R17
    ST Z+, R16

    LD R16, X+
    LD R17, Y+
    ADC R16, R17
    ST Z+, R16

    LD R16, X+
    LD R17, Y+
    ADC R16, R17
    ST Z+, R16

    LD R16, X+
    LD R17, Y+
    ADC R16, R17
    ST Z+, R16
    
modo_indireto_deslocamento:
    ; configura ponteiro Y
    LDI YL, LOW(A)
    LDI YH, HIGH(A)

    LDD R16, Y+0     
    LDD R17, Y+4
    ADD R16, R17
    STD Y+8, R16

    LDD R16, Y+1     
    LDD R17, Y+5     
    ADC R16, R17
    STD Y+9, R16     

    LDD R16, Y+2
    LDD R17, Y+6
    ADC R16, R17
    STD Y+10, R16

    LDD R16, Y+3   
    LDD R17, Y+7   
    ADC R16, R17
    STD Y+11, R16    
