if (A>B) {
  A = A+1; // Bloco 1
} else {
  B = B+1; // Bloco 2
}


.data
    A  : 0
    B  : 1
.text
	LD A
	SUB B
	BLT ELSE    ; Se A menor que B 
THEN:
	LD A
	ADDI 1
	STO A
	HLT
ELSE:
	LD B
	ADDI 1
	STO B
	HLT
