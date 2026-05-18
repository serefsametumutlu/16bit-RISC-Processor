`timescale 1ns / 1ps

module DataMemory (
    input clk,
    input mem_write,
    input mem_read,
    input [15:0] addr,
    input [15:0] write_data,
    output reg [15:0] read_data
);
    // 256 kelimelik hafıza
    reg [15:0] memory [0:255];
    integer i;

    // --- OKUMA İŞLEMİ (ASENKRON) ---
    // addr[9:1] kullanımı MIPS Byte Addressing için doğrudur.
    // Address 5 gelir -> Index 2 okunur.
    always @(*) begin
        if (mem_read) 
            read_data = memory[addr[9:1]];
        else 
            read_data = 16'd0;
    end

    // --- YAZMA İŞLEMİ (SENKRON) ---
    always @(posedge clk) begin
        if (mem_write) begin
            memory[addr[9:1]] <= write_data;
            // Hata ayıklama için konsola yazdırır:
            // $display("Memory Write: Addr=%d (Index=%d) Data=%h", addr, addr[9:1], write_data);
        end
    end

    // --- BAŞLATMA (INITIALIZATION) ---
    // Simülasyonun başında hafızayı temizle ki 'X' hatası alma.
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 16'd0;
        end
    end

endmodule