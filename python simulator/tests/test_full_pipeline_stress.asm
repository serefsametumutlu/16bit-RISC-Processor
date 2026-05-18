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
# R0: 0000 (0)
# R1: 0005 (5)     # BNE alınırsa "addi r1,0" flush olmalı → R1 5 kalır
# R2: 0005 (5)     # Subroutine'de +2 (3->5)
# R3: 0008 (8)     # 5 + 3
# R4: 0008 (8)     # MEM[0]'dan okundu
# R5: 001A (26)    # (8+5)=13, sonra <<1 = 26
# R6: 0018 (24)    # (26-3)=23, sonra +1 = 24
# R7: 001A (26)    # JAL dönüş adresi = PC+2 = 24+2 = 26

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Memory - word)
# --------------------------------------------------------
# Mem[0] = 0008 (8)   # SW r3,0(r0)
# Mem[2] = 0005 (5)   # SW r2,2(r0) (JAL/JR'nin çalıştığının kanıtı)

# --------------------------------------------------------
# AÇIKLAMA (kısa)
# --------------------------------------------------------
# lw -> add hemen sonrası load-use hazard oluşturur → 1 cycle STALL beklenir.
# bne true olduğunda bir sonraki instruction flush olur (addi r1,0 çalışmamalı).
# Program sonunda j 40 ile sonsuz döngü vardır → simülasyon cycle limitine kadar devam eder.
