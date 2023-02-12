`timescale 1ns / 1ps

module rsa_encoder (
        input clk,
        input rst_n,
        input start,
        input [n_bit-1:0] data_in,
        output [n_bit-1:0] data_out,
        output done
    );

    // ---------------------------------- 代码说明start ----------------------------------
    // 只是调用mod_exp模块，设置模n和幂e而已
    // 具体设置：
    //  parameter p=67,q=53,n=3551,t=3432,e=5,d=1373;
    //  p,q是两个素数
    //  n = p*q
    //  t = (p-1)(q-1)
    //  e和d是关于t的模反元素，即e*d-1能整除t
    //  m^e mod n = c
    //  c^d mod n = m
    //  n = 12'3551, n_bit = 12, r = 8, logr = 3, p = r - n[0]' = 8 - 7 = 1, R = r^3 = 4096, Rmodn = 545, R2modn = 2292
    // 参数说明：
    //  由于是解密模块，这里的幂用到的是e = 12'd5,  即将mod_exp的e input端口设置为e
    // ---------------------------------- 代码说明end ------------------------------------

    // ---------------------------------- 实现功能 ----------------------------------
    // 外参
    // -----------------------------------------------------------------------------
    parameter n = 12'd3551;
    parameter n_bit = 12;
    parameter logr = 3;
    parameter p =  3'd1;
    parameter Rmodn = 12'd545;
    parameter R2modn = 12'd2292;
    parameter e = 12'd5;

    // ---------------------------------- 实现功能 ----------------------------------
    // 实例化mod_exp模块
    // -----------------------------------------------------------------------------
    mod_exp #(
                .n     (n),
                .n_bit (n_bit),
                .logr  (logr),
                .p     (p),
                .Rmodn (Rmodn),
                .R2modn(R2modn)
            ) inst_mod_exp (
                .a    (data_in),
                .e    (e),
                .clk  (clk),
                .rst_n(rst_n),
                .start(start),
                .z    (data_out),
                .done (done)
            );
endmodule
