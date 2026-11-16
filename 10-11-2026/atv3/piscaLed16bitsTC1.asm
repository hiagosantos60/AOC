; t_estouro = ((MAX + 1) * Prescaler) / f_osc

; No TC0 (aula), usou-se Prescaler = 1024:
; t_estouro_TC0 = (256 * 1024) / 16.000.000 = 0,016384 s (16,384 ms)
; Por isso, foram necessárias 62 interrupções: 62 * 16,384 ms = 1015,81 ms (~1 s)

; estouro = (65.535 + 1)*256/16MHz = 65.536*256/16.000.000Hz = 1,048576 s
; por isso basta 1 interrupção para bater 1 segundo aproximadamente com
; um registrador de 16 bits 

.ORG 0x0000          ; Vetor reset
  rjmp setup

.ORG 0x001A          ; Vetor (endereco na Flash) do estouro do T/C1
  rjmp isr_tc1b

setup:
  sbi DDRB, PB5      ; PB5 como saida
  cbi PORTB, PB5     ; desliga LED

  ldi R16, 0b00000100 ; TC1 com prescaler de 256, a 16 MHz gera
  sts TCCR1B, R16     ; uma interrupcao a cada 1.048,58 ms (~1 s)
  ldi R16, 1
  sts TIMSK1, R16     ; habilita int. do TC1 (TIMSK1(0) = TOIE1 <- 1)

  sei                 ; habilita as interrupcoes globais

main:
  rjmp main

isr_tc1b:
  sbi PINB, PB5       ; inverte o estado do LED direto a cada estouro (~1 s)
  reti
