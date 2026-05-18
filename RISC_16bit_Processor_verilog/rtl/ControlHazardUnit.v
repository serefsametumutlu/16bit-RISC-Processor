`timescale 1ns / 1ps

module ControlHazardUnit(
    input  wire        stall,
    input  wire        branch_taken,
    input  wire [15:0] pc_plus_2,
    input  wire [15:0] branch_target,

    output wire        pc_write_en,
    output wire [15:0] pc_next,
    output wire        if_id_write_en,
    output wire        if_id_flush,
    output wire        id_ex_flush
);

    // Next PC selection
    assign pc_next = branch_taken ? branch_target : pc_plus_2;

    // Branch/jump alınırsa PC her türlü güncellensin (stall override)
    assign pc_write_en = branch_taken ? 1'b1 : ~stall;

    // IF/ID yazma: stall yoksa yaz. (Branch alınırsa IF/ID flush zaten var.)
    assign if_id_write_en = ~stall;

    // Flush/bubble
    assign if_id_flush = branch_taken;
    assign id_ex_flush = branch_taken;

endmodule
