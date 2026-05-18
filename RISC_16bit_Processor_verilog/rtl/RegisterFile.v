`timescale 1ns / 1ps

module RegisterFile (
    input clk,
    input rst,
    input reg_write_en,
    input [2:0] read_reg1,
    input [2:0] read_reg2,
    input [2:0] write_reg,
    input [15:0] write_data,
    output [15:0] read_data1,
    output [15:0] read_data2
);
    reg [15:0] registers [0:7];
    integer i;

    // --- INTERNAL FORWARDING ---
    // Eğer okunan adres (read_reg), şu an yazılan adres (write_reg) ile aynıysa 
    // ve yazma izni (reg_write_en) varsa, direkt write_data'yı çıkışa ver.
    // Aksi takdirde diziden (registers) oku.
    
    assign read_data1 = (read_reg1 == 3'd0) ? 16'd0 :
                        ((read_reg1 == write_reg) && reg_write_en) ? write_data : 
                        registers[read_reg1];

    assign read_data2 = (read_reg2 == 3'd0) ? 16'd0 :
                        ((read_reg2 == write_reg) && reg_write_en) ? write_data : 
                        registers[read_reg2];
                          
    // --------------------------------------------

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) registers[i] <= 16'd0;
        end else if (reg_write_en && write_reg != 3'd0) begin
            registers[write_reg] <= write_data;
        end
    end
endmodule