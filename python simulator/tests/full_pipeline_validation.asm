# --------------------------------------------------------
# Test: Complex Branch Operations
# --------------------------------------------------------
addi r1, r0, 10    # R1 = 10
addi r2, r0, 5     # R2 = 5
add r3, r1, r2     # R3 = 10 + 5 = 15
bne r2, r1, 1      # 5 != 10 (True) -> 1 satir atla (SKIP1'e git)
addi r4, r0, 30    # BU SATIR ATLANMALI (Calismayacak)
# SKIP1:
addi r4, r0, 1     # R4 = 1 (Branch buraya duser)
addi r5, r0, 5     # R5 = 5
bne r5, r2, 1      # 5 != 5 (False) -> Atlama yapma (Devam et)
addi r6, r0, 20    # R6 = 20 (Branch alinmadigi icin calisir)
# SKIP2:
addi r7, r0, 25    # R7 = 25

# --------------------------------------------------------
# VIVADO ICIN BINARY KODLARI
# --------------------------------------------------------
# 1. ADDI R1, 10
# 0101000001001010
# 2. ADDI R2, 5
# 0101000010000101
# 3. ADD R3, R1, R2
# 0000001010011000
# 4. BNE R2, R1, 1 (Offset=1 -> PC+1+1)
# 1001010001000001
# 5. ADDI R4, 30 (Atlanan satir)
# 0101000100011110
# 6. ADDI R4, 1
# 0101000100000001
# 7. ADDI R5, 5
# 0101000101000101
# 8. BNE R5, R2, 1 (Offset=1 -> PC+1+1)
# 1001101010000001
# 9. ADDI R6, 20
# 0101000110010100
# 10. ADDI R7, 25
# 0101000111011001

# --------------------------------------------------------
# BEKLENEN SONUCLAR (Registers)
# --------------------------------------------------------
# R1: 000a (10)
# R2: 0005 (5)
# R3: 000f (15)
# R4: 0001 (1)   <- 30 atlandi, 1 yazildi.
# R5: 0005 (5)
# R6: 0014 (20)  <- Branch alinmadigi icin calisti.
# R7: 0019 (25)