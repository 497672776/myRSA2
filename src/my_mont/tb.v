`timescale 1ns / 1ps
module tb;
    parameter n = 7'd79, n_bit = 7, logr = 3, p = 3'd1;
    // parameter n = 7'd79, n_bit = 7, logr = 4, p = 4'd1;
    // parameter n = 7'd79, n_bit = 7, logr = 5, p = 5'd17;
    reg clk, rst_n;
    reg [n_bit-1:0] x, y;
    reg start;
    wire [n_bit-1:0] z;
    wire done;

    //生成始时钟
    parameter CLK_PERIOD = 10;
    initial begin
        clk = 0;
        forever
            clk = #(CLK_PERIOD / 2) ~clk;
    end

    /****************** 开始 ADD module inst ******************/
    mont #(
             .n_bit(n_bit),
             .logr (logr),
             .p    (p),
             .n    (n)
         ) inst_mont (
             .x    (x),
             .y    (y),
             .clk  (clk),
             .rst_n(rst_n),
             .start(start),
             .z    (z),
             .done (done)
         );
    /****************** 结束 END module inst ******************/

    initial begin
        $dumpfile("wave.lxt2");
        $dumpvars(0, tb);  //dumpvars(深度, 实例化模块1, 实例化模块2, .....)
    end

    initial begin
        start = 0;

        rst_n = 1;
        #(CLK_PERIOD) rst_n = 0;
        #(CLK_PERIOD) rst_n = 1;

        #(CLK_PERIOD);
        start = 0;
        x = 7'd17;
        y = 7'd26;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        #(CLK_PERIOD);
        start = 0;
        x = 7'd20;
        y = 7'd28;
        #(CLK_PERIOD);
        start = 1;
        wait (done);

        repeat (100) @(posedge clk) begin
        end

        $display("运行结束！");
        $dumpflush;
        $finish;
        $stop;
    end
endmodule

// z = 0x00000000000009A5FFFFFFFFFFFFF65A0000000000000000
// z = ty = 0x0000000000000000000000000000000B000000000000000B
// z = e1 = 0x000000000000000000000000000000010000000000000001
// z = e2 = 0x0000000000000000000000000000000B000000000000000B
