# --------------------------------------------------------
# --- COMPLEX TEST: Function Calls & Jumps ---
# Scenario:
# 1. Load values R1=10 and R2=20.
# 2. Jump to the 'Addition Function' at address 12 using JAL.
# 3. The function will compute R1+R2, store the result in R3, and return (JR).
# 4. After returning, shift and perform logical operations on the result.
# 5. Write the result to memory.
# --------------------------------------------------------

# 0x00: Setup
addi r1, r0, 10    # R1 = 10
addi r2, r0, 20    # R2 = 20

# 0x04: Function Call
jal 12             # Jump to address 12 and save return address (PC+2 = 6) into R7.

# 0x06: Return Point (Function returns here)
sll r4, r3, 1      # R4 = R3 << 1 (30 << 1 = 60)
srl r5, r4, 2      # R5 = R4 >> 2 (60 >> 2 = 15)

# 0x0A: Jump to skip subroutine code
j 16               # Jump to address 16 to avoid re-running function code.

# --- SUBROUTINE (Address 12) ---
# 0x0C:
add r3, r1, r2     # R3 = 10 + 20 = 30
# 0x0E:
jr r7              # Return to the address stored in R7 (0x06).

# --- FINAL SECTION (Address 16) ---
# 0x10: Comparison and Logic
slt r6, r5, r2     # Is 15 < 20? Yes → R6 = 1
or  r7, r6, r1     # 1 OR 10 (1010) = 11 (1011) → R7 = 11

# 0x14: Branch Test
bne r6, r0, 1      # If 1 != 0, skip the next instruction
addi r7, r0, 99    # THIS INSTRUCTION SHOULD BE SKIPPED (Pipeline flush)

# 0x18: Memory Write
sw r7, 4(r0)       # Mem[4] = 11
lw r1, 4(r0)       # R1 = 11 (Verification)


# --------------------------------------------------------
# VIVADO ICIN BINARY KODLARI
# --------------------------------------------------------
# 0101000001001010
# 0101000010010100
# 1101000000001100
# 1010011100000001
# 1011100101000010
# 1100000000010000
# 0000001010011000
# 1110111000000000
# 0100101010110000
# 0011110001111000
# 1001110000000001
# 0101000111100011
# 0111000111000100
# 0110000001000100


# --------------------------------------------------------
# BEKLENEN SONUCLAR (Registers)
# --------------------------------------------------------
# R1: 000b (11)
# R2: 0014 (20)
# R3: 001e (30)
# R4: 003c (60)
# R5: 000f (15)
# R6: 0001 (1)
# R7: 000b (11)

# --------------------------------------------------------
# BEKLENEN SONUCLAR (Memory - Byte Address)
# --------------------------------------------------------
# mem[4] = 000b (11)
