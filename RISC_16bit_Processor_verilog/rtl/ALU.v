`timescale 1ns / 1ps

module ALU (
    input signed [15:0] operand1,
    input signed [15:0] operand2,
    input [3:0] alu_op,
    input [5:0] shamt,
    output reg [15:0] result,
    output reg zero
);
    always @(*) begin
        result = 16'd0;
        case (alu_op)
            4'd0: result = operand1 + operand2; // ADD
            4'd1: result = operand1 - operand2; // SUB
            4'd2: result = operand1 & operand2; // AND
            4'd3: result = operand1 | operand2; // OR
            4'd4: result = (operand1 < operand2) ? 16'd1 : 16'd0; // SLT
            4'd5: result = operand1 + operand2; // ADDI
            4'd6: result = operand1 + operand2; // LW
            4'd7: result = operand1 + operand2; // SW
            4'd8, 4'd9: result = 0; // Branch
            4'd10: result = operand1 << shamt;  // SLL
            4'd11: result = $unsigned(operand1) >> shamt;  // SRL
            
            // Gelen immediate (operand2) değerini 10 bit sola kaydır.
            // Böylece 6 bitlik veri en başa geçer.
            4'd15: result = 16'd0; // NOP
            
            default: result = 16'd0;
        endcase
        zero = (operand1 == operand2) ? 1'b1 : 1'b0;
    end
endmodule