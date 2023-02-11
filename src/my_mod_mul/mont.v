module mont (
        input [n_bit-1 : 0] x,
        input [n_bit-1 : 0] y,
        input clk,
        input rst_n,
        input start,
        output [n_bit-1 : 0] z,
        output done
    );

    // ---------------------------------- 代码说明start ----------------------------------
    // 实现功能: z = mont(x,y) = x * y * R' mod n;
    // z的值在done为高电平时有效
    // 说明: R是大于N的r的最小次幂, R'是R关于模n的逆
    // 实现8进制蒙哥马利，8可以改为16，32..
    // 参数说明：
    //     需要设置四个参数:n, n_bit, logr, p
    //     n是模
    //     n_bit是n的位数
    //     logr是2的几次方的进制的蒙哥马利, 如果r是8, 也就是使用8进制的蒙哥马力, 则使用logr = log2(8) = 3
    //     p = r - n[0]', n[0]是n%r, n[0]'是n[0]关于模r的逆
    // 以下举几个例子:
    // 若n = 7'd79, r = 8, n_bit = 7, logr = 3, n[0] = 79 % 8 = 7, 7关于模8的模逆是7， p = 8 - 7 = 1;
    // 若n = 7'd79, r = 16, n_bit = 7, logr = 4, n[0] = 79 % 16 = 15, 15关于模16的模逆是15， p = 16 - 15 = 1;
    // 若n = 7'd79, r = 32, n_bit = 7, logr = 5, n[0] = 79 % 32 = 15, 15关于模32的模逆是15， p = 32 - 15 = 17;
    // 伪代码如下：
    // mont(x,y){
    //     p = r - n[0]';
    //     s = 0;
    //     for ( i = 0; i < m; i++ ){
    //         q1 = ( ( s[0] + x[i] * y[0] ) * p );
    //         q2 = q1 mod r;
    //         s1 = s + x[i] * y + q2 * n;
    //         s2 = s1 / r;
    //         if ( s2 - n >= 0 ){
    //             next_s = s2 - n;
    //         } else{
    //             next_s = s2;
    //         }
    //         s = next_s;
    //     }
    //     return s;
    // }
    // ---------------------------------- 代码说明end ------------------------------------


    // ---------------------------------- 实现功能 ----------------------------------
    // 外参设置
    // -----------------------------------------------------------------------------
    parameter n = 7'd79;
    parameter n_bit = 7;
    parameter logr = 3;
    parameter p = 3'd1;

    // ---------------------------------- 实现功能 ----------------------------------
    // 内参设置
    // -----------------------------------------------------------------------------
    localparam update_num = n_bit / logr + (n_bit % logr != 0);
    localparam count_stop_flag = update_num - 2;
    localparam count_bit = count_stop_flag < 2 ? 1 :
               count_stop_flag < 4 ? 2 :
               count_stop_flag < 8 ? 3 :
               count_stop_flag < 16 ? 4 :
               count_stop_flag < 32 ? 5 :
               count_stop_flag < 64 ? 6 :
               count_stop_flag < 128 ? 7 :
               count_stop_flag < 256 ? 8 :
               count_stop_flag < 512 ? 9 :
               count_stop_flag < 1024 ? 10 :
               count_stop_flag < 2048 ? 11 : 12 ;

    // ---------------------------------- 实现功能 ----------------------------------
    // 循环肯定需要count来计数
    // count_i 相当于代码中的i
    // 判断count_i的值来停止循环
    // -----------------------------------------------------------------------------
    reg [count_bit-1 : 0] count_i;

    // ---------------------------------- 实现功能 ----------------------------------
    // 得到xi
    // -----------------------------------------------------------------------------
    reg [n_bit-1 : 0] reg_x;
    wire [logr-1 : 0] xi;
    assign xi = reg_x[logr-1 : 0];

    // -------------------------------实现功能----------------------------------
    // 最终目标: 得到next_s
    // q1的位数计算：
    //      q1 = ( ( s[0] + x[i] * y[0] ) * p );
    //      (logr位的数 + logr位的数 * logr位的数) * logr位的数 => 3logr+1
    // s1的位数计算:
    //      s1 = s + x[i] * y + q2 * n;
    //      倒推法： s2 = s1 /r, 又由于s2 < 2n, 所以s2最多nbit+1位， s1最多nbit+1+logr位，即n_bit+logr+1位
    // s1的位数计算:
    //      s1 = s + x[i] * y + q2 * n;
    //      倒推法： s2 = s1 /r, 又由于s2 < 2n, 所以s2最多nbit+1位， s1最多nbit+1+logr位，即n_bit+logr+1位
    // s2_minus_n的位数计算：
    //      0 <= s2 < 2n, 所以-n <= s2-n < n, 即s2_minus_n的位数只需要n的位数+1，即n_bit+1，最高位是符号位
    // ------------------------------------------------------------------------
    reg [n_bit-1 : 0] s;
    wire [logr-1 : 0] s_zero, y_zero;
    assign s_zero = s[logr-1 : 0];
    assign y_zero = y[logr-1 : 0];

    wire [3*logr : 0] q1;
    wire [logr-1 : 0] q2;
    assign q1 = (s_zero + xi * y_zero) * p;
    assign q2 = q1[logr-1 : 0];

    wire [n_bit+logr : 0] s1;
    wire [n_bit : 0] s2;
    assign s1 = s + xi * y + q2 * n;
    assign s2 = s1 >> logr;

    wire [n_bit : 0] s2_minus_n;
    wire [n_bit-1 : 0] next_s;
    assign s2_minus_n = s2 - n;
    assign next_s = s2_minus_n[n_bit] ? s2[n_bit-1 : 0] : s2_minus_n[n_bit-1 : 0];
    assign z = next_s;

    // ---------------------------------- 实现功能 ----------------------------------
    // FSM
    // LOAD: 计数器归零，x寄存，s赋0
    // UPDATE: 计数器自加1， reg_x右移logr位，s更新
    // -----------------------------------------------------------------------------
    // FSM相关参数
    localparam IDLE = 3'd0, LOAD = 3'd1, UPDATE = 3'd2, ENDING = 3'd3;
    reg [2:0] current_state, next_state;

    wire done;
    assign done = current_state == ENDING;

    // FSM-1
    always @(posedge clk, negedge rst_n) begin
        if (~rst_n) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // FSM-2
    always @(*) begin
        case (current_state)
            IDLE: begin
                next_state = start ? LOAD : IDLE;
            end
            LOAD: begin
                next_state = UPDATE;
            end
            UPDATE: begin
                next_state = count_i == count_stop_flag ? ENDING : UPDATE;
            end
            ENDING: begin
                next_state = start ? ENDING : IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // FSM-3
    always @(posedge clk) begin
        case (current_state)
            LOAD: begin
                count_i <= 'b0;
                reg_x <= x;
                s <= 'b0;
            end

            UPDATE: begin
                count_i <= count_i + 1;
                reg_x <= (reg_x >> logr);
                s <= next_s;
            end
        endcase
    end

endmodule


