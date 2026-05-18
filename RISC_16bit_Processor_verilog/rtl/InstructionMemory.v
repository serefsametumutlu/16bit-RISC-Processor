`timescale 1ns / 1ps

module InstructionMemory (
    input  wire [15:0] addr,
    output reg  [15:0] data
);
    // 256 word instruction memory
    (* rom_style = "block" *) reg [15:0] memory [0:255];
    integer i;

`ifndef SYNTHESIS
    initial begin
        // önce temizle
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 16'h0000;

        $display("IMEM: loading machine_code.txt ...");
        // Sim'de çalışır
        $readmemb("machine_code.txt", memory);
        $display("IMEM: memory[0]=%b memory[1]=%b memory[2]=%b memory[3]=%b",
                 memory[0], memory[1], memory[2], memory[3]);
    end
`else
    // Synthesis için deterministic init: 0'la (ROM boş kalmasın)
    initial begin
        for (i = 0; i < 256; i = i + 1)
            memory[i] = 16'h0000;
    end
`endif

    always @(*) begin
        // byte address -> word index
        data = memory[addr[9:1]];
    end
endmodule
