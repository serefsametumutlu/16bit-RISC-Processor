`timescale 1ns / 1ps

module TestBench();
    reg clk;
    reg rst;

    PipelineProcessor uut (.clk(clk), .rst(rst));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        #20 rst = 0;

        // programın bitmesi için yeterli süre
        #800;

        // 4(r0) => addr=4 => index = 4>>1 = 2
        if (uut.dm.memory[2] !== 16'h002A) begin
            $display("FAIL: mem[4] (index2) expected 0x002A, got %h", uut.dm.memory[2]);
            $fatal;
        end

        $display("PASS: lw->sw forwarding test OK");
        $finish;
    end
endmodule
