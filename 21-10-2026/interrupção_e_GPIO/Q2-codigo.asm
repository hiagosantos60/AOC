; Cada vez que o botão INC/DEC for pressionado, incremente uma vez o valor mostrado na porta B e decremente uma vez o valor na porta C. Os intervalos são de 0 até 15 para o incremento e de 15 até 0 para o decremento.
; Se o botão RST for pressionado, a contagem na porta B deve ser zerada e a porta C deve receber o valor 15.
; A porta B deve ser incrementada no momento em que o botão INC/DEC for pressionado e a porta C decrementada quando o botão for liberado. Os intervalos de incremento é de 0 até 15 e de decremento é de 15 até 0.
; Mantenha duas variáveis na memória count_b e count_c para armazenar o estado das portas.
	
.INCLUDE <m328pdef.INC>
    
; DEFINIÇÕES:
.equ BT_I_D = PD3
.equ RST = PD2
.def AUX = r16

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
    out PORTB, AUX
    ldi AUX, 0x0F      ; Carrega 15 no registo
    sts count_c, AUX   ; Armazena o valor do registo na variável count_c
    out PORTC, AUX
	
    sei		; habilita a interrupção global
	
MAIN:  ; Loop principal 
    rjmp MAIN	; fica aguardando interrupções
	

INTERRUPCAO_0:
    push AUX
    in AUX, SREG
    push AUX

	; incrementa/decrementa o valor
	lds AUX, count_b
	inc AUX
	sts count_b, AUX
	out PORTB, AUX
 	
 	lds AUX, count_c
	dec AUX
	sts count_c, AUX
	out PORTC, AUX

    ; PASSO 3: Restaurar contexto na ordem inversa
    pop AUX
    out SREG, AUX
    pop AUX
    
    reti
	
INTERRUPCAO_1:
    push AUX
    in AUX, SREG
    push AUX	
	
	ldi AUX, 0x00     	; coloca valores padrão novamente nas variáveis e no ports
        sts count_b, AUX   
        out PORTB, AUX
        ldi AUX, 0x0F      
        sts count_c, AUX
        out PORTC, AUX    

    pop AUX
    out SREG, AUX
    pop AUX
    
    reti


