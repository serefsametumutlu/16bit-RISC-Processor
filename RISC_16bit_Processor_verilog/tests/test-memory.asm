# --------------------------------------------------------
# Test 3: Memory Operations
# NOT: Immediate alani 6-bit oldugu icin (Max 31),
# --------------------------------------------------------

addi r1, r0, 15    # R1 = 15 (Hex: 000f) - Yazilacak veri
addi r2, r0, 5     # R2 = 5  (Hex: 0005) - Adres
sw r1, 0(r2)       # Mem[5] = 15
lw r3, 0(r2)       # R3 = Mem[5] (15 olmali)

# --------------------------------------------------------
# VIVADO ICIN BINARY KODLARI (Kopyala -> machine_code.txt)
# --------------------------------------------------------
# 0101000001001111
# 0101000010000101
# 0111010001000000
# 0110010011000000

# --------------------------------------------------------
# BEKLENEN SONUCLAR (Registers)
# --------------------------------------------------------
# R1: 000f (15)
# R2: 0005 (5)
# R3: 000f (15)  <-- Eger bu geliyorsa SW ve LW kusursuz calisiyor demektir.