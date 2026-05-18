addi r1, r0, 4
addi r2, r0, 6
add  r3, r1, r2
sw   r3, 0(r0)
lw   r3, 0(r0)
add  r4, r3, r3
j    12

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Registers)
# --------------------------------------------------------
# R0: 0000 (0)
# R1: 0004 (4)
# R2: 0006 (6)
# R3: 000A (10)
# R4: 0014 (20)
# R5: 0000
# R6: 0000
# R7: 0000

# --------------------------------------------------------
# BEKLENEN SONUÇLAR (Memory - word)
# --------------------------------------------------------
# Mem[0] = 000A (10)

# --------------------------------------------------------
# AÇIKLAMA
# --------------------------------------------------------
# lw r3, 0(r0) sonrasında gelen "add r4, r3, r3" komutu,
# load-use hazard oluşturur.
# Bu nedenle pipeline 1 cycle stall uygular.
# Stall sonrası forwarding ile doğru değer kullanılır.
#
# Program sonunda "j 12" ile sonsuz döngüye girilir,
# bu nedenle simülasyon cycle limiti dolana kadar çalışmaya devam eder.
