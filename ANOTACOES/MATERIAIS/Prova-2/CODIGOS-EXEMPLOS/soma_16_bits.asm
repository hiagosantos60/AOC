.INCLUDE <m328Pdef.inc>

.DSEG
.ORG 0x0100
    

.CSEG
.ORG 0x0000
    
somar_16_bits:
    ; 0x12F5 + 0x0A1B em R17:R16, usando ADD/ADC. (esperado: 0x1D10)
    
    LDI R29, 0x12 ; HIGH 
    LDI R28, 0xF5 ; LOW
    
    LDI R17, 0x0A ; HIGH
    LDI R16, 0x1B ; LOW
    
    ADC R16, R28 ; HIGH
    ADC R17, R29 ; LOW
    
fim:
    rjmp fim                    