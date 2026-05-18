`timescale 1ns / 1ps

module cpu_top(
    input  wire clk,
    input  wire rst,
    output wire [15:0] dbg_pc,
    output wire [15:0] dbg_r1,
    output wire [15:0] dbg_r2,
    output wire [15:0] dbg_mem0,
    output wire [15:0] dbg_mem4
);

    PipelineProcessor uut (
        .clk(clk),
        .rst(rst),
        .dbg_pc(dbg_pc),
        .dbg_r1(dbg_r1),
        .dbg_r2(dbg_r2),
        .dbg_mem0(dbg_mem0),
        .dbg_mem4(dbg_mem4)
    );

endmodule
