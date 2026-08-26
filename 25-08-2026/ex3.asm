
Estrutura while
i = 0;
while (i<10) {
    A += 2;     // Bloco 1
    i++; 
}
// Bloco 2


.data
    A : 0
    i : 0
.text

    LD i
LOOP:
		SUBI 10	 
    BGE FIM
    
    LD A
    ADDI 2 # incrementa A
    STO A
    
    LD i
    ADDI 1 # incrementa B
    STO i
    
    JMP LOOP # retorna

FIM:
    HLT