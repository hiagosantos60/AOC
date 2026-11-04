;--------------------------------------------------------------
; EXEMPLO NO PADRAO DAS AULAS (AOC - PROF. ROBERTO DE MATOS)
;
; Circuito:
; - Botoes no PORTD com pull-up interno:
;     BT_INC em PD2 (INT0)
;     BT_RST em PD3 (INT1)
; - LEDs:
;     L_PISCA em PB0 (pisca continuamente no main a cada 1s)
;     PORTC (PC0..PC3): 4 LEDs mostrando um contador de 0 a 15
;
; Comportamento:
; 1) L_PISCA pisca a cada 1 segundo no loop principal.
; 2) Quando BT_INC for pressionado (borda de descida no INT0):
;    incrementa o contador ate o maximo de 15 e atualiza a PORTC.
; 3) Quando BT_RST for pressionado (borda de descida no INT1):
;    zera o contador e atualiza a PORTC.
;--------------------------------------------------------------

.INCLUDE <m328pdef.INC>

; --- DEFINICOES ---
.equ BT_INC  = PD2       ; INT0
.equ BT_RST  = PD3       ; INT1
.equ L_PISCA = PB0       ; LED que pisca no main

.def AUX     = r16       ; Registrador auxiliar

; --- SEGMENTO DE MEMORIA DE DADOS (SRAM) ---
.DSEG
contador: .byte 1

; --- SEGMENTO DE CODIGO (FLASH) ---
.CSEG
.ORG 0x0000              ; Vetor de Reset
    rjmp setup

.ORG 0x0002              ; Vetor INT0 (PD2)
    rjmp INT_0

.ORG 0x0004              ; Vetor INT1 (PD3)
    rjmp INT_1

.ORG 0x0034              ; Pula o espaco dos vetores de interrupcao
setup:
    ; 1. Botoes como ENTRADA com PULL-UP ativo (DDR=0, PORT=1)
    cbi DDRD, BT_INC     ; PD2 eh entrada
    sbi PORTD, BT_INC    ; Pull-up ativo em PD2

    cbi DDRD, BT_RST     ; PD3 eh entrada
    sbi PORTD, BT_RST    ; Pull-up ativo em PD3

    ; 2. Configura LEDs
    sbi DDRB, L_PISCA    ; PB0 eh saida
    sbi PORTB, L_PISCA   ; Comeca desligado (se ativo em 0)

    ldi AUX, 0b00001111  ; PC0..PC3 como saida
    out DDRC, AUX

    ; 3. Inicializa variavel contador com 0
    ldi AUX, 0
    sts contador, AUX
    out PORTC, AUX       ; Mostra 0 nos LEDs da PORTC

    ; 4. Configura EICRA
    ; ISC01=1, ISC00=0 -> INT0 na borda de descida (10)
    ; ISC11=1, ISC10=0 -> INT1 na borda de descida (10)
    ; Binario: 0b00001010
    ldi AUX, 0b00001010
    sts EICRA, AUX       ; Obrigatório usar sts!

    ; 5. Habilita INT0 e INT1 no EIMSK
    sbi EIMSK, INT0
    sbi EIMSK, INT1

    ; 6. Habilita interrupcao global
    sei

main:
    ; Pisca o LED L_PISCA a cada 1 segundo (r19 = 80)
    cbi PORTB, L_PISCA   ; Liga o LED (ativo em 0)
    ldi r19, 80
    rcall delay

    sbi PORTB, L_PISCA   ; Desliga o LED (desligado em 1)
    ldi r19, 80
    rcall delay

    rjmp main

;--------------------------------------------------------------
; INTERRUPCAO 0: BOTAO INCREMENTAR (PD2)
;--------------------------------------------------------------
INT_0:
    push AUX
    in AUX, SREG
    push AUX

    lds AUX, contador
    cpi AUX, 15          ; ja chegou em 15?
    breq FIM_INT0        ; sim: nao incrementa

    inc AUX
    sts contador, AUX
    out PORTC, AUX

FIM_INT0:                ; os dois caminhos passam por aqui
    pop AUX
    out SREG, AUX
    pop AUX
    reti

;--------------------------------------------------------------
; INTERRUPCAO 1: BOTAO RESET (PD3)
;--------------------------------------------------------------
INT_1:
    ; Salva o contexto
    push AUX
    in AUX, SREG
    push AUX

    ; Zera o contador
    ldi AUX, 0
    sts contador, AUX    ; Salva 0 na memoria SRAM
    out PORTC, AUX       ; Atualiza os LEDs da PORTC com 0

    ; Restaura o contexto
    pop AUX
    out SREG, AUX
    pop AUX

    reti



=========================================
Ideia de código para caso chegue no máximo e tenha que voltar para o inicio 
INT_0:
    push AUX
    in AUX, SREG
    push AUX

    lds AUX, contador
    cpi AUX, 15          ; chegou no maximo?
    breq ZERA_CONT       ; sim: vai zerar
    inc AUX              ; nao: incrementa
    rjmp SALVA_CONT      ; pula o trecho que zera

ZERA_CONT:
    ldi AUX, 0           ; volta ao zero

SALVA_CONT:
    sts contador, AUX    ; salva o valor (incrementado ou zero)
    out PORTC, AUX       ; atualiza os LEDs

    pop AUX
    out SREG, AUX
    pop AUX
    reti