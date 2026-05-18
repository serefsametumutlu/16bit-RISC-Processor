`timescale 1ns / 1ps

module StoreForwardingUnit(
    input  wire [2:0] ex_rt,          // EX aşamasındaki instruction'ın Rt'si (SW kaynağı)
    input  wire [2:0] mem_dest_reg,    // MEM aşamasındaki instruction'ın hedef register'ı
    input  wire       mem_is_load,     // MEM aşamasındaki instruction LW mi?
    input  wire [15:0] mem_load_data,  // MEM aşamasından çıkan load verisi
    input  wire [15:0] ex_store_data,  // Normalde store edilecek veri (forwarding sonrası ex_alu_in_b_temp)
    output wire [15:0] store_data_out
);

    assign store_data_out = (mem_is_load && (mem_dest_reg != 3'd0) && (mem_dest_reg == ex_rt))
                            ? mem_load_data
                            : ex_store_data;

endmodule
