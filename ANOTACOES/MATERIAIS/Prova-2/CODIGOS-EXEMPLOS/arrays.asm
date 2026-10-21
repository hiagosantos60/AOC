.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100

A1: .BYTE 10      ; Vetor A1 com 10 posições
A2: .BYTE 10      ; Vetor A2 com 10 posições
A3: .BYTE 10      ; Vetor A3 com 10 posições
A4: .BYTE 3       ; Vetor A4 com 3 posições

.CSEG
.ORG 0x0000

reset:
    ; inicializando os ponteiro X e Y para apontar A1 e A2
    LDI XL, LOW(A1)
    LDI XH, HIGH(A1)
    LDI YL, LOW(A2)
    LDI YH, HIGH(A2)

    LDI R16, 1        ; R16 guardará o valor a ser inserido, começa em 1 
    LDI R17, 10       ; R17 será o contador do loop, 10 interacoes

loop_init:
    ; Inicializando os vetores com valores de 1 até 10
    ST X+, R16        ; Salva valor em A1 e pós-incrementa X
    ST Y+, R16        ; Salva valor em A2 e pós-incrementa Y
    INC R16           ; Incrementa o valor
    DEC R17           ; Decrementa o contador do loop
    BRNE loop_init    ; Volta ao loop_init se R17 não for zero

    ; Inicializando novamente o ponteiro X para o inicio de A1
    LDI XL, LOW(A1)
    LDI XH, HIGH(A1)

    ; Inicializando ponteiro Y para o final de A2
    LDI YL, LOW(A2 + 10)
    LDI YH, HIGH(A2 + 10)

    ; Z aponta para o início de A3
    LDI ZL, LOW(A3)
    LDI ZH, HIGH(A3)

    LDI R17, 10       ; Colocar novamente o 10 no contador para usar no próximo loop da soma 

loop_soma:
    ; somar A1 com A2 e aramzenar em A3
    LD R16, X+        ; Lê A1 e pós-incrementa X, de frente para tras
    LD R18, -Y        ; Pré-decrementa Y e depois lê A2, de trás para frente
    ADD R16, R18      ; Soma os valores
    ST Z+, R16        ; Salva o resultado em A3 e pós-incrementa Z
    DEC R17           ; decrementa e para quando for 0
    BRNE loop_soma    ; se R17 ainda não é zero

    ; Some [A2(1) e A3(3)], [A2(3) e A3(4)], [A2(5) e A3(7)] e salve consecutivamente no A4
    ; Inicializando os ponteiros: X para A4, Y para A2 e Z para A3
    ; Observação: somente ponteiros Y e Z aceitam LDD e STD, por isso a escolha deles para somar e de X para armazenar os valores em A4
    LDI YL, LOW(A2)
    LDI YH, HIGH(A2)
    LDI ZL, LOW(A3)
    LDI ZH, HIGH(A3)
    LDI XL, LOW(A4)
    LDI XH, HIGH(A4)

    ; Lembrando que os valores são de 1 a 10 nos dois vetores
    ; Operação 1: A4(0) = A2(1) + A3(3)
    LDD R16, Y+1      ; Lê A2(1) usando deslocamento (+1)
    LDD R18, Z+3      ; Lê A3(3) usando deslocamento (+3)
    ADD R16, R18
    ST X+, R16        ; Salva no primeiro espaço de A4 e pós-incrementa X

    ; Operação 2: A4(1) = A2(3) + A3(4)
    LDD R16, Y+3      ; Lê A2(3)
    LDD R18, Z+4      ; Lê A3(4)
    ADD R16, R18
    ST X+, R16        ; Salva no segundo espaço de A4 e pós-incrementa X

    ; Operação 3: A4(2) = A2(5) + A3(7)
    LDD R16, Y+5      ; Lê A2(5)
    LDD R18, Z+7      ; Lê A3(7)
    ADD R16, R18
    ST X+, R16        ; Salva no terceiro espaço de A4 e pós-incrementa X

fim:
    RJMP fim          ; Fim do programa