
; Faça um código assembly para somar as constantes 0x16, 25, 042 e armazenar 
; o resultado em R2. A soma tem que ser realizada pelo MCU.
start:
    LDI     R16, 0x16       ; R16 = 22   (0x16 hexadecimal)
    LDI     R17, 25         ; R17 = 25   (decimal)
    LDI     R18, 0x22       ; R18 = 34   (042 octal = 0x22 hex)

    ADD     R16, R17        ; R16 = R16 + R17 = 47
    ADD     R16, R18        ; R16 = R16 + R18 = 81 (0x51)
    MOV     R2, R16         ; R2 = resultado final = 81 (0x51)