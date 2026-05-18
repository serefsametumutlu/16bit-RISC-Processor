`timescale 1ns / 1ps

module HazardUnit(
    input [2:0] id_rs,
    input [2:0] id_rt,
    input [2:0] ex_dest_reg,
    input ex_mem_read,
    output reg stall,
    output reg flush
);
    always @(*) begin
        stall = 0; flush = 0;
        if (ex_mem_read && (ex_dest_reg != 0) && ((ex_dest_reg == id_rs) || (ex_dest_reg == id_rt))) begin
            stall = 1;
        end
    end
endmodule