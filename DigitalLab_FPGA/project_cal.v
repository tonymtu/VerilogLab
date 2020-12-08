`timescale 1ns / 1ps



module display(
    input [2:0] NUM,//决定显示的内容
    input [3:0] BITS,//扫描显示信号输入
    output reg [7:0] ZERO_ONE,
    output [3:0] LED_BITS
    );
    assign LED_BITS = BITS;
    always @(*)
      begin
        case(NUM)
        0:ZERO_ONE=8'b11111100;
        1:ZERO_ONE=8'b01100000;
        2:ZERO_ONE=8'b10011110;//E
        3:ZERO_ONE=8'b00000000;
        4:ZERO_ONE=8'b11111101;//0.
        5:ZERO_ONE=8'b01100001;//1.  左数加点表示-，右数加点表示+
        default:ZERO_ONE=8'b00000001;
        endcase
      end
endmodule



module project_basic(
    input clk,
    input clr,
    input x1,
    input x0,
    input add,
    input sub,
    input result,
    output [7:0] zero_one,
    output [7:0] sign_zero_one,
    output [3:0] led_bits,
    output [3:0] sign_led_bits
    );
    reg [3:0] a = 0;
    reg [3:0] b = 0;
    reg a_or_b = 1;
    integer i = 0;//循环
    integer cnt = 0;//bit count
    reg carry = 0;
    reg [3:0] bcom; // component of b
    reg [30:0] count;//clock count
    reg [4:0] ans;  //ans[4]:signbit
    reg [3:0] t_led_bits;
    reg [3:0] sign_t_led_bits;
    reg [2:0] num;
    reg [2:0] signnum;
    reg error = 0;
    reg ifadd = 0;//whether add or not
    reg ifsub = 0;//whether substract or not
    reg ifresult = 0;//数码管是否以结果形式显示
    //要微动开关0后的1才有效
    reg sw01 = 0;
    //按下按钮后一小段时间无视输入，用以防止抖动影响
    reg if_delay_count = 0;
    reg [23:0] delay = 0;
    

    always @ (posedge clk)
        begin
        if (clr)
            begin
            count = 0;
            ans = 0;
            a = 0;
            b = 0;
            ifadd = 0;
            ifsub = 0;
            ifresult = 0;
            cnt = 0;
            error = 0;
            a_or_b = 1;
            sw01 = 0;
            end
        else count = count + 1; 

        if (cnt == 4)
        begin
        a_or_b = ~a_or_b;
        cnt = 0;
        end
        
        if (x1| x0)
            begin
            if_delay_count = 1;
            if (a_or_b) 
                begin
                if (x1) a[3-cnt] <= 1;
                else if (x0) a[3-cnt] <= 0;
                end
            else
                begin
                if (x1) b[3-cnt] <= 1;
                else if (x0) b[3-cnt] <= 0;
                end
            sw01 = 1;
            end
        else if (sw01 & ~if_delay_count)
            begin
            cnt <= cnt + 1;
            sw01 <= 0;
            end
        
        if (if_delay_count)
            begin
            delay = delay + 1;
            if (delay[23])
                begin
                delay = 0;
                if_delay_count = 0;
                end
            end
        
        if (add)
            begin
            ifadd = 1;
            ifsub = 0;
            end
        if (sub)
            begin
            ifsub = 1;
            ifadd = 0;
            end
        if (result)
            begin
            if (ifadd)
                begin
                carry = 0;
                for(i = 0; i < 4; i = i + 1)
                    begin
                    ans[i] = (a[i]^b[i])^carry;
                    carry = (a[i]&b[i])|((a[i]^b[i])&carry);
                    end
                error = carry;
                ans[4] = 0;
                end
            else if (ifsub)
                begin
                bcom = ~b;
                carry = 1;
                for (i = 0; i < 4; i = i + 1)
                    begin
                    ans[i] = (a[i]^bcom[i])^carry;
                    carry = (a[i]&bcom[i])|((a[i]^bcom[i])&carry);
                    end
                ans[4] = ~carry;
                error = 0;
                end
            ifresult = 1;      
            end
        end


    always@(*)
        begin
        if (~ifresult)
            begin
            if (error)
            case(count[15:14])
            0:begin num <= 2;signnum <= 2;t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= 2;signnum <= 2;t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= 2;signnum <= 2;t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= 2;signnum <= 2;t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            else if (ifadd)
            case(count[15:14])
            0:begin num <= b[0] + 4;signnum <= a[0];t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= b[1] + 4;signnum <= a[1];t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= b[2] + 4;signnum <= a[2];t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= b[3] + 4;signnum <= a[3];t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            else if (ifsub)
            case(count[15:14])
            0:begin num <= b[0];signnum <= a[0] + 4;t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= b[1];signnum <= a[1] + 4;t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= b[2];signnum <= a[2] + 4;t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= b[3];signnum <= a[3] + 4;t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            else
            case(count[15:14])
            0:begin num <= b[0];signnum <= a[0];t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= b[1];signnum <= a[1];t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= b[2];signnum <= a[2];t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= b[3];signnum <= a[3];t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            end
        else
            begin
            if (~error & ans[4])
            case(count[14:13])
            0:begin num <= ans[0];signnum <= 1;t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= ans[1];signnum <= 3;t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= ans[2];signnum <= 3;t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= ans[3];signnum <= 3;t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            else if (~error)
            case(count[15:14])
            0:begin num <= ans[0];signnum <= 3;t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= ans[1];signnum <= 3;t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= ans[2];signnum <= 3;t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= ans[3];signnum <= 3;t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            else
            case(count[15:14])
            0:begin num <= 2;signnum <= 2;t_led_bits <= 4'b0001;sign_t_led_bits <= 4'b0001;end
            1:begin num <= 2;signnum <= 2;t_led_bits <= 4'b0010;sign_t_led_bits <= 4'b0010;end 
            2:begin num <= 2;signnum <= 2;t_led_bits <= 4'b0100;sign_t_led_bits <= 4'b0100;end 
            3:begin num <= 2;signnum <= 2;t_led_bits <= 4'b1000;sign_t_led_bits <= 4'b1000;end
            endcase
            end
        end
      
      
      display display1(.NUM(num),.BITS(t_led_bits),.ZERO_ONE(zero_one),.LED_BITS(led_bits));
      display display2(.NUM(signnum),.BITS(sign_t_led_bits),.ZERO_ONE(sign_zero_one),.LED_BITS(sign_led_bits));
      
endmodule