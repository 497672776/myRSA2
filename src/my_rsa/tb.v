`timescale 1ns / 1ps
module tb;

    // 定义信号
    reg clk, rst_n;
    reg encoder_start, decoder_start;

    parameter n = 12'd3551;
    parameter n_bit = 12;
    parameter logr = 3;
    parameter p = 3'd1;
    parameter Rmodn = 12'd545;
    parameter R2modn = 12'd2292;
    parameter e = 12'd5;
    parameter d = 12'd1373;

    reg [n_bit-1:0] encoder_data_in;
    wire [n_bit-1:0] encoder_data_out, decoder_data_in, decoder_data_out;
    assign decoder_data_in = encoder_data_out;
    wire encoder_done, decoder_done;
    // 生成始时钟
    parameter NCLK = 40;  //40ns 25Mhz
    always #(NCLK / 2) clk = ~clk;

    integer handle_data_in, handle_out, read_cnt;


    /****************** 开始 ADD module inst ******************/
    rsa_encoder #(
                    .n     (n),
                    .n_bit (n_bit),
                    .logr  (logr),
                    .p     (p),
                    .Rmodn (Rmodn),
                    .R2modn(R2modn),
                    .e     (e)
                ) inst_rsa_encoder (
                    .clk     (clk),
                    .rst_n   (rst_n),
                    .start   (encoder_start),
                    .data_in (encoder_data_in),
                    .data_out(encoder_data_out),
                    .done    (encoder_done)
                );
    /****************** 结束 END module inst ******************/

    /****************** 开始 ADD module inst ******************/
    rsa_decoder #(
                    .n     (n),
                    .n_bit (n_bit),
                    .logr  (logr),
                    .p     (p),
                    .Rmodn (Rmodn),
                    .R2modn(R2modn),
                    .d     (d)
                ) inst_rsa_decoder (
                    .clk     (clk),
                    .rst_n   (rst_n),
                    .start   (decoder_start),
                    .data_in (decoder_data_in),
                    .data_out(decoder_data_out),
                    .done    (decoder_done)
                );
    /****************** 结束 END module inst ******************/

    initial begin
        $dumpfile("wave.lxt2");
        $dumpvars(0, tb);  //dumpvars(深度, 实例化模块1, 实例化模块2, .....)
    end

    // 初始化
    task initialization;
        begin
            clk = 1'b0;
            rst_n = 1'b1;
            encoder_start = 1'b0;
            decoder_start = 1'b0;
            encoder_data_in = 'b0;
        end
    endtask

    // 复位
    task reset;
        begin
            #NCLK;
            rst_n = 1'b0;  // 复位
            #NCLK;
            rst_n = 1'b1;
        end
    endtask

    // 打开文件，读取测试数据
    task open_file;
        begin
            // 定义输入文件指针，读取文件数据
            handle_data_in = $fopen("/home/dec/WorkSpace/Security/myRSA2/src/my_rsa/result/data_in.txt", "r");
            // 定义输出文件指针，输出运行结果
            handle_out = $fopen("/home/dec/WorkSpace/Security/myRSA2/src/my_rsa/result/result.txt", "w");
        end
    endtask

    // 关闭文件
    task close_file;
        begin
            $fclose(handle_data_in);
            $fclose(handle_out);
        end
    endtask

    task rsa_verify_file;
        begin
            read_cnt = 0;
            while(read_cnt != -1) begin
                // encoder
                read_cnt = $fscanf(handle_data_in,"%d",encoder_data_in);
                #(NCLK);
                encoder_start = 1'b1;
                wait(encoder_done);

                // decoder
                decoder_start = 1'b1;
                wait(decoder_done);

                // compare
                #(NCLK);
                if(encoder_data_in == decoder_data_out)
                    $fdisplay(handle_out, "%d encode right! >= %d\n", encoder_data_in, encoder_data_out);
                else
                    $fdisplay(handle_out, "%d encode wrong!\n", encoder_data_in);

                // restart
                encoder_start = 1'b0;
                decoder_start = 1'b0;
            end
        end
    endtask

    task rsa_verify_once(input [n_bit-1 : 0] i);
        begin
            // encoder
            encoder_data_in = i;
            #(NCLK);
            encoder_start = 1'b1;
            wait(encoder_done);

            // decoder
            decoder_start = 1'b1;
            wait(decoder_done);

            // compare
            #(NCLK);
            if(encoder_data_in == decoder_data_out)
                $fdisplay(handle_out, "%d encode right! => %d\n", encoder_data_in, encoder_data_out);
            else
                $fdisplay(handle_out, "%d encode wrong!\n", encoder_data_in);

            // restart
            encoder_start = 1'b0;
            decoder_start = 1'b0;
        end
    endtask

    integer i;
    task rsa_verify_all;
        begin
            for(i = 0; i <= n -1; i = i + 1)begin
                rsa_verify_once(i);
            end
        end
    endtask

    task ending;
        begin
            repeat (1000) begin
                @(posedge clk);
            end
            $display("运行结束！");
            $dumpflush;
            $finish;
            $stop;
        end
    endtask

    initial begin
        initialization;
        reset;
        open_file;
        rsa_verify_file;
        // rsa_verify_all;
        close_file;
        ending;
    end

endmodule
