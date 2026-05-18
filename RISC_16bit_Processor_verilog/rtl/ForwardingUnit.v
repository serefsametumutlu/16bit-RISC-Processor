`timescale 1ns / 1ps

module ForwardingUnit(
    input [2:0] ex_rs,
    input [2:0] ex_rt,
    input [2:0] mem_dest_reg,
    input mem_reg_write,
    input [2:0] wb_dest_reg,
    input wb_reg_write,
    output reg [1:0] forward_a,
    output reg [1:0] forward_b
);
    always @(*) begin
        forward_a = 0; forward_b = 0;

        if (mem_reg_write && (mem_dest_reg != 0) && (mem_dest_reg == ex_rs)) forward_a = 2'b10;
        else if (wb_reg_write && (wb_dest_reg != 0) && (wb_dest_reg == ex_rs)) forward_a = 2'b01;

        if (mem_reg_write && (mem_dest_reg != 0) && (mem_dest_reg == ex_rt)) forward_b = 2'b10;
        else if (wb_reg_write && (wb_dest_reg != 0) && (wb_dest_reg == ex_rt)) forward_b = 2'b01;
    end
endmodule