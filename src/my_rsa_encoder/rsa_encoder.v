`timescale 1ns / 1ps

module rsa_encoder (
        input clk,
        input rst_n,
        input start,
        input [k-1:0] data_in,
        output [k-1:0] data_out,
        output done
    );


    // ---------------------------------- 实现功能 ----------------------------------
    // 外参
    // -----------------------------------------------------------------------------
    parameter n = 7'd79;
    parameter n_bit = 7;
    parameter logr = 3;
    parameter p =  3'd1;
    parameter Rmodn = 7'd49;
    parameter R2modn = 7'd31;

    // mod_exp
    mod_exp #(
                .n     (n),
                .n_bit (n_bit),
                .logr  (logr),
                .p     (p),
                .Rmodn (Rmodn),
                .R2modn(R2modn)
            ) inst_mod_exp (
                .a    (data_in),
                .e    (d),
                .clk  (clk),
                .rst_n(rst_n),
                .start(start),
                .z    (data_out),
                .done (done)
            );
endmodule
