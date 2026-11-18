; Vamos precisar usar o registrador OCR0A para comparar o registrador e fazer a contagem 
; OCR0A (Output Compare Register A)
; TCCR0A (Timer/Counter Control Register A)
; TCCR0B (Timer/Counter Control Register B)
; OCIE0A (Output Compare Interrupt Enable)

.ORG 0x0000          ; Vetor reset
  rjmp setup


.ORG 0x001C          ; Vetor (endereco na Flash) da Comparacao A do T/C0
  rjmp isr_tc0a      ; Pula para a rotina de tratamento da Comparação A

setup:
  sbi DDRB, PB5      ; PB5 como saida
  cbi PORTB, PB5     ; desliga LED

  ; Define o Limite (TOP) de contagem exata
  ldi R16, 249
  out OCR0A, R16     ; Grava 249 no comparador (gera interrupcao a cada 4 ms [250*256/16000000])

  ; Configura o Modo CTC (Clear Timer on Compare Match)
  ldi R16, 0b00000010 ; Ativa bit WGM01 | CTC (conta ate o OCR0A e zera)
  out TCCR0A, R16

  ; Configura o Prescaler para 256 e inicia o timer
  ldi R16, 0b00000100 ; Ativa bit CS02   
  out TCCR0B, R16

  ; Habilita a interrupcao local
  ldi R16, 0b00000010     
  sts TIMSK0, R16    ; TIMSK0(1) = OCIE0A <- 1 (Habilita apenas OCIE0A)

  ldi R16, 0         ; Zera o registrador para iniciar a contagem limpa no main
  sei                ; Habilita as interrupcoes globais


main:
  rjmp main


isr_tc0a:             ; O nome deve ser igual ao rjmp do vetor 0x001C
  inc r16
  cpi r16, 250        ; Conta 250 vezes | (1/0,004) = 250
  brne fim
  sbi PINB, PB5       ; inverte o estado do LED depois de entrar 250 vezes
                      ; na interrupcao: 250 * 4 ms = 1000 ms (1 segundo exato)
  ldi r16, 0          ; Zera o contador para o proximo segundo
fim:
  reti

; ========================================================
; Basicamente, o prescaler fica mandando clock que incrementa o TCNT0 a cada pulso ate
; chegar em 249 (o limite gravado no OCR0A), ai, quando chega nesse valor, o hardware 
; levanta a bandeira OCF0A que chama a interrupcao, zera o proprio TCNT0 automaticamente
; e a contagem comeca de novo (e tudo isso so aciona a CPU porque a chave OCIE0A estava ligada)
; ========================================================


; ========================================================
; RESUMO: POR QUE PRECISAMOS DO TCCR0A E DO TCCR0B?
; ========================================================
; Um erro comum e achar que o TCCR0A ou o TCCR0B fazem a 
; contagem do tempo. A letra "C" nas siglas significa 
; "Control" (Controle). Eles sao apenas o painel de 
; configuracao. 

; Quem realmente faz o trabalho duro de contar (0, 1, 2...) 
; e um terceiro registrador chamado TCNT0.
; Para nao esquecer mais, pense no Timer 0 como um carro:

; 1. TCNT0 (O hodometro): 
;    E a engrenagem que efetivamente gira e marca a contagem 
;    do tempo subindo passo a passo.

; 2. OCR0A (A linha de chegada): 
;    E o valor de referencia que voce grava para dizer 
;    "pare em 249".

; 3. TCCR0A (O GPS / A Regra do Jogo): 
;    E onde voce define o modo de operacao. Ativando o bit 
;    WGM01 nele, voce diz ao carro: "Siga a regra CTC. 
;    Quando o hodometro (TCNT0) marcar o valor exato da linha 
;    de chegada (OCR0A), zere o hodometro imediatamente".

; 4. TCCR0B (O Acelerador / Motor): 
;    E onde mora o Prescaler. Se voce configurar o TCCR0A 
;    mas esquecer o TCCR0B, os bits de clock ficarao em 000 
;    (sem fonte de clock). Ou seja, o seu carro sabe a regra 
;    (TCCR0A) e sabe onde tem que chegar (OCR0A), mas o motor 
;    esta desligado e a contagem nunca vai sair do zero. 
;    Voce grava no TCCR0B estritamente para ligar o prescaler 
;    e definir a marcha/velocidade da contagem.
; ========================================================