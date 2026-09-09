# Setup de Ferramentas AVR para Assembly

## 1. Instalação das ferramentas

Baixe e instale os seguintes arquivos para o sistema operacional desejado:

- **IDE:** MPLAB X v6.15 (Windows, Linux ou macOS)
  - Baixe a versão correspondente ao seu sistema operacional e instale.

- **Compilador:** MPLAB XC8 v2.05 (Windows, Linux ou macOS)
  - Baixe a versão correspondente ao seu sistema operacional e instale.

> **Importante:** anote os caminhos das instalações. Eles serão necessários na configuração do montador.

---

## 2. Configuração do montador `avrasm2`

1. Abra o **MPLAB X IDE**.

2. Acesse:

   **Tools → Options**

3. Selecione:

   **Embedded → Build Tools → Add...**

4. Adicione o caminho da instalação do compilador no campo **Base Directory**.

   Exemplo:

   ```text
   /opt/microchip/xc8/v2.05/avr/bin
   ```

5. No campo **Version**, selecione:

   ```text
   avrasm2
   ```

6. Clique em **OK** e depois em **OK** novamente.

---

## 3. Criando o projeto

1. Abra o **MPLAB X IDE**.

2. Acesse:

   **File → New Project**

3. Configure:

   - **Categories:** `Microchip Embedded`
   - **Projects:** `Standalone Project`

4. Clique em **Next**.

5. Configure:

   - **Device:** `ATmega328P`
   - **Tool:** `Simulator`

   > Digite `ATmega328P` no campo **Device** para localizar o microcontrolador.

6. Clique em **Next**.

7. Selecione:

   ```text
   avrasm2
   ```

8. Clique em **Next**.

9. Defina o **nome do projeto** e a **localização**.

10. Clique em **Finish**.

---

## 4. Adicionando um arquivo `.ASM`

1. Clique com o botão direito em **Source Files**.

2. Selecione:

   **New → main.asm...**

3. Defina o nome do arquivo.

4. Mantenha a extensão como **ASM**.

5. Clique em **Finish**.

Será criado um exemplo semelhante a:

```asm
start:
    inc r16
    rjmp start
```

---

## 5. Configurando o simulador

1. Selecione as propriedades do projeto:
   
   **Botão direito sobre o nome do projeto → Properties**

2. No menu **Categories**, selecione:

   **Simulator**

3. Configure o oscilador para **16 MHz**:

   - **Instruction Frequency (Fcyc):** `16`
   - **Frequency in:** `MHz`

4. No menu **Option Categories**, selecione:

   **Reset**

5. Configure:

   - **Reset Type:** `MCLR`

6. Pressione **Apply** e depois **OK**.

---

## 6. Visualizando as memórias

No menu:

**Window → Target Memories Views**

Selecione as seguintes janelas:

- **Program Memory**
- **SRAM Data Memory**
- **I/O Memory (SFRs)**

Configure o posicionamento das janelas conforme sua preferência.

### Sugestão

Deixe as três janelas visíveis simultaneamente para facilitar o acompanhamento da execução do programa.

---

## 7. Montando o programa para Debug

Acesse:

**Debug → Discrete Debugger Operation → Build for Debugging Main Project**

Aguarde a conclusão da montagem do programa.

---

## 8. Iniciando a simulação

Para iniciar o simulador, acesse:

**Debug → Debug Main Project**

O programa será carregado no simulador.

Agora é possível acompanhar a execução das instruções e observar as alterações em:

- **Program Memory**
- **SRAM Data Memory**
- **I/O Memory (SFRs)**

---

## 9. Resultado

Com essas configurações, o ambiente estará pronto para desenvolver e simular programas **Assembly para AVR** utilizando:

- **MPLAB X IDE v6.15**
- **MPLAB XC8 v2.05**
- **avrasm2**
- **ATmega328P**
- **Simulator**
