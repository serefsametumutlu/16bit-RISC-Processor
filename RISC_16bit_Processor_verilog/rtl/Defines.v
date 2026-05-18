`timescale 1ns / 1ps

// Opcodes
`define OP_RTYPE 4'd0
`define OP_ADDI  4'd5
`define OP_LW    4'd6
`define OP_SW    4'd7
`define OP_BEQ   4'd8
`define OP_BNE   4'd9
`define OP_SLL   4'd10
`define OP_SRL   4'd11
`define OP_J     4'd12
`define OP_JAL   4'd13
`define OP_JR    4'd14
`define OP_NOP   4'd15

// R-type FUNC codes (inst[2:0])
`define F_ADD 3'd0
`define F_SUB 3'd1
`define F_AND 3'd2
`define F_OR  3'd3
`define F_SLT 3'd4
