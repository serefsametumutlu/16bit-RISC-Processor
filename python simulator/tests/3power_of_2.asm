
    ADDI R1, R0, 1
    ADDI R2, R0, 0
    ADDI R3, R0, 10
    ADDI R4, R0, 0

LOOP:
    ADD R5, R2, R2
    
    ADD R6, R4, R5
    SW R1, 0, R6
    
    SLL R1, R1, 1
    
    ADDI R2, R2, 1
    
    SLT R7, R2, R3
    BNE R7, R0, LOOP
    
END:
    NOP
