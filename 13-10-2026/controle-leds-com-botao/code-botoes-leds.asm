;----------------------------------------------------------
; LEDs (PD0..PD7):
;   pino = 0  ->  LED ACESO
;   pino = 1  ->  LED APAGADO
;
; Botões (PB1 = ajuste, PB2 = seleção), ligados ao GND:
;   pino = 1  ->  botão SOLTO       (pull-up puxa para 5V)
;   pino = 0  ->  botão PRESSIONADO (botão liga ao GND)
;
; REGISTRADORES (cada bit n controla o pino n da porta):
;   DDRx  = direção:  0 = ENTRADA, 1 = SAÍDA
;   PORTx = se saída:   0 = pino em 0V, 1 = pino em 5V
;           se entrada: 0 = pull-up desligado, 1 = pull-up ligado
;   PINx  = leitura: mostra o nível real do pino agora, 
;           usamos para ler os botões
;==========================================================
    
.INCLUDE <m328Pdef.inc>

.EQU AJUSTE  = PB1
.EQU SELECAO = PB2

setup:
    ldi  r16, 0xFF
    out  DDRD, r16        ; PORTD toda como saída (LEDs), valor 1, todos apagados no setup

    ; definindo os pinos que vamos usar para os botões, nesse caso 1 e 2 do PORTB
    cbi  DDRB, AJUSTE     ; DDRB bit 1 = 0  => PB1 é ENTRADA
    sbi  PORTB, AJUSTE    ; PORTB bit 1 = 1 => liga o pull-up de PB1
    
    cbi  DDRB, SELECAO    ; DDRB bit 2 = 0  => PB2 é ENTRADA
    sbi  PORTB, SELECAO   ; PORTB bit 2 = 1 => liga o pull-up de PB2
	
loop:
    ldi  r16, 0x00          ; acende todos os leds (valor 0 acende)

    sbis PINB, AJUSTE       ; pula se solto (1); executa se pressionado (0)
    ori  r16, 0x0F          ; apaga os 4 menos significativos (0000 1111)

    sbis PINB, SELECAO      ; pula se solto; executa se pressionado
    ori  r16, 0xF0          ; apaga os 4 mais significativos (1111 0000)

    out  PORTD, r16         ; atualiza os LEDs com o valor carregado 
    rjmp loop