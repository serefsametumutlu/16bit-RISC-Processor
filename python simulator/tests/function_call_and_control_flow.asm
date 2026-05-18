# --- COMPLEX TEST: Function Calls & Jumps ---
# Scenario:
# 1. Load values R1=10 and R2=20.
# 2. Jump to the 'Addition Function' at address 12 using JAL.
# 3. The function will compute R1+R2, store the result in R3, and return (JR).
# 4. After returning, shift and perform logical operations on the result.
# 5. Write the result to memory.

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
addi r7, r0, -29    # THIS INSTRUCTION SHOULD BE SKIPPED (Pipeline flush)

# 0x18: Memory Write
sw r7, 4(r0)      # Mem[4] = 11
lw r1, 4(r0)        # R1 = 11 (Verification)