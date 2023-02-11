`timescale 1ns / 1ps

module rsa_decoder (
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
    parameter p = 3'd1;
    parameter Rmodn = 7'd49;
    parameter R2modn = 7'd31;

    // ---------------------------------- 实现功能 ----------------------------------
    // 实例化mod_exp模块
    // mont_result为输出结果,当mont_done为高电平时有效
    // -----------------------------------------------------------------------------
    mod_exp #(
                .n     (n),
                .n_bit (logk),
                .logr  (logr),
                .p     (p),
                .Rmodn (Rmodn),
                .R2modn(R2modn)
            ) inst_mod_exp (
                .x    (d),
                .y    (data_in),
                .clk  (clk),
                .rst_n(rst_n),
                .start(start),
                .z    (data_out),
                .done (done)
            );
endmodule
