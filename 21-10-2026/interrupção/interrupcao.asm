;--------------------------------------------
; Simular um circuito com dois botões, ON (PD2) e OFF (PD3), e dois LEDs, L0 (PB0) e o L1 (PB1).
; Utilizando interrupção externa, implementar um sistema com o seguinte comportamento:
; Piscar o L0 a cada 2s;
; Quando o botão ON for pressionado, o L1 deve ligar;
; Quando o botão OFF for pressionado, o L1 deve desligar.
;
; DDRx (Data Direction Register):
;   0 = entrada
;   1 = saída
; 
; Os LEDs ligam com "0" e desligam com "1"
;--------------------------------------------
    
.INCLUDE <m328pdef.INC>
    
.equ BT_ON = PD2
.equ BT_OFF = PD3
.equ L_0 = PB0
.equ L_1 = PB1
.def AUX = R16
    
.ORG 0x0000	; reset vector
    rjmp setup
    
.ORG 0x0002	; vetor int0
    rjmp INT_0
    
.ORG 0x004	; vetor int1
    rjmp INT_1
    
.ORG 0x0034	; livre depois dos vetores
setup:
    ; Definindo entrada e saída
    cbi DDRD, BT_ON	; Define o pino como entrada (0)
    sbi PORTD, BT_ON    ; Ativa o pull-up
    
    cbi DDRD, BT_OFF	; Define o pino como entrada (0)
    sbi PORTD, BT_OFF   ; Ativa o pull-up
    
    ; Configuração dos Leds, desligados por padrão
    ldi AUX, 0b00000011	   ; 1 em PB0 e PB1 (leds desligados) 0 no restante.
    out DDRB, AUX	       ; Define a direção como saída (valor 1)
    out PORTB, AUX		   ; Define o valor (Leds desligados, valor 1)
    
    ; EICRA -> qualquer mudança irá causar interrupção: 01
    ldi AUX, 0b00000101
    sts EICRA, AUX
    sbi EIMSK, INT0
    sbi EIMSK, INT1
    
    sei ; ativar interrupção global

main:
    cbi PORTB, L_0   ; liga o led 0 (ativo em 0)
    
    ldi r19, 160    ; chamada do atraso 
    rcall delay
    
    sbi PORTB, L_0   ; Desliga o led 0 (desligado em 1)
    
    ldi r19, 160    ; chamada do atraso 
    rcall delay
    
    rjmp main
   
INT_0:	    ; Interrupção BT_ON
    ; Salvar contexto
    push AUX
    in AUX, sreg
    push AUX
    
    cbi PORTB, L_1   ; Ligar led 1
    
    ; Restaurar o contexto
    pop AUX
    out sreg, AUX
    pop AUX
    
    reti
    
INT_1:	    ; Interrupção BT_OFF
    ; Salvar contexto
    push AUX
    in AUX, sreg
    push AUX
    
    sbi PORTB, L_1   ; Desliga led 1

    ; Restaurar o contexto
    pop AUX
    out sreg, AUX
    pop AUX
    
    reti
    
;--------------------------------------------------------------
;SUB-ROTINA DE ATRASO Programável
; Depende do valor de R19 carregado antes da chamada.
; Ex.: - R19 = 16 --> 200ms
;      - R19 = 80 --> 1s
;--------------------------------------------------------------
delay:
  push r17	      ; Salva os valores de r17,
  push r18	      ; ... r18,
  in r17,SREG     ; ...
  push r17        ; ... e SREG na pilha.

  ; Executa sub-rotina :
  clr r17
  clr r18
loop:
  dec  R17        ;decrementa R17, começa com 0x00
  brne loop       ;enquanto R17 > 0 fica decrementando R17
  dec  R18        ;decrementa R18, começa com 0x00
  brne loop       ;enquanto R18 > 0 volta decrementar R18
  dec  R19        ;decrementa R19
  brne loop       ;enquanto R19 > 0 vai para volta

  pop r17
  out SREG, r17   ; Restaura os valores de SREG,
  pop r18         ; ... r18
  pop r17         ; ... r17 da pilha

  ret