if (a == b)
  a = a + 1;
else if (a > b)
  a = a + 2;
else if  (a < b)
  a = a + 3;


.data
       A : 0
       B : 1
.text
        LD    A
        SUB   B
        BEQ   IGUAL       ; Se caso são iguais
        BGT   MAIOR       ; Se (A-B) > 0, portanto A > B
        BLT   MENOR       ; Se (A - B) < 0 portanto  B > A
        JMP   FIM

IGUAL:  LD    A
        ADDI  1
        STO   A
        JMP   FIM

MAIOR:  LD    A
        ADDI  2
        STO   A
        JMP   FIM

MENOR:  LD    A
        ADDI  3
        STO   A
        JMP FIM

FIM:    HLT