# Registradores do AVR e Lógica de Montagem (ATmega328P)

Guia de referência para programação em Assembly AVR, organizado a partir da arquitetura do
core até as instruções e diretivas do montador.

---

## 1. A arquitetura em uma frase

O AVR é um **RISC de 8 bits, Harvard, tipo Load-Store**.

Cada um desses três termos define uma regra  de programação:

| Termo | O que significa | Consequência no código |
|---|---|---|
| **RISC** | Instruções simples, tamanho fixo (16 bits, algumas de 32) | Quase tudo executa em 1 ciclo de clock |
| **Harvard** | Barramentos separados para programa (Flash) e dados (SRAM) | Constantes na Flash exigem `lpm`, não `ld` |
| **Load-Store** | A ULA **só opera sobre registradores** | Para somar um valor da RAM, primeiro carregue (`lds`/`ld`), some, depois grave (`sts`/`st`) |

A regra do Load-Store é a mais importante de todas. Não existe algo como
`add [0x0100], r16`. O caminho é sempre:

```
memória  --(load)-->  registrador  --(ULA)-->  registrador  --(store)-->  memória
```

### O core

```
                     Data Bus 8-bit
   ┌──────────┐    ┌──────────────┐   ┌──────────────┐
   │  Flash   │──▶│ Instruction  │   │   Status     │
   │ (código) │    │  Register    │   │ and Control  │
   └──────────┘    └──────┬───────┘   └──────────────┘
        ▲                 │
   ┌────┴─────┐    ┌──────▼───────┐    ┌──────────────┐
   │ Program  │    │ Instruction  │    │   32 x 8     │
   │ Counter  │    │   Decoder    │──▶│  Registers   │◀──▶ periféricos
   └──────────┘    └──────────────┘    └──────┬───────┘
                                              │
                                           ┌──▼──┐
                                           │ ULA │
                                           └──┬──┘
                                              ▼
                                          Data SRAM
```

Os 32 registradores ficam **conectados diretamente à ULA**, com dois operandos lidos e um
resultado escrito no mesmo ciclo. É por isso que operar em registrador custa 1 ciclo e
acessar a SRAM custa 2.

---

## 2. Mapa de memória do ATmega328P

São **três espaços de endereçamento independentes**:

### Memória de programa (Flash) — 32 KB, organizada em 16K palavras de 16 bits

```
0x0000  ┌──────────────────────────┐
        │  Application Flash       │   ← seu código + constantes (.DB)
        │                          │
        ├──────────────────────────┤
        │  Boot Flash (256–2048 w) │   ← bootloader (Arduino usa esta área)
0x3FFF  └──────────────────────────┘
```

Endereçada em **palavras**, não em bytes. É por isso que o `PC` (Program Counter) do
ATmega328P tem 14 bits, e `rjmp`/`rcall` saltam em palavras.

### Memória de dados (Data Space) — 8 bits de largura

```
0x0000  ┌──────────────────────────┐
        │ 32 Registradores (R0–R31)│ 
0x001F  ├──────────────────────────┤
0x0020  │  64 Registradores de I/O │  ← acessíveis por in/out (0x00–0x3F)
0x005F  ├──────────────────────────┤
0x0060  │  160 I/O Estendidos      │  ← só por lds/sts (UCSRnA, ADC, etc.)
0x00FF  ├──────────────────────────┤
0x0100  │  SRAM interna (2 KB)     │  ← variáveis + pilha
0x08FF  └──────────────────────────┘   RAMEND
```

Detalhe importante: **os registradores são espelhados na RAM**. `lds r0, 0x0010` lê o
conteúdo de R16. 

### EEPROM — 1 KB (0x000–0x3FF)

Espaço **totalmente separado**, acessado apenas por registradores (`EEARH:EEARL`,
`EEDR`, `EECR`). Não é endereçável por `ld`/`lds`.

---

## 3. Os 32 registradores de uso geral

```
        7            0   Addr.
      ┌────────────────┐
  R0  │                │  0x00   ← destino implícito de LPM / MUL (R1:R0)
  R1  │                │  0x01   ← parte alta de MUL / "zero reg" no C do GCC
  R2  │                │  0x02
      │      ...       │
 R13  │                │  0x0D
 R14  │                │  0x0E
 R15  │                │  0x0F   ── fim da "metade baixa"
 R16  │                │  0x10   ── início da "metade alta"
 R17  │                │  0x11
      │      ...       │
 R26  │                │  0x1A   X-register Low Byte  (XL)
 R27  │                │  0x1B   X-register High Byte (XH)
 R28  │                │  0x1C   Y-register Low Byte  (YL)
 R29  │                │  0x1D   Y-register High Byte (YH)
 R30  │                │  0x1E   Z-register Low Byte  (ZL)
 R31  │                │  0x1F   Z-register High Byte (ZH)
      └────────────────┘
```

### A divisão R0–R15 × R16–R31

Esta é a pegadinha nº 1 do AVR. Instruções com **operando imediato (constante)** só
funcionam com **R16–R31**.

O motivo é a codificação. O opcode do `ldi` tem 16 bits:

```
 1110 KKKK dddd KKKK
 └─┬┘ └───────┬────┘
opcode    8 bits de K   +  apenas 4 bits para 'd'
```

Com 4 bits só dá para endereçar 16 registradores e o hardware escolheu a metade alta,
fazendo `d = dddd + 16`. Daí a restrição `16 ≤ d ≤ 31`.

Instruções afetadas: **`ldi`, `andi`, `ori`, `subi`, `sbci`, `cpi`, `sbr`, `cbr`, `ser`**.

```asm
ldi r16, 0xFF   ; OK
ldi r15, 0xFF   ; ERRO de montagem
```

Para carregar constante em R0–R15, use um registrador alto como ponte:

```asm
ldi r16, 0xFF
mov r15, r16
```

**Regra prática:** use R16–R31 para trabalho geral e deixe R0–R15 para dados
que já estão prontos ou para variáveis de longa duração.

### Os pares de 16 bits: X, Y e Z

Os seis últimos registradores formam três ponteiros de 16 bits (little-endian: low byte no
registrador de índice menor):

```
              15        8 7         0
  X-register  │ R27 (XH) │ R26 (XL) │   uso geral
  Y-register  │ R29 (YH) │ R28 (YL) │   uso geral + deslocamento (ldd/std)
  Z-register  │ R31 (ZH) │ R30 (ZL) │   uso geral + deslocamento + LPM/ICALL/IJMP
```

Diferenças entre eles:

| | X | Y | Z |
|---|---|---|---|
| `ld`/`st` simples | sim | sim | sim |
| Pós-incremento `X+` / pré-decremento `-X` | sim | sim | sim |
| Deslocamento `ldd r16, Y+5` | **não** | sim | sim |
| Ler Flash (`lpm`) | não | não | **só Z** |
| Salto indireto (`ijmp`, `icall`) | não | não | **só Z** |

Carregando um ponteiro:

```asm
ldi XL, low(0x0100)     ; low()/high() são funções do montador
ldi XH, high(0x0100)
ld  r16, X+             ; r16 ← SRAM[X], depois X ← X+1
```

### Registradores com papel especial implícito

| Registrador | Papel |
|---|---|
| **R1:R0** | Resultado de `mul`, `muls`, `mulsu`, `fmul` |
| **R0** | Destino padrão de `lpm` (na forma `lpm` sem operandos) |
| **R24:R25, X, Y, Z** | Únicos pares aceitos por `adiw` / `sbiw` |
| **Pares de índice par** | Únicos aceitos por `movw` (r0,r2,...,r30) |

---

## 4. Registradores de controle do core

### SREG — Status Register (I/O 0x3F, data 0x5F)

```
 bit   7   6   5   4   3   2   1   0
      ┌───┬───┬───┬───┬───┬───┬───┬───┐
      │ I │ T │ H │ S │ V │ N │ Z │ C │
      └───┴───┴───┴───┴───┴───┴───┴───┘
```

| Flag | Nome | Significado |
|---|---|---|
| **I** | Global Interrupt Enable | Habilita interrupções (`sei` / `cli`) |
| **T** | Bit Copy Storage | Bit temporário usado por `bst` / `bld` |
| **H** | Half Carry | Carry do bit 3 para o 4 — aritmética BCD |
| **S** | Sign | `S = N ⊕ V` — sinal correto para comparação com sinal |
| **V** | Two's Complement Overflow | Estouro em aritmética **com sinal** |
| **N** | Negative | Cópia do bit 7 do resultado |
| **Z** | Zero | Resultado foi zero |
| **C** | Carry | "Vai um" / empresta um em aritmética **sem sinal** |

Todo desvio condicional (`breq`, `brne`, `brcs`, `brlt`, ...) é apenas um teste de bit
do SREG. Por isso a lógica de comparação no AVR é sempre em duas etapas:

```asm
cp   r16, r17     ; compara (subtrai sem salvar) e atualiza flags
breq iguais       ; salta se Z == 1
```

Cuidado: qualquer instrução aritmética/lógica entre o `cp` e o `br**` destrói as flags.

### Stack Pointer — SPH:SPL (I/O 0x3E:0x3D)

Aponta para o topo da pilha na SRAM, usado por `push`/`pop` e por `rcall`/`ret`
(que empilham o endereço de retorno automaticamente). A pilha **cresce para baixo**.

Em código puro em Assembly é obrigatório inicializá-lo antes de qualquer `call`:

```asm
ldi r16, low(RAMEND)
out SPL, r16
ldi r16, high(RAMEND)
out SPH, r16
```

(No ATmega328P `RAMEND = 0x08FF`; o próprio hardware já faz isso no reset nos AVRs
modernos, mas inicializar explicitamente é boa prática e é o que o compilador C faz.)

### Registradores de I/O

Os 64 registradores de I/O (`PORTB`, `DDRB`, `PINB`, `TCCR0A`, ...) ficam em um espaço
próprio de 0x00 a 0x3F, acessado por instruções dedicadas:

```asm
in   r16, PINB        ; registrador ← I/O
out  PORTB, r16       ; I/O ← registrador
sbi  PORTB, 5         ; seta bit — só funciona em I/O 0x00–0x1F
cbi  PORTB, 5         ; limpa bit — idem
sbic PINB, 3          ; pula a próxima instrução se o bit estiver em 0
```

Os **I/O estendidos** (acima de 0x3F, como `UCSR0A` e os registradores do ADC) não são
alcançáveis por `in`/`out` — exigem `lds`/`sts` com o endereço no data space.

---

## 5. Modos de endereçamento e as instruções de cada um

### 5.1 Imediato — `Rd ← constante`

A constante está **gravada na Flash**, codificada dentro do próprio opcode.

```asm
ldi r16, 0x14      ; opcode = 1110 0001 0000 0100
```

Decompondo: `1110` (ldi) | `0001` = K alto | `0000` = d, ou seja r16 | `0100` = K baixo
→ K = `0001 0100` = 0x14. ✓

Instruções: `ldi`, `andi`, `ori`, `subi`, `sbci`, `cpi`, `sbr`, `cbr`, `adiw`, `sbiw`.

> **Não existe `addi`.** Para somar uma constante, usa-se o truque `subi Rd, -K`
> (subtrair o negativo). O montador resolve o complemento de dois. Atenção: nesse caso o
> significado da flag C fica invertido.

`adiw`/`sbiw` operam em 16 bits, com `K` de 0 a 63, e apenas nos pares
**r25:r24, X, Y, Z** — feitas sob medida para aritmética de ponteiros:

```asm
adiw ZH:ZL, 2      ; ou simplesmente: adiw Z, 2
```

### 5.2 Registrador único — `Rd ← f(Rd)`

O operando é o conteúdo de `Rd` e o resultado volta para o próprio `Rd`.
Aqui vale `0 ≤ d ≤ 31` (sem restrição de metade alta).

```
 15            4    0
┌────────────┬──────┐
│     OP     │  Rd  │ ──────▶ REGISTER FILE
└────────────┴──────┘
```

```asm
inc r0
clr r0
```

Instruções:

- **Transferência:** `push`, `pop`
- **Lógica/Aritmética:** `com`, `neg`, `inc`, `dec`, `tst`, `clr`, `ser`
- **Bit:** `lsl`, `lsr`, `asr`, `rol`, `ror`, `swap`, `bld`, `bst`

Várias delas são **pseudo-instruções** (aliases) que o montador traduz:

| Escrito | Vira | Observação |
|---|---|---|
| `clr Rd` | `eor Rd, Rd` | Afeta flags (Z=1, N=V=S=0) |
| `tst Rd` | `and Rd, Rd` | Só testa, não altera Rd |
| `lsl Rd` | `add Rd, Rd` | Deslocamento à esquerda |
| `rol Rd` | `adc Rd, Rd` | Rotação através do carry |
| `ser Rd` | `ldi Rd, 0xFF` | **Restrito a R16–R31!** |

Note a assimetria: `clr` funciona em qualquer registrador, `ser` não — porque é um `ldi`
disfarçado.

### 5.3 Dois registradores — `Rd ← Rd op Rr`

Ambos os operandos vêm de registradores; o resultado vai para `Rd` (destruindo o valor
anterior). `0 ≤ r/d ≤ 31`.

```
 15         9  5 4    0
┌──────────┬────┬──────┐
│    OP    │ Rr │  Rd  │
└──────────┴────┴──────┘
```

```asm
inc  r0
mov  r1, r0      ; r1 ← r0 (cópia de 8 bits)
inc  r0
movw r2, r0      ; r3:r2 ← r1:r0 (cópia de 16 bits em 1 ciclo)
```

`movw` exige que **ambos os índices sejam pares** (0, 2, ..., 30) e copia o par completo.

Instruções:

- **Transferência:** `mov`, `movw`
- **Lógica/Aritmética:** `add`, `adc`, `sub`, `sbc`, `and`, `or`, `eor`,
  `mul`, `muls`, `mulsu`, `fmul`, `fmuls`, `fmulsu`
- **Comparação:** `cp`, `cpc`, `cpse`

### 5.4 Direto na memória de dados — `lds` / `sts`

Endereço de 16 bits codificado na instrução (instrução de **2 palavras**, 2 ciclos).

```asm
lds r16, 0x0100     ; r16 ← SRAM[0x0100]
sts 0x0100, r16     ; SRAM[0x0100] ← r16
```

### 5.5 Indireto — `ld` / `st` via X, Y, Z

```asm
ld  r16, X          ; r16 ← SRAM[X]
ld  r16, X+         ; lê e depois incrementa X    (pós-incremento)
ld  r16, -X         ; decrementa X e depois lê    (pré-decremento)
ldd r16, Y+5        ; r16 ← SRAM[Y+5]  (só Y e Z, deslocamento de 0 a 63)
st  Z, r16          ; SRAM[Z] ← r16
```

É este modo que torna possível percorrer vetores e implementar structs.

### 5.6 Memória de programa — `lpm`

Como Harvard separa os barramentos, ler uma tabela de constantes da Flash exige uma
instrução própria, e **apenas via Z**:

```asm
        ldi ZL, low(tabela*2)    ; *2 porque Z endereça BYTES e a Flash é em PALAVRAS
        ldi ZH, high(tabela*2)
        lpm r16, Z+
        ...
tabela: .DB 0x01, 0x02, 0x04, 0x08
```

O `*2` é outra pegadinha clássica: rótulos na Flash são endereços de palavra, mas `Z` em
`lpm` é endereço de byte.

---

## 6. Diretivas do montador

Diretivas **não geram código** — são instruções para o montador.

### `.DEF` — nome simbólico para um registrador

```asm
.DEF temp = r16
.DEF contador = r17
```

Serve para dar significado ao código. `ldi temp, 5` é muito mais legível que `ldi r16, 5`,
e se você precisar trocar de registrador, muda em um lugar só.

### `.EQU` — constante simbólica a partir de uma expressão

```asm
.EQU valor = 0x23 + 5
.EQU LED   = PB5
```

A expressão é avaliada **em tempo de montagem**, sem custo de execução.

### Exemplo completo dos dois

```asm
.DEF temp = r16
.EQU valor = 0x23 + 5

start:
    ldi  temp, valor     ; inicializa o reg. temp com valor
    inc  temp            ; incrementa o reg. temp
    rjmp start
```

### Outras diretivas úteis

| Diretiva | Função |
|---|---|
| `.ORG endereço` | Define onde o código/dado começa |
| `.CSEG` / `.DSEG` / `.ESEG` | Seleciona o segmento (código / dados / EEPROM) |
| `.DB` / `.DW` | Grava bytes/palavras constantes na Flash |
| `.BYTE n` | Reserva n bytes na SRAM (só no `.DSEG`) |
| `.INCLUDE "m328Pdef.inc"` | Traz os nomes dos registradores de I/O do chip |
| `.MACRO` / `.ENDMACRO` | Define uma macro |

Diferença essencial: `.DEF`/`.EQU` são **apelidos**, enquanto `.BYTE` **reserva espaço
real**. Confundir os dois é erro comum de iniciante.

---

## 7. Convenção de uso dos registradores

Não é obrigatória em Assembly puro, mas seguir a convenção do GCC facilita a vida quando
você misturar Assembly com C:

| Registradores | Convenção no AVR-GCC |
|---|---|
| **R0** | Temporário, livre para uso (nenhuma função preserva) |
| **R1** | Sempre zero — o código C assume `r1 == 0`. **Se você usar, zere antes de voltar ao C** |
| **R2–R17, R28, R29** | *Call-saved*: quem usa deve salvar e restaurar (`push`/`pop`) |
| **R18–R27, R30, R31** | *Call-used*: livres, podem ser destruídos por chamadas |
| **R25:R24, R23:R22, ...** | Passagem de argumentos, da esquerda para a direita |
| **R25:R24** | Valor de retorno |

Em Assembly puro, uma convenção pessoal minimamente organizada já ajuda muito. Por exemplo:

```asm
.DEF zero    = r1       ; sempre 0
.DEF temp    = r16      ; rascunho
.DEF arg     = r17      ; parâmetro
.DEF ret     = r24      ; retorno
.DEF contador= r18
```

---

### Padrões de controle de fluxo

**Laço contado:**

```asm
        ldi  contador, 10
loop:
        ; ... corpo ...
        dec  contador
        brne loop            ; repete enquanto contador != 0
```

`dec` já atualiza Z — não é preciso comparar com zero.

**Condicional simples (if a == b):**

```asm
        cp   a, b
        brne fim             ; se diferente, pula o bloco
        ; ... bloco do "então" ...
fim:
```

Note a inversão: o desvio testa a condição **contrária** para pular o bloco.

**Comparação com/sem sinal** — usar o par errado é fonte de bug silencioso:

| Comparação | Sem sinal | Com sinal |
|---|---|---|
| `a < b` | `brlo` (= `brcs`) | `brlt` |
| `a >= b` | `brsh` (= `brcc`) | `brge` |
| `a == b` | `breq` | `breq` |

---