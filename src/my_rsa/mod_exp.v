module mod_exp (
        input [n_bit-1:0] a,
        input [n_bit-1:0] e,
        input clk,
        input rst_n,
        input start,
        output [n_bit-1:0] z,
        output done
    );

    // ---------------------------------- 代码说明start ----------------------------------
    // 实现功能: z = mod_exp(a,e) = a^e mod n;
    // z的值在done为高电平时有效
    // 实现8进制蒙哥马利模幂，8可以改为16，32..
    // 参数说明:
    //     n, n_bit, logr, p的设置可看mont.v文件
    //     相较于mont.v，需要多设两个参数，Rmodn和R2modn
    //     先获得R, R即是大于n的关于r的最小幂数
    //     Rmodn = R % n
    //     R2modn = R^2 % n = ((R % n) * (R % n)) % n
    // 以下举几个例子:
    // 若n = 7'd79, r = 8, R = 8^3 = 512, Rmodn = 512 % 79 = 38, R2modn = 38 * 38 mod 79 = 22
    // 伪代码如下：
    // mod_exp(a,e){
    //     s = R % n;
    //     t = mont(a,R^2 % n);
    //     for ( i = k-1; i >= 0; i-- ){
    //         s = mont(s,s);
    //         if ( e[i] == 1 ){
    //             s = mont(s,t);
    //         }
    //     }
    //     z = mont(s,1);
    //     return z;
    // }
    // ---------------------------------- 代码说明end ------------------------------------


    // ---------------------------------- 实现功能 ----------------------------------
    // 外参
    // -----------------------------------------------------------------------------
    parameter n = 7'd79;
    parameter n_bit = 7;
    parameter logr = 3;
    parameter p =  3'd1;
    parameter Rmodn = 7'd49;
    parameter R2modn = 7'd31;

    // ---------------------------------- 实现功能 ----------------------------------
    // 内参设置
    // 思考: 循环次数为n_bit次，那么我们count到n_bit-1截止，进入GET_Z状态，即退出循环，就可以做到循环0~n_bit-1，总共n_bit次，合理
    //       所以设置count_stop_flag为n_bit-1，虽然后面count_i的值加到了n_bit且e多左移了一位，但是不影响，因为已经退出了循环
    // -----------------------------------------------------------------------------
    localparam count_stop_flag = n_bit-1;
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
    // 通过control来控制mont模块的两个输入，operand1和operand2
    // -----------------------------------------------------------------------------
    reg [1:0] control;
    localparam one = {{n_bit - 2{1'b0}}, 1'b1};
    wire [n_bit-1 : 0] operand1, operand2;
    assign operand1 = (control==2'b00)? a : s;
    assign operand2 = (control==2'b00)? R2modn :(control==2'b01)? s:(control==2'b10)? t: one;

    // ---------------------------------- 实现功能 ----------------------------------
    // 实例化mont模块
    // mont_result为输出结果,当mont_done为高电平时有效
    // -----------------------------------------------------------------------------
    wire [n_bit-1 : 0] mont_result;
    reg mont_start;
    mont #(
             .n_bit(n_bit),
             .logr (logr),
             .p    (p),
             .n    (n)
         ) inst_mont (
             .x    (operand1),
             .y    (operand2),
             .clk  (clk),
             .rst_n(rst_n),
             .start(mont_start),
             .z    (mont_result),
             .done (mont_done)
         );

    // ---------------------------------- 实现功能 ----------------------------------
    // 得到xi
    // -----------------------------------------------------------------------------
    reg [n_bit-1 : 0] reg_e;
    wire ei;
    assign ei = reg_e[n_bit-1];

    // ---------------------------------- 实现功能 ----------------------------------
    // 检测mont_done的上升沿
    // -----------------------------------------------------------------------------
    reg temp_mont_done;
    wire pedge_mont_done;
    always @(posedge clk) begin
        temp_mont_done <= mont_done;
    end
    assign pedge_mont_done = ~temp_mont_done & mont_done;

    // ---------------------------------- 实现功能 ----------------------------------
    // FSM
    // IDLE: 设置mont_start为0, 保证能开启
    // GET_X_PIE， GET_Y_PIE， GET_Z_PIE, GET_Z:
    //     通过改变control, 从而改变操作数，平时设置mont_start为1，开始计算
    //     计算done后，设置mont_start为0,结束计算，并且储存计算结果
    // default: 设置mont_start为0, 防止误开启，只是防止而已，应该也不会出现这种情况
    // -----------------------------------------------------------------------------
    reg [2:0] current_state, next_state;
    localparam IDLE = 3'd0, LOAD = 3'd1, GET_T = 3'd2, GET_S1 = 3'd3, GET_S2 = 3'd4, UPDATE = 3'd5, GET_Z = 3'd6, ENDING = 3'd7;

    wire done;
    assign done = current_state == ENDING;

    // FSM-1
    always @(posedge clk, negedge rst_n) begin : proc_current_state
        if (~rst_n) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // FSM-2
    // ---------------------------------- 实现功能 ----------------------------------
    // 循环肯定需要count来计数
    // count_i 相当于代码中的i
    // 判断count_i的值来停止循环
    // -----------------------------------------------------------------------------
    reg [count_bit-1 : 0] count_i;

    wire s1_to_s2;
    wire s1_to_s1;
    wire end_circle;
    assign end_circle = count_i == count_stop_flag;
    assign s1_to_s2 = pedge_mont_done & ei;
    assign s1_to_s1 = ~pedge_mont_done;
    always @(*) begin
        case (current_state)
            IDLE:
                next_state = start ? LOAD : IDLE;
            LOAD:
                next_state = GET_T;
            GET_T:
                next_state = pedge_mont_done ? GET_S1 : GET_T;
            GET_S1:
                next_state = s1_to_s1 ? GET_S1 : s1_to_s2 ? GET_S2 : UPDATE;
            GET_S2:
                next_state = pedge_mont_done ? UPDATE : GET_S2;
            UPDATE:
                next_state = end_circle ? GET_Z : GET_S1;
            GET_Z:
                next_state = pedge_mont_done ? ENDING : GET_Z;
            ENDING:
                next_state = start ? ENDING : IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // FSM-3
    reg [n_bit-1 :
         0] t, s, z;
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                mont_start <= 1'b0;
            end

            LOAD: begin
                count_i <= 'b0;
                reg_e <= e;
                mont_start <= 1'b0;
                s <= Rmodn;
            end

            GET_T: begin
                control <= 2'b00;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    t <= mont_result;
                end
            end

            GET_S1: begin
                control <= 2'b01;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    s <= mont_result;
                end
            end

            GET_S2: begin
                control <= 2'b10;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    s <= mont_result;
                end
            end

            UPDATE:begin
                mont_start <= 1'b0;
                count_i <= count_i + 1;
                reg_e <= (reg_e << 1);
            end

            GET_Z: begin
                control <= 2'b11;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    z <= mont_result;
                end
            end

            default: begin
                mont_start <= 1'b0;
            end
        endcase
    end
endmodule

