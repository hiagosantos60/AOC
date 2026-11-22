# GUIA DE ESTUDO: TEMPORIZADOR/CONTADOR (TC0, TC1, TC2)
Matéria: Arquitetura e Organização de Computadores (AOC) - IFSC SJ
Microcontrolador: ATmega328P - f_osc = 16 MHz

Fontes: handout "Temporizador/Contador" do prof. Roberto de Matos e datasheet
ATmega328P (DS40002061B): vetores p. 74 (Tabela 12-6), TC0 p. 102-119,
TC1 p. 120-146, TC2 p. 150-167.

---

## 1. OS TRÊS TIMERS DO ATMEGA328P

| | TC0 | TC1 | TC2 |
|---|---|---|---|
| Tamanho | 8 bits | 16 bits | 8 bits |
| MAX | 255 (0xFF) | 65535 (0xFFFF) | 255 (0xFF) |
| Prescalers | 1, 8, 64, 256, 1024 | 1, 8, 64, 256, 1024 | 1, 8, **32**, 64, **128**, 256, 1024 |
| Instrução p/ configurar | `OUT` (menos TIMSK0 = `STS`) | **tudo `STS`** | **tudo `STS`** |
| Vetor overflow | 0x0020 | 0x001A | 0x0012 |
| Vetor comparação A | **0x001C** | 0x0016 | 0x000E |

O timer é só um contador (TCNTx) que soma +1 a cada pulso de clock que sai do prescaler.

```
f_osc (16 MHz) --> [ PRESCALER ÷N ] --> [ TCNTx: 0,1,2,... ] --> estouro / comparação --> flag --> interrupção
```

---

## 2. FÓRMULAS

### Modo Normal (overflow): conta de 0 até MAX e estoura
```
t_estouro = (MAX + 1) × N / f_osc          TC0/TC2: (255+1)    TC1: (65535+1)
```

### Modo CTC: conta de 0 até OCRxA e zera
```
t_int = (OCRxA + 1) × N / f_osc
OCRxA = (t × f_osc / N) - 1                -> tem que dar INTEIRO e caber (≤255 ou ≤65535)
```

### Quantas interrupções contar na variável
```
n = t_desejado / t_int
```

### Duração de 1 "tique" do timer (16 MHz) - atalho para não errar conta
| N | tiques por segundo | 1 tique dura |
|---|---|---|
| 1 | 16.000.000 | 62,5 ns |
| 8 | 2.000.000 | 0,5 µs |
| 64 | 250.000 | 4 µs |
| 256 | 62.500 | 16 µs |
| 1024 | 15.625 | 64 µs |

Então: **OCR = (t / tique) − 1**. Ex.: 4 ms / 16 µs = 250 → OCR0A = 249.

---

## 3. TABELAS PRONTAS (16 MHz)

### Tempo de estouro no modo Normal
| N | TC0 / TC2 (8 bits) | TC1 (16 bits) |
|---|---|---|
| 1 | 16 µs | 4,096 ms |
| 8 | 128 µs | 32,768 ms |
| 32 (só TC2) | 512 µs | - |
| 64 | 1,024 ms | 262,144 ms |
| 128 (só TC2) | 2,048 ms | - |
| 256 | 4,096 ms | 1,048576 s |
| 1024 | 16,384 ms | 4,194304 s |

### Intervalos exatos no CTC com TC0 (8 bits)
| Intervalo | N | OCR0A |
|---|---|---|
| 10 µs | 1 | 159 |
| 100 µs | 8 | 199 |
| 500 µs | 64 | 124 |
| 1 ms | 64 | 249 |
| 2 ms | 256 | 124 |
| 4 ms | 256 | 249 |
| 8 ms | 1024 | 124 |
| 16 ms | 1024 | 249 |
| 5 ms / 10 ms | **impossível direto** (5 ms / 64 µs = 78,125, não inteiro) → use 1 ms × 5 / 2 ms × 5 | |

### Intervalos exatos no CTC com TC1 (16 bits)
| Intervalo | N | OCR1A | hex |
|---|---|---|---|
| 100 ms | 256 | 6249 | 0x1869 |
| 250 ms | 64 | 62499 | 0xF423 |
| 500 ms | 256 | 31249 | 0x7A11 |
| 1 s | 256 | 62499 | 0xF423 |
| 1 s | 1024 | 15624 | 0x3D08 |
| 2 s | 1024 | 31249 | 0x7A11 |
| 4 s | 1024 | 62499 | 0xF423 |
| 5 s | não cabe (78125 > 65535) → 1 s × 5 | | |

### Precisão para piscar a cada 1 s
| Método | Interrupções | Tempo real | Erro |
|---|---|---|---|
| TC0 overflow, N=1024 (slide) | 62 | 1015,8 ms | +1,58% |
| TC0 overflow, N=1024 | 61 | 999,4 ms | −0,06% |
| TC0 CTC, N=256, OCR0A=249 (4 ms) | 250 | 1000 ms | 0 |
| TC0 CTC, N=1024, OCR0A=124 (8 ms) | 125 | 1000 ms | 0 |
| TC1 overflow, N=256 | 1 | 1048,6 ms | +4,86% |
| TC1 CTC, N=256, OCR1A=62499 | 1 | 1000 ms | 0 |

> Cuidado com a interpretação: "LED pisca com **período** de 1 s" = inverte a cada **500 ms**.
> "Inverte a cada 1 s" = período de 2 s. Na atividade do botão: 200 ms de período = 100 ms aceso + 100 ms apagado.

---

## 4. PASSO A PASSO PARA ESCOLHER PRESCALER E OCR

1. Escreva o tempo desejado t.
2. Para cada N (do menor pro maior): calcule X = t × f_osc / N.
3. Sirva o primeiro N em que X é **inteiro** e **X ≤ 256** (TC0/TC2) ou **X ≤ 65536** (TC1).
4. OCR = X − 1.
5. Se nenhum serviu: quebre o tempo em pedaços (ex.: 1 s = 250 × 4 ms) e conte as interrupções numa variável na SRAM.
6. Prefira que a contagem caiba em **1 byte (≤ 255)**: aí basta `inc` + `cpi`.

Exemplo: 2 ms no TC0
- N=1: 32000 (não cabe) - N=8: 4000 (não cabe) - N=64: 500 (não cabe) - **N=256: 125 ✓** → OCR0A = 124.

---

## 5. REGISTRADORES

### TC0 (o mais cobrado)
| Registrador | Endereço I/O (memória) | Instrução | Bits 7 → 0 |
|---|---|---|---|
| TCCR0A | 0x24 (0x44) | `OUT` | COM0A1 COM0A0 COM0B1 COM0B0 – – **WGM01 WGM00** |
| TCCR0B | 0x25 (0x45) | `OUT` | FOC0A FOC0B – – WGM02 **CS02 CS01 CS00** |
| TCNT0 | 0x26 (0x46) | `OUT`/`IN` | contador (o "hodômetro") |
| OCR0A | 0x27 (0x47) | `OUT` | valor de comparação A (a "linha de chegada") |
| OCR0B | 0x28 (0x48) | `OUT` | valor de comparação B |
| TIMSK0 | – (0x6E) | **`STS`** | – – – – – OCIE0B **OCIE0A TOIE0** |
| TIFR0 | 0x15 (0x35) | `OUT`/`SBI` | – – – – – OCF0B OCF0A TOV0 |

- **TCCR0A** → modo (WGM) e pinos OC0A/OC0B (COM).
- **TCCR0B** → prescaler (CS). Com CS = 000 o timer fica **parado**. Por isso configure-o **por último**.
- **TIMSK0** → "chave local" da interrupção. Tem que bater com o modo:
  - Overflow → `TOIE0` (bit 0) → `0b00000001`
  - CTC com OCR0A → `OCIE0A` (bit 1) → `0b00000010`
- **TIFR0** → flags. São limpas **sozinhas** quando a ISR é executada. Limpar manualmente = escrever **1** (`sbi TIFR0, OCF0A`).

### TC1 (16 bits) - TUDO com STS
| Registrador | Memória | Bits 7 → 0 |
|---|---|---|
| TCCR1A | 0x80 | COM1A1 COM1A0 COM1B1 COM1B0 – – WGM11 WGM10 |
| TCCR1B | 0x81 | ICNC1 ICES1 – WGM13 **WGM12** **CS12 CS11 CS10** |
| TCNT1H / TCNT1L | 0x85 / 0x84 | contador 16 bits |
| OCR1AH / OCR1AL | 0x89 / 0x88 | comparação A 16 bits |
| TIMSK1 | 0x6F | – – ICIE1 – – OCIE1B **OCIE1A TOIE1** |
| TIFR1 | 0x16 (0x36) | – – ICF1 – – OCF1B OCF1A TOV1 |

- **CTC no TC1: o bit é WGM12 e ele fica no TCCR1B** (não no TCCR1A!). Modo 4: WGM13:0 = 0100.
- **Escrita 16 bits: ALTO primeiro, depois BAIXO** (datasheet p. 122). Leitura: BAIXO primeiro.

### TC2 - TUDO com STS
| Registrador | Memória | Bits 7 → 0 |
|---|---|---|
| TCCR2A | 0xB0 | COM2A1 COM2A0 COM2B1 COM2B0 – – WGM21 WGM20 |
| TCCR2B | 0xB1 | FOC2A FOC2B – – WGM22 CS22 CS21 CS20 |
| TCNT2 | 0xB2 | contador |
| OCR2A | 0xB3 | comparação A |
| TIMSK2 | 0x70 | – – – – – OCIE2B OCIE2A TOIE2 |
| TIFR2 | 0x17 (0x37) | – – – – – OCF2B OCF2A TOV2 |

### OUT x STS x SBI (manual de instruções AVR)
| Instrução | Faixa de endereço | Uso nos timers |
|---|---|---|
| `SBI`/`CBI` | I/O 0 a 31 | TIFRx, DDRx, PORTx, PINx |
| `OUT`/`IN` | I/O 0 a 63 | TCCR0A, TCCR0B, TCNT0, OCR0A, OCR0B, TIFRx |
| `STS`/`LDS` | qualquer endereço de memória | TIMSK0/1/2, **todo o TC1 e TC2** |

Pegadinhas:
- `out TIMSK0, r16` → **erro de montagem** (0x6E > 63).
- `sbi TCCR0B, CS02` → **erro de montagem** (0x25 > 31). Use `ldi` + `out`.
- `sts TCCR0A, r16` → **monta, mas está ERRADO**: no .inc, TCCR0A = 0x24 é o endereço de I/O; como endereço de memória, 0x24 é o **DDRB**! Registrador de I/O → use `OUT`.

---

## 6. TABELAS DO DATASHEET

### Modo de operação TC0 (Tabela 15-8, p. 115)
| Modo | WGM02 | WGM01 | WGM00 | Operação | TOP | TOV0 liga em |
|---|---|---|---|---|---|---|
| **0** | 0 | 0 | 0 | **Normal** | 0xFF | MAX |
| 1 | 0 | 0 | 1 | PWM Phase Correct | 0xFF | BOTTOM |
| **2** | 0 | 1 | 0 | **CTC** | **OCR0A** | MAX |
| 3 | 0 | 1 | 1 | Fast PWM | 0xFF | MAX |
| 5 | 1 | 0 | 1 | PWM Phase Correct | OCR0A | BOTTOM |
| 7 | 1 | 1 | 1 | Fast PWM | OCR0A | TOP |

- Normal → `TCCR0A = 0b00000000` (já é o valor de reset).
- CTC → `TCCR0A = 0b00000010` (WGM01).
- No CTC com OCR0A < 255 o TCNT0 **nunca chega em 0xFF** → TOV0 nunca liga → **TOIE0 não funciona no CTC**, use OCIE0A.

### Prescaler TC0 e TC1 (Tabelas 15-9 e 16-5)
| CS2 | CS1 | CS0 | Clock | `ldi` |
|---|---|---|---|---|
| 0 | 0 | 0 | timer parado | 0b00000000 |
| 0 | 0 | 1 | ÷1 | 0b00000001 |
| 0 | 1 | 0 | ÷8 | 0b00000010 |
| 0 | 1 | 1 | ÷64 | 0b00000011 |
| 1 | 0 | 0 | ÷256 | 0b00000100 |
| 1 | 0 | 1 | ÷1024 | 0b00000101 |
| 1 | 1 | 0 | pino externo T0/T1, borda de **descida** | |
| 1 | 1 | 1 | pino externo T0/T1, borda de **subida** | |

> Obs.: no slide 7 do handout as linhas 110 e 111 aparecem as duas como "borda de subida". O datasheet
> diz que 110 = descida e 111 = subida.

### Prescaler TC2 (Tabela 18-9) - DIFERENTE!
| CS22 | CS21 | CS20 | Clock |
|---|---|---|---|
| 0 | 0 | 0 | parado |
| 0 | 0 | 1 | ÷1 |
| 0 | 1 | 0 | ÷8 |
| 0 | 1 | 1 | **÷32** |
| 1 | 0 | 0 | **÷64** |
| 1 | 0 | 1 | **÷128** |
| 1 | 1 | 0 | **÷256** |
| 1 | 1 | 1 | **÷1024** |

> Pegadinha: `0b00000100` é ÷256 no TC0, mas **÷64 no TC2**. E ÷1024 no TC2 é `0b00000111`
> (no TC0, 111 é clock externo!).

### Pino OC0A em modo não-PWM (Tabela 15-2, p. 113) - bits COM0A1:0 do TCCR0A
| COM0A1 | COM0A0 | O que acontece no OC0A (PD6) na comparação |
|---|---|---|
| 0 | 0 | nada (pino normal) |
| 0 | 1 | **inverte** (toggle) |
| 1 | 0 | zera |
| 1 | 1 | liga |

Frequência da onda gerada no pino (CTC + toggle): **f = f_osc / (2 × N × (1 + OCR0A))** (p. 108).
OC0B = PD5. O pino precisa estar como saída no DDR.

---

## 7. VETORES DE INTERRUPÇÃO (Tabela 12-6, p. 74)

| Endereço | Fonte | Nome no .inc |
|---|---|---|
| 0x0000 | RESET | |
| 0x0002 | INT0 (PD2) | `INT0addr` |
| 0x0004 | INT1 (PD3) | `INT1addr` |
| 0x000E | TIMER2_COMPA | `OC2Aaddr` |
| 0x0010 | TIMER2_COMPB | `OC2Baddr` |
| 0x0012 | TIMER2_OVF | `OVF2addr` |
| 0x0014 | TIMER1_CAPT | `ICP1addr` |
| 0x0016 | TIMER1_COMPA | `OC1Aaddr` |
| 0x0018 | TIMER1_COMPB | `OC1Baddr` |
| 0x001A | TIMER1_OVF | `OVF1addr` |
| **0x001C** | **TIMER0_COMPA** | `OC0Aaddr` |
| 0x001E | TIMER0_COMPB | `OC0Baddr` |
| **0x0020** | **TIMER0_OVF** | `OVF0addr` |
| 0x0022 | SPI_STC (**não é timer!**) | `SPIaddr` |
| 0x0034 | primeiro endereço livre depois da tabela | `INT_VECTORS_SIZE` = 52 = 0x34 |

Para decorar: os timers vêm na ordem **TC2 → TC1 → TC0**, e dentro de cada um **COMPA → COMPB → OVF**.
Se o `m328pdef.inc` estiver incluído, dá para escrever `.org OC0Aaddr` em vez do número.

---

## 8. CHECKLIST DE CONFIGURAÇÃO

```
1. .org 0x0000 -> rjmp setup
2. .org <VETOR CERTO> -> rjmp isr_...
3. Pino do LED: sbi DDRx, Pxn  /  cbi PORTx, Pxn
4. Variável de contagem na SRAM (.dseg) = 0
5. OCRxA (se CTC)
6. TCCRxA (modo)            [TC1: o modo CTC vai no TCCR1B]
7. TIMSKx (OCIExA ou TOIEx)  -> STS
8. TCCRxB (prescaler)        -> por último, liga o timer
9. sei
10. main: rjmp main
11. ISR: salva contexto -> trabalho -> restaura contexto -> RETI
```

---

## 9. TEMPLATES

### A) TC0 - Overflow (~1 s, igual ao slide mas com contexto salvo)
```asm
.include "m328pdef.inc"
.def AUX = r16

.dseg
contagem: .byte 1

.cseg
.org 0x0000
    rjmp setup
.org 0x0020                 ; TIMER0_OVF
    rjmp isr_tc0_ovf
.org 0x0034
setup:
    sbi  DDRB, PB5          ; LED (PB5) como saída
    cbi  PORTB, PB5         ; LED apagado

    ldi  AUX, 0
    sts  contagem, AUX

                            ; TCCR0A = 0 (modo normal) -> valor de reset, não precisa escrever
    ldi  AUX, 0b00000001    ; TOIE0
    sts  TIMSK0, AUX        ; TIMSK0 só com STS
    ldi  AUX, 0b00000101    ; CS02|CS00 -> prescaler 1024 -> estouro a cada 16,384 ms
    out  TCCR0B, AUX
    sei
main:
    rjmp main

isr_tc0_ovf:
    push AUX
    in   AUX, SREG
    push AUX

    lds  AUX, contagem
    inc  AUX
    cpi  AUX, 62            ; 62 × 16,384 ms = 1015,8 ms
    brne salva_ovf
    sbi  PINB, PB5          ; escrever 1 no PINx inverte o pino
    ldi  AUX, 0
salva_ovf:
    sts  contagem, AUX

    pop  AUX
    out  SREG, AUX
    pop  AUX
    reti
```

### B) TC0 - CTC (1 s exato)
```asm
.include "m328pdef.inc"
.def AUX = r16

.dseg
contagem: .byte 1

.cseg
.org 0x0000
    rjmp setup
.org 0x001C                 ; TIMER0_COMPA  (NÃO é 0x0022!)
    rjmp isr_tc0_compa
.org 0x0034
setup:
    sbi  DDRB, PB5
    cbi  PORTB, PB5

    ldi  AUX, 0
    sts  contagem, AUX

    ldi  AUX, 249
    out  OCR0A, AUX         ; (249+1) × 256 / 16 MHz = 4 ms
    ldi  AUX, 0b00000010    ; WGM01 -> modo CTC
    out  TCCR0A, AUX
    ldi  AUX, 0b00000010    ; OCIE0A
    sts  TIMSK0, AUX
    ldi  AUX, 0b00000100    ; CS02 -> prescaler 256 (liga o timer)
    out  TCCR0B, AUX
    sei
main:
    rjmp main

isr_tc0_compa:
    push AUX
    in   AUX, SREG
    push AUX

    lds  AUX, contagem
    inc  AUX
    cpi  AUX, 250           ; 250 × 4 ms = 1000 ms
    brne salva_ctc
    sbi  PINB, PB5
    ldi  AUX, 0
salva_ctc:
    sts  contagem, AUX

    pop  AUX
    out  SREG, AUX
    pop  AUX
    reti
```
Variante: `OCR0A = 124` + prescaler 1024 (`0b00000101`) → 8 ms; conta **125** → 1 s.

### C) TC1 - Overflow (~1,05 s, atividade 3)
```asm
.org 0x0000
    rjmp setup
.org 0x001A                 ; TIMER1_OVF
    rjmp isr_tc1_ovf
.org 0x0034
setup:
    sbi  DDRB, PB5
    cbi  PORTB, PB5
    ldi  r16, 0b00000001    ; TOIE1
    sts  TIMSK1, r16
    ldi  r16, 0b00000100    ; CS12 -> prescaler 256 -> 65536 × 256 / 16 MHz = 1,048576 s
    sts  TCCR1B, r16        ; TC1 inteiro é STS
    sei
main:
    rjmp main

isr_tc1_ovf:
    sbi  PINB, PB5          ; SBI não mexe no SREG nem em registradores -> não precisa salvar contexto
    reti
```

### D) TC1 - CTC (1 s exato, sem variável de contagem)
```asm
.org 0x0000
    rjmp setup
.org 0x0016                 ; TIMER1_COMPA
    rjmp isr_tc1_compa
.org 0x0034
setup:
    sbi  DDRB, PB5
    cbi  PORTB, PB5

    ldi  r16, high(62499)   ; 62499 = 0xF423
    sts  OCR1AH, r16        ; 16 bits: ALTO primeiro
    ldi  r16, low(62499)
    sts  OCR1AL, r16        ; ... depois o BAIXO

                            ; TCCR1A = 0 (WGM11:10 = 00) -> valor de reset
    ldi  r16, 0b00000010    ; OCIE1A
    sts  TIMSK1, r16
    ldi  r16, 0b00001100    ; WGM12 (CTC, TOP = OCR1A) | CS12 (prescaler 256)
    sts  TCCR1B, r16
    sei
main:
    rjmp main

isr_tc1_compa:
    sbi  PINB, PB5          ; (62499+1) × 256 / 16 MHz = 1 s
    reti
```

### E) TC2 - CTC (1 s exato)
```asm
.dseg
contagem: .byte 1

.cseg
.org 0x0000
    rjmp setup
.org 0x000E                 ; TIMER2_COMPA
    rjmp isr_tc2_compa
.org 0x0034
setup:
    sbi  DDRB, PB5
    cbi  PORTB, PB5
    ldi  r16, 0
    sts  contagem, r16

    ldi  r16, 124
    sts  OCR2A, r16         ; (124+1) × 1024 / 16 MHz = 8 ms
    ldi  r16, 0b00000010    ; WGM21 -> CTC
    sts  TCCR2A, r16
    ldi  r16, 0b00000010    ; OCIE2A
    sts  TIMSK2, r16
    ldi  r16, 0b00000111    ; prescaler 1024 NO TC2 é 111 !
    sts  TCCR2B, r16
    sei
; ISR igual à do template B, mas com cpi 125 (125 × 8 ms = 1 s)
```

### F) Onda quadrada no pino SEM interrupção (CTC + toggle no OC0A)
```asm
setup:
    sbi  DDRD, PD6          ; OC0A = PD6 precisa ser saída
    ldi  r16, 124
    out  OCR0A, r16
    ldi  r16, 0b01000010    ; COM0A0 (toggle OC0A) | WGM01 (CTC)
    out  TCCR0A, r16
    ldi  r16, 0b00000011    ; prescaler 64
    out  TCCR0B, r16
main:
    rjmp main               ; o hardware inverte o PD6 sozinho
; f = 16 MHz / (2 × 64 × (1 + 124)) = 1000 Hz
```

### G) Contagem maior que 255 (variável de 16 bits na SRAM)
Use só se não der pra escolher um intervalo maior. Ex.: 1000 × 1 ms.
```asm
.dseg
cont: .byte 2               ; cont = byte baixo, cont+1 = byte alto

; dentro da ISR (salvar r16, SREG, r24, r25 antes):
    lds  r24, cont
    lds  r25, cont+1
    adiw r24, 1             ; r25:r24 += 1 (ADIW só em r24, r26, r28, r30)
    ldi  r16, high(1000)
    cpi  r24, low(1000)
    cpc  r25, r16           ; Z = 1 só se os 16 bits forem iguais
    brne salva16
    sbi  PINB, PB5
    clr  r24
    clr  r25
salva16:
    sts  cont, r24
    sts  cont+1, r25
```

### H) Timer + botão (atividade da aula 10/11)
Referência completa: `10-11-2026/aula/codigo_aula.asm`. Ideia:
- Duas variáveis na SRAM: `contagem` (incrementa a cada estouro) e `intervalo` (quantos estouros até inverter o LED).
- `isr_tc0b` (overflow, 0x0020): `contagem++`; se `contagem >= intervalo` → inverte LED e zera `contagem`.
- `isr_int0` (0x0002, borda de descida: `EICRA = 0b00000010`, `sbi EIMSK, INT0`): `intervalo -= 6`;
  se chegou a 0 volta para 30; zera `contagem`.
- 30 × 16,384 ms ≈ 491 ms de meio período → período ≈ 983 ms (~1 s); cada passo de 6 ≈ 98 ms de meio período (≈ 200 ms no período).

---

## 10. FLUXOGRAMA MODELO (CTC, template B)

```
   ( Reset )                         ( isr_tc0_compa )
       |                                    |
 [Config. pino LED]                 [Salva contexto: R16, SREG]
       |                                    |
 [contagem = 0]                      [contagem = contagem + 1]
       |                                    |
 [OCR0A = 249]                       < contagem == 250? >--Não--+
       |                                    | Sim               |
 [TC0 modo CTC (WGM01)]               [Inverte LED]             |
       |                                    |                   |
 [Habilita int. OCIE0A]               [contagem = 0]            |
       |                                    |<------------------+
 [TC0 prescaler 256]                 [Grava contagem na SRAM]
       |                                    |
 [Habilita I global (SEI)]           [Restaura contexto]
       |                                    |
   +-->o                                ( Retorno )
   |   |
   +---+   (laço infinito)
```
O fluxograma tem que representar **exatamente** o código (mesma ordem, mesmos testes).

---

## 11. ERROS COMUNS (REVISE ANTES DE ENTREGAR)

- [ ] Vetor errado: **CTC TC0 = 0x001C**, overflow TC0 = 0x0020, TC1 COMPA = 0x0016, TC1 OVF = 0x001A, TC2 COMPA = 0x000E, TC2 OVF = 0x0012.
- [ ] `out` em TIMSKx, ou em qualquer registrador do TC1/TC2 → tem que ser `sts`.
- [ ] `sts` em TCCR0A/TCCR0B/OCR0A/TCNT0 → tem que ser `out`.
- [ ] Modo e bit de interrupção não batem (CTC com TOIE0, ou overflow com OCIE0A).
- [ ] Esqueceu o prescaler (TCCRxB = 0 → timer parado) ou esqueceu o `sei`.
- [ ] OCR = valor **− 1** (contagem vai de 0 até OCR → OCR+1 tiques).
- [ ] TC1 CTC: WGM12 está no **TCCR1B**. TC1 16 bits: **alto primeiro**.
- [ ] TC2 tem tabela de prescaler diferente.
- [ ] ISR sem salvar SREG e os registradores usados, ou terminando com `ret` em vez de `reti`.
- [ ] `push`/`pop` em ordem inversa (último a entrar, primeiro a sair).
- [ ] Variável usada na ISR com nome diferente do declarado no `.dseg`.
- [ ] `cpi`/`ldi` só funcionam de r16 a r31.
- [ ] Contagem > 255 em um registrador de 8 bits.
- [ ] Confundir período com meio período do pisca-LED.

---

## 12. EXERCÍCIOS RÁPIDOS (com resposta)

1. Tempo de estouro do TC0 com prescaler 64? → (256 × 64) / 16 MHz = **1,024 ms**.
2. Quantos estouros do TC0 (N=1024) para ~500 ms? → 500 / 16,384 = 30,5 → **30** (491,5 ms) ou **31** (507,9 ms).
3. OCR0A e N para interrupção a cada 2 ms? → N=64 dá 500 (não cabe); **N=256 → OCR0A = 124**.
4. LED piscando a 5 Hz com TC0 CTC? → período 200 ms → inverte a cada 100 ms → 4 ms × **25** (OCR0A=249, N=256).
5. TC1 CTC a cada 0,5 s? → N=256: 0,5 × 62500 = 31250 → **OCR1A = 31249 = 0x7A11** (OCR1AH = 0x7A, OCR1AL = 0x11).
6. Onda de 1 kHz no PD6 sem interrupção? → CTC + COM0A0, **N=64, OCR0A=124**.
7. Por que 10 ms não sai exato com uma única interrupção do TC0? → 10 ms × 16 MHz / N = 160000/N; para N=1024 dá 156,25 (não inteiro), para N ≤ 256 passa de 256. Use 2 ms × 5 ou 1 ms × 10.
8. Valor de TCCR1B para TC1 em CTC (OCR1A) com prescaler 1024? → WGM12 | CS12 | CS10 = **0b00001101**.
