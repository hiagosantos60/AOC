.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
A : .BYTE 4 ; 4 bytes = 32 bits
B : .BYTE 4
C : .BYTE 4

; Little-Endian: Fica de trás pra frente. O byte menos significativo na frente
; Big-Endian: Fica como se lê. O byte mais significativo na frente

.CSEG
    ; A = 0x0001FFFF (little-endian: FF FF 01 00)
    ldi r16, 0xFF
    sts A,   r16
    sts A+1, r16
    ldi r16, 0x01
    sts A+2, r16
    ldi r16, 0x00
    sts A+3, r16

    ; B = 0x00000001 (little-endian: 01 00 00 00)
    ldi r16, 0x01
    sts B,   r16
    ldi r16, 0x00
    sts B+1, r16
    sts B+2, r16
    sts B+3, r16

main:
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

    LD R16, X
    LD R17, Y
    ADC R16, R17
    ST Z, R16

fim:
    rjmp fim


; =====================================================================
; EXPLICAÇÃO: COMO FUNCIONAM OS PONTEIROS X, Y E Z
; =====================================================================
;
; DOIS LUGARES DIFERENTES
;
;  REGISTRADORES (dentro da CPU)        SRAM (memória de dados)
;                                       endereço   conteúdo
;  XH (R27) = 01 \                 +--> 0x0100       FF  \
;  XL (R26) = 00 /  X = 0x0100 ----+    0x0101       FF   | A (4 bytes)
;                                       0x0102       01   |
;  YH (R29) = 01 \                      0x0103       00  /
;  YL (R28) = 04 /  Y = 0x0104 ------>  0x0104       01  \
;                                       0x0105       00   | B (4 bytes)
;  ZH (R31) = 01 \                      0x0106       00   |
;  ZL (R30) = 08 /  Z = 0x0108 --+      0x0107       00  /
;                                +--->  0x0108       00  \
;                                       0x0109       00   | C (4 bytes)
;                                       0x010A       02   |
;                                       0x010B       00  /
;
; - Esquerda: os ponteiros. São números guardados em registradores,
;   NÃO estão na SRAM e não ocupam espaço nas variáveis.
; - Direita: os dados. Os 12 bytes reservados por .BYTE.
; - O "01" do YH NÃO é um byte a mais de B. Ele faz parte do NÚMERO do
;   endereço (0x0104) e fica guardado no registrador, não na SRAM.
;
;
; LOW() e HIGH() separam o MESMO endereço (o de início da variável):
;
;   endereço de B = 0x0104
;                     | |
;          HIGH(B) ---+ +--- LOW(B)
;            0x01             0x04
;
; Nenhuma das duas fala do FIM da variável: o tamanho (.BYTE 4) não
; entra na conta. Quem anda pelos outros bytes é o pós-incremento (Y+).
;
; Toda a SRAM do ATmega328p está entre 0x0100 e 0x08FF, então o HIGH
; vai de 01 a 08. Aqui é sempre 01 porque as variáveis estão < 0x0200.
;
; ATENÇÃO À COINCIDÊNCIA
;
; O CONTEÚDO de B em 0x0104 é 01 (valor que colocamos em B) e o YH
; também vale 01. São dois "01" de origens diferentes: um é dado na
; SRAM, o outro é a metade alta do endereço 0x0104.
;
; PASSO A PASSO (X, Y e Z = valores ANTES de cada leitura)
;
;  Passo |  X   |  Y   |  Z   | A  | B  | soma                   | grava
;  ------+------+------+------+----+----+------------------------+----------
;    1   | 0100 | 0104 | 0108 | FF | 01 | FF+01   = 100 -> 00, C=1 | 0x0108=00
;    2   | 0101 | 0105 | 0109 | FF | 00 | FF+00+1 = 100 -> 00, C=1 | 0x0109=00
;    3   | 0102 | 0106 | 010A | 01 | 00 | 01+00+1 = 02,        C=0 | 0x010A=02
;    4   | 0103 | 0107 | 010B | 00 | 00 | 00+00+0 = 00             | 0x010B=00
;
; - ADD soma o primeiro byte; ADC soma os demais COM o carry anterior.
; - Nos passos 1 a 3 o "+" avança o ponteiro; no passo 4 não avança.
;   Por isso terminam em X=0x0103, Y=0x0107 e Z=0x010B.
;
; RESULTADO: C = 00 00 02 00 (little-endian) = 0x00020000
;            0x0001FFFF + 0x00000001 = 0x00020000
; =====================================================================