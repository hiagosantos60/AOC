; Cada vez que o botão INC/DEC for pressionado, incremente uma vez o valor mostrado na porta B e decremente uma vez o valor na porta C. Os intervalos são de 0 até 15 para o incremento e de 15 até 0 para o decremento.
; Se o botão RST for pressionado, a contagem na porta B deve ser zerada e a porta C deve receber o valor 15.
; A porta B deve ser incrementada no momento em que o botão INC/DEC for pressionado e a porta C decrementada quando o botão for liberado. Os intervalos de incremento é de 0 até 15 e de decremento é de 15 até 0.
; Mantenha duas variáveis na memória count_b e count_c para armazenar o estado das portas.
	
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

.ORG 0x0002	; vetor int0 (PD2 = RST)
    rjmp INTERRUPCAO_1

.ORG 0x004	; vetor int1 (PD3 = INC/DEC)
    rjmp INTERRUPCAO_0

SETUP: ; Configuração incial 
	cbi DDRD, BT_I_D 	; Definir o pino como entrada (Valor: 0)
	sbi PORTD, BT_I_D	; Ativar o Pull-UP
	    
	cbi DDRD, RST	; Define o pino como entrada (0)
    sbi PORTD, RST	; Ativa o pull-uo
    
    ; Configuração de saída dos Leds, PORTB e PORTC
    ldi AUX, 0b00001111
    out DDRB, AUX   ; Direção como saída (1)
    out DDRC, AUX   ; Direção como saída (1)
	
	; EICRA -> INT0 (RST): borda de descida (10) | INT1 (INC/DEC): qualquer mudança (01)
    ldi AUX, 0b00000110	
    sts EICRA, AUX
    sbi EIMSK, INT0   ; Habilita leitura nos dois
    sbi EIMSK, INT1
	
	; Colocando os valores padrão no setup 
	ldi AUX, 0x00      ; Carrega 0 no registo
    sts count_b, AUX   ; Armazena o valor do registo na variável count_b
    ldi AUX, 0x0F      ; Carrega 15 no registo
    sts count_c, AUX   ; Armazena o valor do registo na variável count_c
	
	rcall ATUALIZA_VALORES	; mostra o estado inicial nos LEDs
	
	sei		; habilita a interrupção global
	
MAIN:  ; Loop principal 
    rjmp MAIN	; fica aguardando interrupções
	
	
; ================================================================================
; INTERRUPÇÃO CASO INC/DEC PRESSIONADO
INTERRUPCAO_0:
	push AUX		; salvar o contexto 
	in AUX, SREG
	PUSH AUX
	push AUX2
	
	rcall VALIDAR_VALORES 	; chama função para validar função e continuar no loop 
	
	pop AUX2
	pop AUX			; recuperar contexto
	out SREG, AUX
	pop AUX
	reti

; só atualiza os valores que foram validados 
ATUALIZA_VALORES:
    lds AUX, count_b
    out PORTB, AUX
	
    lds AUX, count_c
    out PORTC, AUX
	ret
	
; lê o botão: pressionado (0) incrementa B | solto (1) decrementa C, cada um com seu limite
VALIDAR_VALORES:
	sbic PIND, BT_I_D	;pino em 0 (pressionado) pula o rjmp
	rjmp BOTAO_SOLTO
	
	lds AUX, count_b
	cpi AUX, 0x0F	; compara se é igual a 15
	breq RETORNA
	inc AUX			
	sts count_b, AUX
	rjmp CHAMADA		

BOTAO_SOLTO:				
	lds AUX2, count_c	
	cpi AUX2, 0x00	; compara se é igual a 0  (<< agora com AUX2)
	breq RETORNA
	dec AUX2		
	sts count_c, AUX2

CHAMADA:				
	rcall ATUALIZA_VALORES	; só vai cair aqui se passar nos testes

RETORNA:
	ret
; ================================================================================


; ================================================================================
; INTERRUÇÃO 1 CASO RESET PRESSIONADO 
SET_VALORES_PADRAO:    ; usado pelo RESET
	push AUX		; salvar o contexto 
	in AUX, SREG
	PUSH AUX
	
    ; Inicializa as variáveis na memória SRAM
    ldi AUX, 0x00      ; Carrega 0 no registo
    sts count_b, AUX   ; Armazena o valor do registo na variável count_b
    ldi AUX, 0x0F      ; Carrega 15 no registo
    sts count_c, AUX   ; Armazena o valor do registo na variável count_c
	
	rcall ATUALIZA_VALORES
	
	pop AUX			; recuperar contexto
	out SREG, AUX
	pop AUX

	reti

INTERRUPCAO_1:	; Caso RST pressionado 
    rjmp SET_VALORES_PADRAO     ; volta a setar os valores padrões
; ================================================================================