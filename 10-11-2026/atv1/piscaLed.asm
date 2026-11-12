.include "m328pdef.inc"

.equ LED         = PB5
.equ BOTAO       = PD2
.equ INT_INICIAL = 30           ; 30 * 16,384ms ~= 500ms (período de 1s)
.equ PASSO       = 6            ; 6 * 16,384ms ~= 100ms (reduz 200ms no período)

.dseg
.org SRAM_START
contagem:  .byte 1
intervalo: .byte 1

.cseg
.org 0x0000
    rjmp setup
.org 0x0002
    rjmp isr_int0
.org 0x0020
    rjmp isr_tc0b

setup:
    ; Configura LED (PB5 saída) e Botão (PD2 entrada com pull-up)
    sbi DDRB, LED
    cbi PORTB, LED
    cbi DDRD, BOTAO
    sbi PORTD, BOTAO

    ; Configura INT0 na borda de descida
    ldi R16, 0b00000010
    sts EICRA, R16
    sbi EIMSK, INT0

    ; Inicializa variáveis na SRAM
    ldi R16, 0
    sts contagem, R16
    ldi R16, INT_INICIAL
    sts intervalo, R16

    ; Configura Timer 0 com prescaler de 1024 (16,384 ms)
    ldi R16, 0b00000101
    out TCCR0B, R16
    ldi R16, 1                  ; TIMSK0(0) = TOIE0 <- 1
    sts TIMSK0, R16

    sei

main:
    rjmp main

isr_tc0b:
    push R16
    in R16, SREG
    push R16
    push R17

    lds R16, contagem			; incrementa a contagem
    inc R16
    sts contagem, R16

    lds R17, intervalo		
    cp R16, R17
    brlo fim_tc0b               ; se contagem < intervalo, sai

    sbi PINB, LED               ; inverte o LED
    ldi R16, 0
    sts contagem, R16           ; zera contagem

fim_tc0b:
    pop R17
    pop R16
    out SREG, R16
    pop R16
    reti

isr_int0:
    push R16
    in R16, SREG
    push R16

    lds R16, intervalo
    subi R16, PASSO             ; reduz 100ms no meio período (200ms no período)
    brne grava_int              ; se não chegou a 0, grava o novo estágio
    ldi R16, INT_INICIAL        ; após o 5º estágio (6 - 6 = 0), volta para 30 (1s)

grava_int:
    sts intervalo, R16
    ldi R16, 0
    sts contagem, R16           ; reinicia contagem para o novo período

    pop R16
    out SREG, R16
    pop R16
    reti