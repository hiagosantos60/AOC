i = 0; 
do {
  A += 2    // Bloco 1
  i++;
} while (i<10)
// Bloco 2

.data
    A : 0
    i : 0
.text
    LD i

BLOCO1:
    LD A
    ADDI 2    # A += 2 
    STO A

    LD i
    ADDI 1    # i += 1  
    STO i          

    SUBI 10
    BLT BLOCO1       # verifica a condição e volta caso falsa (TESTAR)  

BLOCO2:
    HLT