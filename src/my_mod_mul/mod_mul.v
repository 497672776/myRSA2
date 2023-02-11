module mod_mul (
        input [n_bit-1:0] x,
        input [n_bit-1:0] y,
        input clk,
        input rst_n,
        input start,
        output [n_bit-1:0] z,
        output done
    );

    // ---------------------------------- 代码说明start ----------------------------------
    // 实现功能: z = mod_mul(x,y) = x * y mod n;
    // z的值在done为高电平时有效
    // 实现8进制蒙哥马利模乘，8可以改为16，32..
    // 参数说明：
    //     n, n_bit, logr, p的设置可看mont.v文件
    //     相较于mont.v，需要多设置一个参数为R2modn,即R^2 mod n
    // 以下举几个例子:
    // 若n = 7'd79, r = 8, R = 8^3 = 512, R2modn = R^2 mod n = 512 * 512 mod 79 = 22
    // 若n = 7'd79, r = 16, R = 16^2 = 256, R2modn = R^2 mod n = 256 * 256 mod 79 = 45
    // 若n = 7'd79, r = 32, R = 32^2 = 1024, R2modn = R^2 mod n = 1024 * 1024 mod 79 = 9
    // 伪代码如下：
    // mod_mul(x,y){
    //     x' = mont(x,R2modn);
    //     y' = mont(y,R2modn);
    //     z' = mont(x',y');
    //     z  = mont(z',1);
    //     return z;
    // }
    // ---------------------------------- 代码说明end ------------------------------------


    // ---------------------------------- 实现功能 ----------------------------------
    // 外参设置
    // -----------------------------------------------------------------------------
    parameter R2modn = 7'd22;
    parameter n = 7'd79;
    parameter n_bit = 7;
    parameter logr = 3;
    parameter p =  3'd1;

    // ---------------------------------- 实现功能 ----------------------------------
    // 通过control来控制mont模块的两个输入，operand1和operand2
    // -----------------------------------------------------------------------------
    reg [1:0] control;
    parameter one = {{n_bit - 2{1'b0}}, 1'b1};
    wire [n_bit-1 : 0] operand1, operand2;
    assign operand1 = (control==2'b00)? x:(control==2'b01)? y:(control==2'b10)? x_pie: z_pie;
    assign operand2 = (control==2'b00 || control==2'b01)? R2modn:(control==2'b10)? y_pie: one;

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
    // 检测mont_done的上升沿
    // -----------------------------------------------------------------------------
    reg  temp_mont_done;
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
    localparam IDLE = 3'd0, GET_X_PIE = 3'd1, GET_Y_PIE = 3'd2, GET_Z_PIE = 3'd3, GET_Z = 3'd4, ENDING = 3'd5;

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
    always @(*) begin
        case (current_state)
            IDLE:
                next_state = start ? GET_X_PIE : IDLE;
            GET_X_PIE:
                next_state = pedge_mont_done ? GET_Y_PIE : GET_X_PIE;
            GET_Y_PIE:
                next_state = pedge_mont_done ? GET_Z_PIE : GET_Y_PIE;
            GET_Z_PIE:
                next_state = pedge_mont_done ? GET_Z : GET_Z_PIE;
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
         0] x_pie, y_pie, z_pie, z;
    always @(posedge clk) begin
        case (current_state)
            IDLE: begin
                mont_start <= 1'b0;
            end

            GET_X_PIE: begin
                control <= 2'b00;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    x_pie <= mont_result;
                end
            end

            GET_Y_PIE: begin
                control <= 2'b01;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    y_pie <= mont_result;
                end
            end

            GET_Z_PIE: begin
                control <= 2'b10;
                mont_start <= 1'b1;
                if (pedge_mont_done) begin
                    mont_start <= 1'b0;
                    z_pie <= mont_result;
                end
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


