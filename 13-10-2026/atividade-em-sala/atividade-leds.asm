;=============================================================================================================
; DESCRIÇÃO DO PROBLEMA
;=============================================================================================================
; Enquanto um botão estiver pressionado, um LED pisca a cada 2 s.
; Quando o botão NÃO estiver pressionado, o LED permanece ligado.
;
;   Botão: 1 - Pressionado; 0 - Não pressionado
;   LED  : 1 - ON;          0 - OFF
;
; Requisitos:
;   - Utilizar uma variável "count" na SRAM.
;   - Emular LEDs e botão com bits do GPIOR0 (definidos em m328Pdef.inc):
;         GPIOR02 (bit 2) -> LED 2   (não usado)
;         GPIOR03 (bit 3) -> Botão   (entrada: apenas lido pelo programa)
;         GPIOR07 (bit 7) -> LED 1   (saída)
;
;=============================================================================================================
; EXPLICAÇÃO
;=============================================================================================================
; - A pilha é inicializada com RAMEND, pois o programa usa RCALL, PUSH e POP.
; - A variável count (SRAM) é zerada no início.
; - No laço principal, o programa LÊ o bit do botão (GPIOR03) com SBIS:
;     * Botão solto (bit 3 = 0): salta para botao_solto, que liga o LED 1 (SBI)
;       e volta ao laço. O LED fica aceso fixo.
;     * Botão pressionado (bit 3 = 1): executa botao_pressionado.
; - Em botao_pressionado, o LED 1 é invertido: se estava ligado, desliga (CBI);
;   se estava desligado, liga (SBI).
; - Em seguida, count é incrementado na SRAM e é chamado o delay com R19 = 160
;   (~2 s, considerando R19 = 80 -> 1 s). Depois volta ao laço principal.
; - Resultado: com o botão pressionado, o LED 1 muda de estado a cada ~2 s.
; - O botão é alterado manualmente no simulador (I/O View), alterando o bit 3 do GPIOR0.
;
;=============================================================================================================
; IMPLEMENTAÇÃO
;=============================================================================================================

.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100

    count: .BYTE 1

.CSEG
.ORG 0x0000

    clr  r16
    sts  count, r16

loop_principal:
    sbis GPIOR0, GPIOR03      ; botão pressionado? se sim, pula a próxima
    rjmp botao_solto

botao_pressionado:
    ; pisca: alterna LED1 a cada 2 s
    sbis GPIOR0, GPIOR07      ; se LED1 = 1, pula
    rjmp liga_led
    cbi  GPIOR0, GPIOR07      ; LED1 OFF
    rjmp espera
liga_led:
    sbi  GPIOR0, GPIOR07      ; LED1 ON
espera:
    lds  r16, count           ; count++
    inc  r16
    sts  count, r16

    ldi  r19, 160             ; ~2 s 
    rcall delay
    rjmp loop_principal

botao_solto:
    sbi  GPIOR0, GPIOR07      ; LED ligado fixo
    rjmp loop_principal

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
