import sys
import os

# =============================================================================
# SETTINGS
# =============================================================================
MEMORY_SIZE = 512
REG_COUNT = 8


# Terminal çıktısını renklendirmek için
class Colors:
    HEADER = "\033[95m"
    BLUE = "\033[94m"
    CYAN = "\033[96m"
    GREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"


# Assembly satırını ve üretilen makine kodunu birlikte tutmak için
class AssembledInstruction:
    def __init__(self, machineCode, source):
        self.machineCode = machineCode
        self.source = source


# =============================================================================
# 1) ASSEMBLER & FILE READER
# =============================================================================
def load_assembly_file(filename):
    code_lines = []
    if not os.path.exists(filename):
        print(f"{Colors.FAIL}Error: {filename} not found!{Colors.ENDC}")
        return code_lines

    try:
        with open(filename, 'r') as f:
            for line in f:
                # Yorumları ve boş satırları temizle
                line = line.split("#")[0].strip()
                if line:
                    code_lines.append(line)
    except Exception as e:
        print(f"{Colors.FAIL}File read error: {e}{Colors.ENDC}")
    return code_lines


def parse_reg(r):
    # r3 → 3 dönüşümü
    return int(r.lower().replace("r", ""))


def strip_comment(s: str) -> str:
    return s.split("#")[0].strip()


def assemble_line(line):
    """
    Tek satırlık komutu makine koduna çevirir.
    Label çözümleme yapmaz.
    """
    clean_line = line.replace(",", " ").replace("(", " ").replace(")", " ").strip()
    parts = clean_line.split()
    if not parts:
        return None

    cmd = parts[0].lower()

    OP_RTYPE = 0
    FUNC = {"add": 0, "sub": 1, "and": 2, "or": 3, "slt": 4}

    opcodes = {
        "addi": 5, "lw": 6, "sw": 7,
        "beq": 8, "bne": 9,
        "sll": 10, "srl": 11,
        "j": 12, "jal": 13, "jr": 14,
        "nop": 15
    }

    if cmd in FUNC:
        opcode = OP_RTYPE
    else:
        opcode = opcodes.get(cmd, None)
        if opcode is None:
            return AssembledInstruction(0xFFFF, "nop")

    machine_code = 0

    try:
        # R-type: opcode + rs + rt + rd + func
        if cmd in FUNC:
            rd = parse_reg(parts[1])
            rs = parse_reg(parts[2])
            rt = parse_reg(parts[3])
            func = FUNC[cmd] & 0x7
            machine_code = (OP_RTYPE << 12) | (rs << 9) | (rt << 6) | (rd << 3) | func

        # I-type komutlar
        elif cmd in ["addi", "lw", "sw", "beq", "bne"]:
            if cmd in ["lw", "sw"]:
                rt = parse_reg(parts[1])
                imm = int(parts[2]) & 0x3F
                rs = parse_reg(parts[3])
                machine_code = (opcode << 12) | (rs << 9) | (rt << 6) | imm
            else:
                rt = parse_reg(parts[1])
                rs = parse_reg(parts[2])
                imm = int(parts[3]) & 0x3F
                machine_code = (opcode << 12) | (rs << 9) | (rt << 6) | imm

        # Shift işlemleri
        elif cmd in ["sll", "srl"]:
            rd = parse_reg(parts[1])
            rt = parse_reg(parts[2])
            shamt = int(parts[3]) & 0x3F
            machine_code = (opcode << 12) | (rt << 9) | (rd << 6) | shamt

        # Jump / JAL
        elif cmd in ["j", "jal"]:
            addr = int(parts[1]) & 0xFFF
            machine_code = (opcode << 12) | addr

        # JR
        elif cmd == "jr":
            rs = parse_reg(parts[1])
            machine_code = (opcode << 12) | (rs << 9)

        elif cmd == "nop":
            machine_code = 0xFFFF

    except:
        return AssembledInstruction(0xFFFF, "nop")

    return AssembledInstruction(machine_code, line)


def assemble_program_with_labels(lines: list[str]) -> list[AssembledInstruction]:
    """
    2-pass assembler:
    1) label adreslerini bulur
    2) gerçek makine kodunu üretir
    """
    labels = {}
    pc = 0
    cleaned = []

    # PASS 1 → label adresleri
    for raw in lines:
        line = strip_comment(raw)
        if not line:
            continue

        while ":" in line:
            left, right = line.split(":", 1)
            labels[left.strip().lower()] = pc
            line = right.strip()
            if not line:
                break

        if not line:
            continue

        cleaned.append(line)
        pc += 2

    # PASS 2 → instruction üretimi
    out = []
    pc = 0
    for line in cleaned:
        out.append(assemble_line_with_labels(line, labels, pc))
        pc += 2

    return out


def assemble_line_with_labels(line: str, labels: dict[str, int], pc: int) -> AssembledInstruction:
    # Label destekli tek satır çevirici
    clean_line = line.replace(",", " ").replace("(", " ").replace(")", " ").strip()
    parts = clean_line.split()
    if not parts:
        return AssembledInstruction(0xFFFF, "nop")

    cmd = parts[0].lower()

    OP_RTYPE = 0
    FUNC = {"add": 0, "sub": 1, "and": 2, "or": 3, "slt": 4}
    opcodes = {
        "addi": 5, "lw": 6, "sw": 7,
        "beq": 8, "bne": 9,
        "sll": 10, "srl": 11,
        "j": 12, "jal": 13, "jr": 14,
        "nop": 15
    }

    if cmd in FUNC:
        opcode = OP_RTYPE
    else:
        opcode = opcodes.get(cmd, None)
        if opcode is None:
            return AssembledInstruction(0xFFFF, "nop")

    try:
        machine_code = 0

        if cmd in FUNC:
            rd = parse_reg(parts[1])
            rs = parse_reg(parts[2])
            rt = parse_reg(parts[3])
            func = FUNC[cmd] & 0x7
            machine_code = (OP_RTYPE << 12) | (rs << 9) | (rt << 6) | (rd << 3) | func

        elif cmd in ["addi", "lw", "sw"]:
            if cmd in ["lw", "sw"]:
                rt = parse_reg(parts[1])
                imm = int(parts[2]) & 0x3F
                rs = parse_reg(parts[3])
            else:
                rt = parse_reg(parts[1])
                rs = parse_reg(parts[2])
                imm = int(parts[3]) & 0x3F
            machine_code = (opcode << 12) | (rs << 9) | (rt << 6) | imm

        elif cmd in ["beq", "bne"]:
            rs = parse_reg(parts[1])
            rt = parse_reg(parts[2])
            op3 = parts[3].lower()

            if op3.lstrip("-").isdigit():
                imm = int(op3) & 0x3F
            else:
                target = labels.get(op3, 0)
                imm = ((target - (pc + 2)) // 2) & 0x3F

            machine_code = (opcode << 12) | (rs << 9) | (rt << 6) | imm

        elif cmd in ["sll", "srl"]:
            rd = parse_reg(parts[1])
            rt = parse_reg(parts[2])
            shamt = int(parts[3]) & 0x3F
            machine_code = (opcode << 12) | (rt << 9) | (rd << 6) | shamt

        elif cmd in ["j", "jal"]:
            op1 = parts[1].lower()
            addr = int(op1) if op1.isdigit() else labels.get(op1, 0)
            machine_code = (opcode << 12) | (addr & 0xFFF)

        elif cmd == "jr":
            rs = parse_reg(parts[1])
            machine_code = (opcode << 12) | (rs << 9)

        elif cmd == "nop":
            machine_code = 0xFFFF

        return AssembledInstruction(machine_code, line)

    except:
        return AssembledInstruction(0xFFFF, "nop")


# =============================================================================
# 2) HARDWARE UNITS
# =============================================================================
class RegisterFile:
    # 8 adet register var, R0 her zaman 0 kalır
    def __init__(self):
        self.regs = [0] * REG_COUNT

    def read(self, r):
        return self.regs[r]

    def write(self, r, v):
        if r != 0:
            self.regs[r] = v & 0xFFFF

    def __str__(self):
        return str(self.regs)


class Memory:
    # Byte-addressed bellek, word erişimi 16-bit
    def __init__(self):
        self.data = [0] * MEMORY_SIZE

    def read_word(self, addr):
        if addr >= MEMORY_SIZE - 1:
            return 0
        return (self.data[addr] << 8) | self.data[addr + 1]

    def write_word(self, addr, val):
        if addr >= MEMORY_SIZE - 1:
            return
        self.data[addr] = (val >> 8) & 0xFF
        self.data[addr + 1] = val & 0xFF

    def get_dump(self, count):
        return [f"0x{self.read_word(i * 2):x}" for i in range(count)]


# =============================================================================
# 3) PROCESSOR (PIPELINE + TRACE)
# =============================================================================
class Processor:
    # Pipeline register’ları ve temel CPU durumu burada tutulur
    def __init__(self):
        self.pc = 0
        self.stall = False
        self.reg_file = RegisterFile()
        self.inst_mem = Memory()
        self.data_mem = Memory()
        self.cycle_count = 0
        self.program_map = {}

        self.if_id = {}
        self.id_ex = {}
        self.ex_mem = {}
        self.mem_wb = {}

        self.pipe_view = {"IF": "-", "ID": "-", "EX": "-", "MEM": "-", "WB": "-"}

    def load_program(self, code_tuples):
        # Program yüklenirken tüm pipeline temizlenir
        self.pc = 0
        self.stall = False
        self.cycle_count = 0
        self.program_map = {}
        self.if_id.clear()
        self.id_ex.clear()
        self.ex_mem.clear()
        self.mem_wb.clear()
        self.pipe_view = {"IF": "-", "ID": "-", "EX": "-", "MEM": "-", "WB": "-"}

        addr = 0
        for item in code_tuples:
            self.inst_mem.write_word(addr, item.machineCode)
            self.program_map[addr] = item.source
            addr += 2

    # ---------------- PIPELINE STAGES ----------------
    def write_back(self):
        # WB aşaması: register’a yazma burada olur
        self.pipe_view["WB"] = "-"
        if not self.mem_wb:
            return

        if self.mem_wb.get("Ctrl_RegWrite", False):
            self.reg_file.write(
                self.mem_wb.get("Dest_Reg", 0),
                self.mem_wb.get("Write_Data", 0)
            )
            self.pipe_view["WB"] = f"R{self.mem_wb.get('Dest_Reg')}={self.mem_wb.get('Write_Data')}"

    def memory_access(self):
        # MEM: load / store işlemleri
        self.pipe_view["MEM"] = "-"
        if not self.ex_mem:
            self.mem_wb.clear()
            return

        op = self.ex_mem.get("Opcode")
        res = self.ex_mem.get("ALU_Result")
        store_val = self.ex_mem.get("Store_Val")

        if op == 6:
            read_val = self.data_mem.read_word(res)
            self.pipe_view["MEM"] = f"Rd M[{res}]"
        elif op == 7:
            self.data_mem.write_word(res, store_val)
            self.pipe_view["MEM"] = f"Wr M[{res}]"
            read_val = 0
        else:
            read_val = res
            self.pipe_view["MEM"] = "Pass"

        self.mem_wb["Write_Data"] = read_val
        self.mem_wb["Dest_Reg"] = self.ex_mem.get("Dest_Reg")
        self.mem_wb["Ctrl_RegWrite"] = self.ex_mem.get("Ctrl_RegWrite")

    def execute(self):
        # EX: ALU hesapları + branch/jump kararları
        self.pipe_view["EX"] = "-"
        if not self.id_ex:
            self.ex_mem.clear()
            return

        op = self.id_ex.get("Opcode")
        func = self.id_ex.get("Func", 0)
        rs = self.id_ex.get("Rs")
        rt = self.id_ex.get("Rt")
        imm = self.id_ex.get("Imm")
        dest = self.id_ex.get("Dest")
        pc_curr = self.id_ex.get("PC_Current")

        val_rs = self.reg_file.read(rs)
        val_rt = self.reg_file.read(rt)

        # Forwarding (data hazard çözümü)
        fwd_info = ""
        if self.ex_mem and self.ex_mem.get("Ctrl_RegWrite", False):
            if self.ex_mem.get("Dest_Reg") == rs:
                val_rs = self.ex_mem.get("ALU_Result")
                fwd_info += " [Fwd-A]"
            if self.ex_mem.get("Dest_Reg") == rt:
                val_rt = self.ex_mem.get("ALU_Result")
                fwd_info += " [Fwd-B]"

        res = 0
        take_branch = False
        target = 0

        # Control Unit

        if op == 0:
            if func == 0: res = val_rs + val_rt
            elif func == 1: res = val_rs - val_rt
            elif func == 2: res = val_rs & val_rt
            elif func == 3: res = val_rs | val_rt
            elif func == 4: res = 1 if val_rs < val_rt else 0
        elif op == 5:
            res = val_rs + imm
        elif op == 6 or op == 7:
            res = val_rs + imm
        elif op == 8 and val_rs == val_rt:
            take_branch = True
            target = pc_curr + 2 + (imm * 2)
        elif op == 9 and val_rs != val_rt:
            take_branch = True
            target = pc_curr + 2 + (imm * 2)
        elif op == 10:
            res = val_rs << imm
        elif op == 11:
            res = (val_rs & 0xFFFF) >> imm
        elif op == 12:
            take_branch = True
            target = imm
        elif op == 13:
            take_branch = True
            target = imm
            res = pc_curr + 2
            dest = 7
        elif op == 14:
            take_branch = True
            target = val_rs

        if take_branch:
            self.pc = target
            self.if_id.clear()
            self.stall = False
            self.pipe_view["EX"] = "CONTROL HAZARD"
        else:
            self.pipe_view["EX"] = self.id_ex.get("Source", "") + fwd_info

        self.ex_mem["ALU_Result"] = res & 0xFFFF
        self.ex_mem["Store_Val"] = val_rt & 0xFFFF
        self.ex_mem["Dest_Reg"] = dest
        self.ex_mem["Opcode"] = op
        self.ex_mem["Ctrl_RegWrite"] = op in (0, 5, 6, 10, 11, 13)

    def decode(self):
        # ID: instruction çözümleme ve hazard kontrolü
        self.pipe_view["ID"] = "-"
        if self.stall:
            self.pipe_view["ID"] = "STALL"
            self.id_ex.clear()
            return

        if not self.if_id:
            self.id_ex.clear()
            return

        inst = self.if_id.get("Inst")
        if inst == 0xFFFF:
            self.id_ex.clear()
            self.pipe_view["ID"] = "NOP"
            return

        op = (inst >> 12) & 0xF
        rs = (inst >> 9) & 0x7
        rt = (inst >> 6) & 0x7
        rd = (inst >> 3) & 0x7
        func = inst & 0x7

        if op in (12, 13):
            imm = inst & 0xFFF
        else:
            imm = inst & 0x3F
            if imm > 31:
                imm -= 64

        if op == 0:
            dest = rd
        elif op == 13:
            dest = 7
        else:
            dest = rt

        source_code = self.program_map.get(self.if_id.get("PC_Current"), "Unknown")

        # load-use hazard kontrolü
        if self.id_ex and self.id_ex.get("Opcode") == 6:
            ex_dest = self.id_ex.get("Dest")
            if ex_dest != 0 and (ex_dest == rs or ex_dest == rt):
                self.stall = True
                self.pipe_view["ID"] = "HAZARD"
                self.id_ex.clear()
                return

        self.pipe_view["ID"] = source_code
        self.id_ex["Opcode"] = op
        self.id_ex["Func"] = func
        self.id_ex["Rs"] = rs
        self.id_ex["Rt"] = rt
        self.id_ex["Imm"] = imm
        self.id_ex["Dest"] = dest
        self.id_ex["PC_Current"] = self.if_id.get("PC_Current")
        self.id_ex["Source"] = source_code

    def fetch(self):
        # IF: instruction fetch + PC artışı
        self.pipe_view["IF"] = "-"
        if self.stall:
            self.pipe_view["IF"] = "STALL"
            self.stall = False
            return

        inst = self.inst_mem.read_word(self.pc)
        if inst != 0:
            self.pipe_view["IF"] = f"0x{inst:x}"
            self.if_id["Inst"] = inst
            self.if_id["PC_Current"] = self.pc
            self.pc += 2
        else:
            self.if_id.clear()
            self.pipe_view["IF"] = "END"

    def run_cycle(self):
        self.cycle_count += 1
        self.write_back()
        self.memory_access()
        self.execute()
        self.decode()
        self.fetch()

    def print_state(self):
        print(
            f"{Colors.BOLD}Cycle {self.cycle_count:<3}{Colors.ENDC} | "
            f"{Colors.CYAN}IF:{Colors.ENDC} {self.pipe_view['IF']:<8} | "
            f"{Colors.BLUE}ID:{Colors.ENDC} {self.pipe_view['ID']:<15} | "
            f"{Colors.GREEN}EX:{Colors.ENDC} {self.pipe_view['EX']:<20} | "
            f"{Colors.WARNING}MEM:{Colors.ENDC} {self.pipe_view['MEM']:<8} | "
            f"WB: {self.pipe_view['WB']:<8}"
        )


# =============================================================================
# 4) MAIN (CLI)
# =============================================================================
def main():
    # Programı çalıştıran ana kısım
    cpu = Processor()
    filename = "input.asm"
    print(f"{Colors.HEADER}=== 16-Bit RISC Simulator v3.0 (GUI Compatible) ==={Colors.ENDC}")
    print(f"Loading {filename}...")

    lines = load_assembly_file(filename)
    if not lines:
        return

    code_tuples = assemble_program_with_labels(lines)
    cpu.load_program(code_tuples)

    print("Program loaded successfully.")
    print("-" * 95)
    mode = input("Step-by-step mode? (y/n): ").strip().lower()
    print("-" * 95)
    print("CYC | IF       | ID              | EX                   | MEM      | WB")
    print("-" * 95)

    for _ in range(200):
        cpu.run_cycle()
        cpu.print_state()
        if mode == "y":
            input()

        if (
            cpu.pipe_view["IF"] == "END"
            and not cpu.id_ex
            and not cpu.ex_mem
            and not cpu.mem_wb
            and not cpu.stall
        ):
            break

    print("-" * 95)
    print(f"{Colors.HEADER}Final Register State:{Colors.ENDC}")
    print(cpu.reg_file)


if __name__ == "__main__":
    main()