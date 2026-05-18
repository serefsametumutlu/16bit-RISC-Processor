addi r1, r0, 5
addi r2, r0, 3
add  r3, r1, r2
sw   r3, 0(r0)
lw   r4, 0(r0)
add  r5, r4, r1
sll  r5, r5, 1
sub  r6, r5, r2
beq  r6, r0, 1
addi r6, r6, 1
bne  r6, r0, 1
addi r1, r0, 0
jal  28
j    36
addi r2, r2, 2
jr   r7
nop
nop
sw   r2, 2(r0)
nop
j    40

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Registers)
# --------------------------------------------------------
# R1: 0005 (5)    # BNE doğruysa ROM[11] (addi r1,0) atlanır, R1 5 kalır
# R2: 0005 (5)    # Subroutine'de +2 yapılır (3->5)
# R3: 0008 (8)    # 5 + 3
# R4: 0008 (8)    # MEM[0]'dan yüklenir
# R5: 001A (26)   # (MEM[0]=8) + 5 = 13, sonra <<1 = 26
# R6: 0018 (24)   # 26 - 3 = 23, sonra +1 = 24
# R7: 001A (26) Dönüş adresi (PC+2)  # JAL dönüş adresini tutar

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Memory - word)
# --------------------------------------------------------
# Mem[0] = 0008 (8)   # SW r3,0(r0)
# Mem[2] = 0005 (5)   # End bölümünde SW r2,2(r0) (JAL/JR çalıştığının kanıtı)
