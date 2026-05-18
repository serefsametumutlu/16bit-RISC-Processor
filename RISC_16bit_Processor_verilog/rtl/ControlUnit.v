`timescale 1ns / 1ps

module ControlUnit (
    input  [3:0] opcode,
    output reg   reg_write,
    output reg   mem_to_reg,
    output reg   mem_write,
    output reg   mem_read,
    output reg   alu_src,
    output reg [1:0] reg_dst,  // 0:Rd, 1:Rt, 2:R7
    output reg   branch,
    output reg   jump,
    output reg   jr_type
);

    always @(*) begin
        // defaults
        reg_write = 0; mem_to_reg = 0; mem_write = 0; mem_read = 0;
        alu_src   = 0; reg_dst    = 0; branch    = 0; jump     = 0; jr_type = 0;

        case(opcode)

            // =========================
            // R-TYPE (opcode=0 only)
            // func field (inst[2:0]) decides operation in EX/ALU control
            // =========================
            4'd0: begin
                reg_write = 1;
                reg_dst   = 0;   // Rd (bits 5:3)
                // alu_src stays 0 (use register operands)
            end

            // =========================
            // I-TYPE
            // =========================
            4'd5: begin // ADDI
                reg_write = 1;
                alu_src   = 1;   // use imm
                reg_dst   = 1;   // Rt (bits 8:6)
            end

            4'd6: begin // LW
                reg_write  = 1;
                mem_to_reg = 1;
                mem_read   = 1;
                alu_src    = 1;  // base + offset
                reg_dst    = 1;  // Rt
            end

            4'd7: begin // SW
                mem_write = 1;
                alu_src   = 1;   // base + offset
            end

            // =========================
            // BRANCH (uses ALU compare in EX)
            // =========================
            4'd8, 4'd9: begin // BEQ, BNE
                branch = 1;
                alu_src = 0;
            end

            // =========================
            // SHIFT (dest in Rt field in your design)
            // =========================
            4'd10, 4'd11: begin // SLL, SRL
                reg_write = 1;
                alu_src   = 1;   // use shift amount/immediate path
                reg_dst   = 1;   // Rt (bits 8:6) is destination in this ISA
            end

            // =========================
            // JUMPS
            // =========================
            4'd12: begin // J
                jump = 1;
            end

            4'd13: begin // JAL
                jump      = 1;
                reg_write = 1;
                reg_dst   = 2;   // R7
            end

            4'd14: begin // JR
                jump    = 1;
                jr_type = 1;
            end

            // =========================
            // NOP
            // =========================
            4'd15: begin
                // Do nothing (all zeros)
            end

            default: begin
                // Do nothing
            end

        endcase
    end
endmodule
