`timescale 1ns / 1ps

module PipelineProcessor(
    input  wire clk,
    input  wire rst,
    output wire [15:0] dbg_pc,
    output wire [15:0] dbg_r1,
    output wire [15:0] dbg_r2,
    output wire [15:0] dbg_mem0,
    output wire [15:0] dbg_mem4
);

    // =========================================================================
    // 1. IF STAGE
    // =========================================================================
    reg  [15:0] pc;
    wire [15:0] pc_plus_2 = pc + 16'd2;
    wire [15:0] instruction_if;

    wire        stall;
    wire        branch_taken;
    wire [15:0] branch_target;

    // MEM stage read data
    wire [15:0] mem_read_data;

    // --- Control Hazard Unit outputs ---
    wire        pc_write_en;
    wire [15:0] pc_next;
    wire        if_id_write_en;
    wire        if_id_flush;
    wire        id_ex_flush;

    ControlHazardUnit chu (
        .stall(stall),
        .branch_taken(branch_taken),
        .pc_plus_2(pc_plus_2),
        .branch_target(branch_target),
        .pc_write_en(pc_write_en),
        .pc_next(pc_next),
        .if_id_write_en(if_id_write_en),
        .if_id_flush(if_id_flush),
        .id_ex_flush(id_ex_flush)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 16'd0;
        else if (pc_write_en) pc <= pc_next;
    end

    InstructionMemory inst_mem (.addr(pc), .data(instruction_if));

    // IF/ID pipeline reg + VALID bit
    reg [15:0] if_id_pc;
    reg [15:0] if_id_inst;
    reg        if_id_valid;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            if_id_pc    <= 16'd0;
            if_id_inst  <= 16'd0;
            if_id_valid <= 1'b0;
        end else if (if_id_flush) begin
            if_id_valid <= 1'b0;
        end else if (if_id_write_en) begin
            if_id_pc    <= pc;
            if_id_inst  <= instruction_if;
            if_id_valid <= 1'b1;
        end
    end

    // =========================================================================
    // 2. ID STAGE
    // =========================================================================
    wire id_valid = if_id_valid;

    wire [3:0] id_opcode = if_id_inst[15:12];
    wire [2:0] id_rs     = if_id_inst[11:9];
    wire [2:0] id_rt     = if_id_inst[8:6];
    wire [2:0] id_rd     = if_id_inst[5:3];

    // NEW: func field for R-type (inst[2:0])
    wire [2:0] id_func   = if_id_inst[2:0];

    // NEW: shift amount must be imm6 = inst[5:0] (same as your Python assembler)
    wire       id_is_shift = (id_opcode == 4'd10) || (id_opcode == 4'd11);
    wire [5:0] id_shamt6    = if_id_inst[5:0];

    // immediates
    // Python sim: imm6 is signed for addi/lw/sw/beq/bne
    wire [15:0] id_imm_signed   = {{10{if_id_inst[5]}}, if_id_inst[5:0]};
    wire [15:0] id_imm_unsigned = {10'b0, if_id_inst[5:0]};

    wire id_imm_is_signed = (id_opcode == 4'd5) || (id_opcode == 4'd6) || (id_opcode == 4'd7) ||
                            (id_opcode == 4'd8) || (id_opcode == 4'd9);

    wire [15:0] id_imm = (id_imm_is_signed) ? id_imm_signed : id_imm_unsigned;

    wire [15:0] id_jump_target  = {4'b0000, if_id_inst[11:0]};

    // Control Unit raw outputs
    wire        ctrl_reg_write, ctrl_mem_to_reg, ctrl_mem_write, ctrl_mem_read;
    wire        ctrl_alu_src, ctrl_branch, ctrl_jump, ctrl_jr;
    wire [1:0]  ctrl_reg_dst;

    ControlUnit cu (
        .opcode(id_opcode),
        .reg_write(ctrl_reg_write),
        .mem_to_reg(ctrl_mem_to_reg),
        .mem_write(ctrl_mem_write),
        .mem_read(ctrl_mem_read),
        .alu_src(ctrl_alu_src),
        .reg_dst(ctrl_reg_dst),
        .branch(ctrl_branch),
        .jump(ctrl_jump),
        .jr_type(ctrl_jr)
    );

    // Gate control signals with id_valid
    wire id_reg_write = ctrl_reg_write & id_valid;
    wire id_mem_to_reg= ctrl_mem_to_reg & id_valid;
    wire id_mem_write = ctrl_mem_write & id_valid;
    wire id_mem_read  = ctrl_mem_read  & id_valid;
    wire id_alu_src   = ctrl_alu_src   & id_valid;
    wire id_branch    = ctrl_branch    & id_valid;
    wire id_jump      = ctrl_jump      & id_valid;
    wire id_jr        = ctrl_jr        & id_valid;
    wire [1:0] id_reg_dst_ctrl = id_valid ? ctrl_reg_dst : 2'd0;

    // Register file (WB writes)
    wire        wb_reg_write;
    wire [2:0]  wb_dest_reg;
    wire [15:0] wb_write_data;

    wire [15:0] read_data1, read_data2;

    RegisterFile rf (
        .clk(clk), .rst(rst),
        .reg_write_en(wb_reg_write),
        .read_reg1(id_rs), .read_reg2(id_rt),
        .write_reg(wb_dest_reg), .write_data(wb_write_data),
        .read_data1(read_data1), .read_data2(read_data2)
    );

    // Hazard unit (stall only matters if ID valid)
    wire [2:0] id_rs_eff = id_valid ? id_rs : 3'd0;
    wire [2:0] id_rt_eff = id_valid ? id_rt : 3'd0;

    wire [2:0] id_ex_dest_reg_wire;
    reg        id_ex_mem_read;

    HazardUnit hu (
        .id_rs(id_rs_eff),
        .id_rt(id_rt_eff),
        .ex_dest_reg(id_ex_dest_reg_wire),
        .ex_mem_read(id_ex_mem_read),
        .stall(stall),
        .flush()
    );

    // ID/EX pipeline regs
    reg        id_ex_reg_write, id_ex_mem_to_reg, id_ex_mem_write, id_ex_alu_src;
    reg        id_ex_branch, id_ex_jump, id_ex_jr;
    reg [3:0]  id_ex_op;
    reg [2:0]  id_ex_rs, id_ex_rt, id_ex_rd_field;
    reg [15:0] id_ex_r1_data, id_ex_r2_data, id_ex_imm_val, id_ex_pc_curr;
    reg [1:0]  id_ex_reg_dst_ctrl;
    reg [15:0] id_ex_jump_addr;

    // NEW: carry func and shift amount (imm6)
    reg [2:0]  id_ex_func;
    reg [5:0]  id_ex_shamt6;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            id_ex_reg_write <= 0; id_ex_mem_to_reg <= 0; id_ex_mem_write <= 0; id_ex_mem_read <= 0;
            id_ex_alu_src   <= 0; id_ex_branch     <= 0; id_ex_jump      <= 0; id_ex_jr       <= 0;

            id_ex_op <= 0;
            id_ex_rs <= 0; id_ex_rt <= 0; id_ex_rd_field <= 0;
            id_ex_r1_data <= 0; id_ex_r2_data <= 0; id_ex_imm_val <= 0; id_ex_pc_curr <= 0;
            id_ex_reg_dst_ctrl <= 0;
            id_ex_jump_addr <= 0;

            id_ex_func   <= 0;
            id_ex_shamt6 <= 0;

        end else if (stall || id_ex_flush) begin
            // Bubble: only control signals (and make func/shamt harmless)
            id_ex_reg_write <= 0; id_ex_mem_to_reg <= 0; id_ex_mem_write <= 0; id_ex_mem_read <= 0;
            id_ex_alu_src   <= 0; id_ex_branch     <= 0; id_ex_jump      <= 0; id_ex_jr       <= 0;

            id_ex_func   <= 0;
            id_ex_shamt6 <= 0;

        end else begin
            id_ex_op <= id_opcode;

            id_ex_reg_write <= id_reg_write;
            id_ex_mem_to_reg<= id_mem_to_reg;
            id_ex_mem_write <= id_mem_write;
            id_ex_mem_read  <= id_mem_read;
            id_ex_alu_src   <= id_alu_src;
            id_ex_reg_dst_ctrl <= id_reg_dst_ctrl;
            id_ex_branch    <= id_branch;
            id_ex_jump      <= id_jump;
            id_ex_jr        <= id_jr;

            id_ex_pc_curr   <= if_id_pc;
            id_ex_r1_data   <= read_data1;
            id_ex_r2_data   <= read_data2;
            id_ex_imm_val   <= id_imm;
            id_ex_jump_addr <= id_jump_target;
            id_ex_rs        <= id_rs;
            id_ex_rt        <= id_rt;
            id_ex_rd_field  <= id_rd;

            // NEW
            id_ex_func   <= id_func;
            id_ex_shamt6 <= (id_is_shift ? id_shamt6 : 6'd0);
        end
    end

    // =========================================================================
    // 3. EX STAGE
    // =========================================================================
    reg [2:0] ex_dest_reg_logic;
    always @(*) begin
        case (id_ex_reg_dst_ctrl)
            2'd0: ex_dest_reg_logic = id_ex_rd_field;
            2'd1: ex_dest_reg_logic = id_ex_rt;
            2'd2: ex_dest_reg_logic = 3'd7;
            default: ex_dest_reg_logic = 3'd0;
        endcase
    end
    assign id_ex_dest_reg_wire = ex_dest_reg_logic;

    // Forwarding (EX operands)
    wire [1:0] fwd_a, fwd_b;
    wire [15:0] ex_alu_in_a, ex_alu_in_b_temp;

    wire        ex_mem_reg_write_wire;
    wire [2:0]  ex_mem_dest_reg;
    wire [15:0] ex_mem_alu_out;

    ForwardingUnit fu (
        .ex_rs(id_ex_rs), .ex_rt(id_ex_rt),
        .mem_dest_reg(ex_mem_dest_reg), .mem_reg_write(ex_mem_reg_write_wire),
        .wb_dest_reg(wb_dest_reg), .wb_reg_write(wb_reg_write),
        .forward_a(fwd_a), .forward_b(fwd_b)
    );

    assign ex_alu_in_a = (fwd_a == 2'b10) ? ex_mem_alu_out :
                         (fwd_a == 2'b01) ? wb_write_data :
                         id_ex_r1_data;

    assign ex_alu_in_b_temp = (fwd_b == 2'b10) ? ex_mem_alu_out :
                              (fwd_b == 2'b01) ? wb_write_data :
                              id_ex_r2_data;

    wire [15:0] ex_alu_in_b = (id_ex_alu_src) ? id_ex_imm_val : ex_alu_in_b_temp;

    // NEW: ALU control selection
    // If opcode==0 (R-type), operation is decided by func (3-bit)
    // else ALU op is opcode (as before)
    wire [3:0] ex_alu_ctrl = (id_ex_op == 4'd0) ? {1'b0, id_ex_func} : id_ex_op;

    wire [15:0] alu_result;
    wire        zero_flag;

    ALU alu_inst (
        .operand1(ex_alu_in_a),
        .operand2(ex_alu_in_b),
        .alu_op(ex_alu_ctrl),
        .shamt(id_ex_shamt6),     // IMPORTANT: 6-bit shift amount
        .result(alu_result),
        .zero(zero_flag)
    );

    // Branch/Jumps resolved in EX
    reg branch_cond;
    always @(*) begin
        case(id_ex_op)
            4'd8: branch_cond =  zero_flag;  // BEQ
            4'd9: branch_cond = ~zero_flag;  // BNE
            default: branch_cond = 1'b0;
        endcase
    end

    wire [15:0] branch_addr_calc = id_ex_pc_curr + 16'd2 + (id_ex_imm_val << 1);

    assign branch_taken  = (id_ex_branch && branch_cond) || id_ex_jump;

    assign branch_target = (id_ex_jr) ? ex_alu_in_a :
                           (id_ex_jump && !id_ex_jr) ? id_ex_jump_addr :
                           branch_addr_calc;

    wire [15:0] final_ex_result = (id_ex_op == 4'd13) ? (id_ex_pc_curr + 16'd2) : alu_result;

    // EX/MEM pipeline regs
    reg        ex_mem_reg_write, ex_mem_mem_to_reg, ex_mem_mem_write, ex_mem_read_ctrl;
    reg [15:0] ex_mem_alu_res;
    reg [15:0] ex_mem_write_data;
    reg [2:0]  ex_mem_dest;

    assign ex_mem_reg_write_wire = ex_mem_reg_write;
    assign ex_mem_dest_reg       = ex_mem_dest;
    assign ex_mem_alu_out        = ex_mem_alu_res;

    // STORE DATA forwarding
    wire [15:0] store_data_fwd =
        (ex_mem_reg_write_wire && (ex_mem_dest_reg != 3'd0) &&
         (ex_mem_dest_reg == id_ex_rt) && !ex_mem_mem_to_reg)
            ? ex_mem_alu_out :
        (wb_reg_write && (wb_dest_reg != 3'd0) && (wb_dest_reg == id_ex_rt))
            ? wb_write_data :
          id_ex_r2_data;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ex_mem_reg_write <= 0; ex_mem_mem_to_reg <= 0; ex_mem_mem_write <= 0; ex_mem_read_ctrl <= 0;
            ex_mem_alu_res   <= 0; ex_mem_write_data <= 0; ex_mem_dest <= 0;
        end else begin
            ex_mem_reg_write <= id_ex_reg_write;
            ex_mem_mem_to_reg<= id_ex_mem_to_reg;
            ex_mem_mem_write <= id_ex_mem_write;
            ex_mem_read_ctrl <= id_ex_mem_read;

            ex_mem_alu_res   <= final_ex_result;
            ex_mem_write_data<= store_data_fwd;
            ex_mem_dest      <= ex_dest_reg_logic;
        end
    end

    // =========================================================================
    // 4. MEM STAGE
    // =========================================================================
    DataMemory dm (
        .clk(clk),
        .mem_write(ex_mem_mem_write),
        .mem_read(ex_mem_read_ctrl),
        .addr(ex_mem_alu_res),
        .write_data(ex_mem_write_data),
        .read_data(mem_read_data)
    );

    // MEM/WB pipeline regs
    reg        wb_mem_to_reg_reg, wb_reg_write_reg;
    reg [15:0] wb_mem_data, wb_alu_res;
    reg [2:0]  wb_dest;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wb_reg_write_reg <= 0;
            wb_mem_to_reg_reg<= 0;
            wb_mem_data <= 0; wb_alu_res <= 0; wb_dest <= 0;
        end else begin
            wb_reg_write_reg <= ex_mem_reg_write;
            wb_mem_to_reg_reg<= ex_mem_mem_to_reg;

            wb_mem_data <= mem_read_data;   
            wb_alu_res  <= ex_mem_alu_res;
            wb_dest     <= ex_mem_dest;
        end
    end

    // =========================================================================
    // 5. WB STAGE
    // =========================================================================
    assign wb_reg_write  = wb_reg_write_reg;
    assign wb_dest_reg   = wb_dest;
    assign wb_write_data = (wb_mem_to_reg_reg) ? wb_mem_data : wb_alu_res;

    assign dbg_pc   = pc;

    // RegisterFile içindeki registers array'ine hiyerarşik erişim:
    assign dbg_r1   = rf.registers[1];
    assign dbg_r2   = rf.registers[2];

    // DataMemory içindeki memory array'ine erişim:
    assign dbg_mem0 = dm.memory[0];
    assign dbg_mem4 = dm.memory[2]; // 4 byte => index 2 (addr[9:1])

endmodule
