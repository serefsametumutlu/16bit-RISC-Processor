addi r1, r0, 5
addi r2, r0, 3
add  r3, r1, r2
sw   r3, 2(r0)
j    8

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Registers)
# --------------------------------------------------------
# R0: 0000 (0)
# R1: 0005 (5)
# R2: 0003 (3)
# R3: 0008 (8)
# R4: 0000
# R5: 0000
# R6: 0000
# R7: 0000

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Memory - word)
# --------------------------------------------------------
# Mem[2] = 0008 (8)

# --------------------------------------------------------
# AÇIKLAMA
# --------------------------------------------------------
# Program, J komutu ile kendi üzerine dönen sonsuz döngü içerir.
# Bu nedenle simülasyon cycle sınırına kadar çalışmaya devam eder.
# Ama register ve bellek değerleri sabit kalır.
