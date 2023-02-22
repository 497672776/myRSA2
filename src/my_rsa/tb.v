`timescale 1ns / 1ps
module tb;

    // 定义信号
    reg clk, rst_n;
    reg encoder_start, decoder_start;

    /*
    parameter n = 12'd3551;
    parameter n_bit = 12;
    parameter logr = 3;
    parameter p = 3'd1;
    parameter Rmodn = 12'd545;
    parameter R2modn = 12'd2292;
    parameter e = 12'd5;
    parameter d = 12'd1373;
    */

    parameter n = 1024'h904C420555F3A4543702808B9E553444C99E548A3E7691EE28C54693EA1705EEE47FB21B67CCC67A6027249AD455703241551508F90052DE699AEFC2286DE1E3C2B0CBAC45A45F7ADCDEA12B24A1FD869E169433E1A5D2409C176D30C028FFAFCB595532862600ACC062E5CDB028934617E46A6A6CAB8C0064DDA8E423CCBE2F;
    parameter n_bit = 1024;
    parameter logr = 4;
    parameter p = 4'd1;

    parameter Rmodn = ~n+1;
    parameter R2modn = 1024'h67FCEFB1079367E5DF13F3044846EEA562139306870E41385156605DB90EA9C5FB11657656D05B8F76A69826913C7F345E965191773BFDF545E51FC5ECA1973B700F3C4EF0C78FD94BD344A2611424BB60AAA68D578637FCDA8029E73D0531A6205B07C9790E8C57152F325A583AECB240725F598EA835BFCA2C7493746FD340;

    parameter e = 1024'h10001;
    parameter d = 1024'hCB208E4FB48F25E4E70B3EA94C59E51A7037D20A49A3E009C29AF29F8608A2F187F7BA6199DD4A093B11DF159592303E8E799702EA82EA24EDC48D7E642B4AAF86767F380A063067C3337366F813ABC6ABB1731A293DAF0CC480A96057A757283B3342E43BB4992A0404F1811229C9B026475F1A622818B419D11442C6896F1;

    /*
    parameter n = 12'd3551;
    parameter n_bit = 12;
    parameter logr = 4;
    parameter p = 4'd1;
    parameter Rmodn = ~n+1;
    // parameter R2modn = Rmodn * Rmodn % n;
    parameter e = 12'd5;
    parameter d = 12'd1373;
    */
    
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
            handle_data_in = $fopen("/home/dec/WorkSpace/Security/myRSA_r/src/my_rsa/result/data_in.txt", "r");
            // 定义输出文件指针，输出运行结果
            handle_out = $fopen("/home/dec/WorkSpace/Security/myRSA_r/src/my_rsa/result/result.txt", "w");
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
            read_cnt = $fscanf(handle_data_in,"%d",encoder_data_in);
            while(read_cnt != -1) begin
                // encoder
                $display("encoder_data_in: %h",encoder_data_in);
                #(NCLK);
                encoder_start = 1'b1;
                wait(encoder_done);
                $display("encoder_data_out: %h",encoder_data_out);
                $display("decoder_data_in: %h",decoder_data_in);

                // decoder
                decoder_start = 1'b1;
                wait(decoder_done);
                $display("decoder_data_out: %h",decoder_data_out);

                // compare
                #(NCLK);
                if(encoder_data_in == decoder_data_out)
                    $fdisplay(handle_out, "%h encode right! >= %d\n", encoder_data_in, encoder_data_out);
                else
                    $fdisplay(handle_out, "%h encode wrong!\n", encoder_data_in);

                // restart
                encoder_start = 1'b0;
                decoder_start = 1'b0;

                read_cnt = $fscanf(handle_data_in,"%d",encoder_data_in);
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
                $fdisplay(handle_out, "%h encode right! => %d\n", encoder_data_in, encoder_data_out);
            else
                $fdisplay(handle_out, "%h encode wrong!\n", encoder_data_in);

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
