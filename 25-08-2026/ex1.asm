if (A>=B) {
  A = A + 1 // Bloco 1
}

.data
    A  : 3
    B  : 1
.text
    LD A
    SUB B
	  BLT FIM
THEN:               ; BLOCO 1
	  LD A
		ADDI 1
		STO A

FIM: HLT           