# GUIA COMPLETO DE ESTUDO: GPIO, INTERRUPCOES E INSTRUCOES AVR
Materia: Arquitetura e Organizacao de Computadores (AOC) - IFSC SJ
Microcontrolador: ATmega328P

---

## 1. GPIO: OS 3 REGISTRADORES FUNDAMENTAIS

Para cada porta fisica (B, C e D), o chip possui 3 registradores de 8 bits associados:

### A) DDRx (Data Direction Register)
Define o sentido do pino (se eh Entrada ou Saida).
- Bit = 0: Pino eh configurado como ENTRADA (Input).
- Bit = 1: Pino eh configurado como SAIDA (Output).

Exemplo:
```asm
sbi DDRB, PB0    ; PB0 configurado como SAIDA
cbi DDRD, PD2    ; PD2 configurado como ENTRADA
```

---

### B) PORTx (Port Output Data Register)
Tem funcao dupla dependendo da configuracao no DDRx:

1. Se o pino for SAIDA (DDR = 1):
   - Bit = 0: Coloca 0V (GND) no pino fisico.
   - Bit = 1: Coloca 5V (VCC) no pino fisico.

2. Se o pino for ENTRADA (DDR = 0):
   - Bit = 0: Resistor Pull-up interno DESLIGADO (alta impedancia).
   - Bit = 1: Resistor Pull-up interno LIGADO (puxa para 5V).

---

### C) PINx (Input Pins Address)
Registrador apenas de LEITURA.
- Bit = 0: O pino fisico esta em 0V.
- Bit = 1: O pino fisico esta em 5V.
- Regra de prova: Para ler botoes, teste sempre o registrador `PINx`, nunca `PORTx`!

---

## 2. BOTAO COM RESISTOR DE PULL-UP INTERNO

Um pino de entrada nunca deve ficar flutuando no ar para nao captar ruido. O resistor interno de pull-up conecta o pino internamente aos 5V.

### Como o circuito funciona:
- Pino conectado ao resistor interno (puxado para 5V).
- O botao conecta o pino ao GND (terra).

### Logica do Botao:
- Botao SOLTO (Aberto): o resistor mantem a linha em 5V -> leitura no PINx eh 1.
- Botao PRESSIONADO (Fechado): o botao joga a linha direto para o GND -> leitura no PINx eh 0.

### Como configurar no SETUP:
```asm
cbi DDRD, PD2    ; 1) DDR = 0 -> Define PD2 como Entrada
sbi PORTD, PD2   ; 2) PORT = 1 com DDR=0 -> LIGA o resistor Pull-up
```

---

## 3. INTERRUPCOES EXTERNAS (INT0 e INT1)

A interrupcao pausa o programa principal no momento exato em que o botao eh acionado.

### Pinos Fisicos Fixos:
- INT0: pino obrigatorio PD2.
- INT1: pino obrigatorio PD3.

---

### Registrador EICRA (Sensibilidade do Disparo)
Define qual evento eletrico vai disparar a interrupcao:
- Bits 1 e 0 (ISC01, ISC00): configuram o INT0 (PD2).
- Bits 3 e 2 (ISC11, ISC10): configuram o INT1 (PD3).
- Bits 7 a 4: reservados (sempre 0).

Tabela de Modos:
- `00`: Nivel baixo continuo (Low Level).
- `01`: Qualquer mudanca logica (dispara ao apertar e ao soltar).
- `10`: Borda de descida (Falling Edge) -> dispara no instante em que o botao eh PRESSIONADO (vai de 5V para 0V). Modo padrao com pull-up!
- `11`: Borda de subida (Rising Edge) -> dispara quando o botao eh SOLTO (vai de 0V para 5V).

ATENCAO: O registrador EICRA fica no endereco estendido 0x69.
- NUNCA use `out EICRA, r16`.
- SEMPRE use `sts EICRA, r16`.

---

### Registrador EIMSK (Mascara de Habilitacao)
Habilita individualmente cada interrupcao:
- Bit 0: INT0 (habilita o pino PD2).
- Bit 1: INT1 (habilita o pino PD3).

Exemplo:
```asm
sbi EIMSK, INT0   ; Habilita interrupcao no PD2
sbi EIMSK, INT1   ; Habilita interrupcao no PD3
```

---

### Chave Geral de Interrupcao:
- `sei`: Set Global Interrupt Flag (liga a chave geral no chip).
- `cli`: Clear Global Interrupt Flag (desliga a chave geral).

---

## 4. DICIONARIO COMPLETO DE INSTRUCOES AVR PARA A PROVA

Aqui estao descritas todas as instrucoes utilizadas nas aulas e avaliacoes, separadas por categoria:

### A) Instrucoes de E/S e Manipulacao de Bits (GPIO)

1. `sbi A, b` (Set Bit in I/O):
   - O que faz: Escreve o bit `1` na posicao `b` do registrador de I/O `A`.
   - Vantagem: Nao altera nenhum dos outros 7 pinos da porta.
   - Limitacao: Funciona apenas nos registradores de I/O de 0 a 31 (0x00 a 0x1F).
   - Exemplo: `sbi DDRB, PB0` (define PB0 como saida).

2. `cbi A, b` (Clear Bit in I/O):
   - O que faz: Escreve o bit `0` na posicao `b` do registrador de I/O `A`.
   - Exemplo: `cbi DDRD, PD2` (define PD2 como entrada).

3. `sbic A, b` (Skip if Bit in I/O is Clear):
   - O que faz: Testa o bit `b` no registrador `A`. Se o bit for `0`, pula a instrucao seguinte.
   - Uso com botao: Como o botao com pull-up vai para 0 quando apertado, `sbic` pula se o botao estiver PRESSIONADO.
   - Exemplo:
     ```asm
     sbic PIND, PD2    ; Botao pressionado (0)? Se sim, pula o rjmp
     rjmp MAIN         ; Botao solto (1): volta para o loop
     ```

4. `sbis A, b` (Skip if Bit in I/O is Set):
   - O que faz: Testa o bit `b` no registrador `A`. Se o bit for `1`, pula a instrucao seguinte.
   - Uso com botao: Pula se o botao estiver SOLTO (1).
   - Exemplo:
     ```asm
     sbis PIND, PD2    ; Botao solto (1)? Se sim, pula
     rjmp BOTAO_PRESS  ; Executa se o botao estiver pressionado (0)
     ```

5. `in Rd, A` (In from I/O Location):
   - O que faz: Le todos os 8 bits do registrador de I/O `A` e copia para o registrador de uso geral `Rd`.
   - Exemplo: `in r16, PIND` (le o estado dos 8 pinos da porta D de uma vez so).

6. `out A, Rr` (Out to I/O Location):
   - O que faz: Grava o valor do registrador `Rr` diretamente no registrador de I/O `A`.
   - Exemplo: `out DDRB, r16` (configura a direcao dos 8 pinos da porta B de uma vez).

---

### B) Instrucoes de Movimentacao de Dados e Memoria

1. `ldi Rd, K` (Load Immediate):
   - O que faz: Carrega um valor constante/literal `K` (de 0 a 255) diretamente no registrador `Rd`.
   - REGRA DE OURO: So funciona nos registradores superiores: de **R16 a R31** (nao funciona em R0 a R15).
   - Exemplo: `ldi r16, 0b00001010` ou `ldi r16, 15`.

2. `clr Rd` (Clear Register):
   - O que faz: Zera o registrador `Rd` (coloca o valor 0).
   - Exemplo: `clr r16`.

3. `mov Rd, Rr` (Copy Register):
   - O que faz: Copia o conteudo do registrador `Rr` para o registrador `Rd`.
   - Exemplo: `mov r17, r16`.

4. `lds Rd, k` (Load Direct from SRAM):
   - O que faz: Le o byte armazenado no endereco de memoria RAM `k` (ou nome de variavel) e guarda em `Rd`.
   - Exemplo: `lds r16, contador`.

5. `sts k, Rr` (Store Direct to SRAM / Extended I/O):
   - O que faz: Grava o valor de `Rr` no endereco de memoria `k` (variavel na SRAM) ou em registradores estendidos como `EICRA`.
   - Exemplo 1 (salvar variavel): `sts contador, r16`
   - Exemplo 2 (configurar interrupcao): `sts EICRA, r16`

6. `push Rr` (Push on Stack):
   - O que faz: Guarda o conteudo do registrador `Rr` no topo da pilha (Stack). Usado para salvar o contexto.
   - Exemplo: `push r16`.

7. `pop Rd` (Pop from Stack):
   - O que faz: Retira o valor do topo da pilha e devolve para o registrador `Rd`.
   - Exemplo: `pop r16`.

---

### C) Instrucoes Aritmeticas e de Comparacao

1. `inc Rd` (Increment):
   - O que faz: Soma 1 ao valor contido em `Rd` (`Rd = Rd + 1`).
   - Exemplo: `inc r16`.

2. `dec Rd` (Decrement):
   - O que faz: Subtrai 1 do valor contido em `Rd` (`Rd = Rd - 1`).
   - Exemplo: `dec r16`.

3. `cpi Rd, K` (Compare with Immediate):
   - O que faz: Compara o registrador `Rd` com a constante `K` (fazendo uma subtracao interna `Rd - K` sem alterar o valor de `Rd`, apenas atualizando as flags no SREG).
   - REGRA DE OURO: So funciona com registradores de **R16 a R31**.
   - Exemplo:
     ```asm
     cpi r16, 15       ; Compara se r16 eh igual a 15
     breq FIM          ; Se for igual (Zero flag = 1), pula para FIM
     ```

---

### D) Instrucoes de Desvio e Controle de Fluxo

1. `rjmp k` (Relative Jump):
   - O que faz: Salta incondicionalmente para o rotulo `k`.
   - Exemplo: `rjmp main`.

2. `rcall k` (Relative Call to Subroutine):
   - O que faz: Chama a sub-rotina no rotulo `k`. Salva automaticamente o endereco de retorno (PC) na pilha.
   - Exemplo: `rcall delay`.

3. `ret` (Return from Subroutine):
   - O que faz: Retorna de uma sub-rotina chamada por `rcall`. Retira o endereco de retorno da pilha.
   - ATENCAO: Use apenas em sub-rotinas normais (nunca em interrupcoes!).

4. `reti` (Return from Interrupt):
   - O que faz: Retorna de uma rotina de interrupcao (ISR). Alem de retirar o endereco de retorno da pilha, ele **reabilita automaticamente a flag global de interrupcao (I) no SREG**.
   - REGRA DE OURO: Toda rotina de interrupcao DEVE terminar com `reti`.

5. `breq k` (Branch if Equal):
   - O que faz: Salta para o rotulo `k` se o teste anterior deu igual (se a flag Z = 1).
   - Exemplo: `breq ATINGIU_LIMITE`.

6. `brne k` (Branch if Not Equal):
   - O que faz: Salta para o rotulo `k` se o teste anterior deu diferente (se a flag Z = 0). Muito usado em lacos de atraso:
   - Exemplo:
     ```asm
     dec  r17
     brne loop_delay   ; enquanto r17 nao for zero, volta a decrementar
     ```

---

### E) Instrucoes de Interrupcao Global

1. `sei` (Set Global Interrupt Flag):
   - O que faz: Seta o bit I no registrador de status `SREG`, permitindo que o microcontrolador receba interrupcoes.
   - Onde colocar: No final da rotina de `setup`.

2. `cli` (Clear Global Interrupt Flag):
   - O que faz: Zera o bit I no `SREG`, bloqueando temporariamente todas as interrupcoes.

---

## 5. ESTRUTURA COMPLETA DE UM CODIGO PARA A PROVA

```asm
.INCLUDE <m328pdef.INC>

; --- DEFINICOES ---
.equ BOTAO = PD2        ; Pino de interrupcao INT0
.equ LED   = PB0        ; Pino de saida do LED
.def AUX   = r16        ; Registrador auxiliar

; --- MEMORIA DE DADOS NA SRAM ---
.DSEG
.ORG 0x0100
contador: .byte 1       ; Reserva 1 byte na SRAM para a variavel

; --- VETORES DE INTERRUPCAO NA FLASH ---
.CSEG
.ORG 0x0000             ; Vetor de RESET (quando liga o chip)
    rjmp setup

.ORG 0x0002             ; Vetor da interrupcao INT0 (pino PD2)
    rjmp TRATA_INT0

.ORG 0x0034             ; Pula a area reservada dos vetores
setup:
    ; 1. Configura Botao: Entrada com Pull-up (DDR=0, PORT=1)
    cbi DDRD, BOTAO
    sbi PORTD, BOTAO

    ; 2. Configura LED: Saida
    sbi DDRB, LED
    sbi PORTB, LED      ; Comeca apagado (se ativo em 0)

    ; 3. Configura EICRA (Borda de descida para INT0: 10)
    ldi AUX, 0b00000010
    sts EICRA, AUX      ; ATENCAO: usar sts

    ; 4. Habilita INT0 no EIMSK
    sbi EIMSK, INT0

    ; 5. Inicializa variavel na SRAM
    clr AUX
    sts contador, AUX

    ; 6. Habilita interrupcoes globais
    sei

main:
    ; O programa principal fica rodando aqui
    rjmp main

; --- ROTINA DE ATENDIMENTO DA INTERRUPCAO (ISR) ---
TRATA_INT0:
    ; PASSO 1: Salvar contexto (AUX e SREG)
    push AUX
    in AUX, SREG
    push AUX

    ; PASSO 2: Acao da interrupcao
    lds AUX, contador
    inc AUX
    sts contador, AUX

    ; PASSO 3: Restaurar contexto na ordem inversa
    pop AUX
    out SREG, AUX
    pop AUX

    ; PASSO 4: Retorno obrigatorio com RETI
    reti
```

---

## 6. SUB-ROTINA DE ATRASO PADRAO DA DISCIPLINA

Sub-rotina programavel por `r19`:
- `r19 = 16` -> ~200 milissegundos
- `r19 = 80` -> ~1 segundo
- `r19 = 160` -> ~2 segundos

```asm
delay:
    push r17
    push r18
    in r17, SREG
    push r17

    clr r17
    clr r18
loop_delay:
    dec r17
    brne loop_delay
    dec r18
    brne loop_delay
    dec r19
    brne loop_delay

    pop r17
    out SREG, r17
    pop r18
    pop r17
    ret
```

---

## 7. CHECKLIST FINAL PARA REVISAR ANTES DE ENTREGAR A PROVA

1. [ ] Usou `cbi DDR` e `sbi PORT` para ligar o pull-up nos botoes?
2. [ ] Usou **`sts EICRA, AUX`** e nunca `out`?
3. [ ] Configurou o vetor de reset em `.ORG 0x0000` e INT0 em `.ORG 0x0002`?
4. [ ] Pulou o espaco dos vetores com `.ORG 0x0034` antes do `setup`?
5. [ ] Lembrou da instrucao **`sei`** no final do `setup`?
6. [ ] Na rotina de interrupcao, salvou e restaurou o **`SREG`**?
7. [ ] A interrupcao termina com **`reti`** (e nao com `ret`)?
8. [ ] As instrucoes `ldi` e `cpi` foram usadas apenas com registradores de **R16 a R31**?
