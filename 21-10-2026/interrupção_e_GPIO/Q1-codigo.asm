; Cada vez que o botão INC/DEC for pressionado, incremente uma vez o valor mostrado na porta B e 
; decremente uma vez o valor na porta C. Os intervalos são de 0 até 15 para o incremento e de 
; 15 até 0 para o decremento.
; 
; Se o botão RST for pressionado, a contagem na porta B deve ser zerada e a porta C deve receber o valor 15.
; 
; DDRx (Data Direction Register):
;   0 = entrada
;   1 = saída
; 
; Os LEDs ligam com "0" e desligam com "1"
    
    
.INCLUDE <m328pdef.INC>
    
; DEFINIÇÕES:
.equ BT_I_D = PD3
.equ RST = PD2
.def AUX = r16
.def AUX2 = r20

.DSEG             ;  Início do segmento de memória de dados
count_b: .byte 1   
count_c: .byte 1   
   
.CSEG              ; Retorna ao segmento de código 
.ORG 0x0000	; reset vector
    rjmp setup

SETUP:
    ; Configurações dos botões
    cbi DDRD, BT_I_D	; Define o pino como entrada (0)
    sbi PORTD, BT_I_D	; Ativa o pull-uo
    
    cbi DDRD, RST	; Define o pino como entrada (0)
    sbi PORTD, RST	; Ativa o pull-uo
 
    ; Configuração de saída dos Leds, PORTB e PORTC
    ldi AUX, 0b00001111
    out DDRB, AUX   ; Direção como saída (1)
    out DDRC, AUX   ; Direção como saída (1)
    
SET_VALORES_PADRAO:    
    ; Inicializa as variáveis na memória SRAM
    LDI AUX, 0x00      ; Carrega 0 no registo
    STS count_b, AUX   ; Armazena o valor do registo na variável count_b
    LDI AUX, 0x0F      ; Carrega 15 no registo
    STS count_c, AUX   ; Armazena o valor do registo na variável count_c
    
SET_VALORES:
    lds AUX, count_b
    out PORTB, AUX
    lds AUX, count_c
    out PORTC, AUX
    
MAIN:	; Loop principal 
RST_PRESS:                      ; RST pressionado?
    sbis PIND, RST              ; solto (1)? pula o rjmp
    rjmp SET_VALORES_PADRAO     ; SIM: volta a setar os valores padrões

INC_DEC_PRESS:
    sbic PIND, BT_I_D       ; botão pressionado incremento? (0 = pressionado)
    rjmp MAIN

    lds AUX, count_b
    cpi AUX, 15             ; B == 15?
    breq ATUALIZA_VALOR	    ; Caso verdade

    lds AUX2, count_c
    cpi AUX2, 0             ; C == 0?
    breq ATUALIZA_VALOR	    ; Caso verdade

    inc AUX		    ; Incrementa B
    sts count_b, AUX	    ; Salva na variável
    dec AUX2		    ; Decrementa C
    sts count_c, AUX2	    ; Salva na variável 

ATUALIZA_VALOR:
    sbis PIND, BT_I_D	    ; Evita que o usuário incremente várias vezes apertando o botão
    rjmp ATUALIZA_VALOR
    ldi r19, 2		
    rcall delay		    ; chamada do delay
    rjmp SET_VALORES	    ; atualiza os valores dos PORTx

;--------------------------------------------------------------
;SUB-ROTINA DE ATRASO Programável
; Depende do valor de R19 carregado antes da chamada.
; Ex.: - R19 = 16 --> 200ms
;      - R19 = 80 --> 1s
;--------------------------------------------------------------
delay:
  push r17
  push r18
  in r17,SREG
  push r17

  clr r17
  clr r18
loop:
  dec  R17
  brne loop
  dec  R18
  brne loop
  dec  R19
  brne loop

  pop r17
  out SREG, r17
  pop r18
  pop r17

  ret