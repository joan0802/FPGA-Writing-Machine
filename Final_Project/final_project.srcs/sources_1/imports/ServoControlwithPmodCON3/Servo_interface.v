`timescale 1ns / 1ps

module Servo_interface (
    input [3:0] sw,
    input rst,
    input clk,
    input en,
    input [15:0] num,
    output reg pwm_claw,
    output reg pwm_left,
    output reg pwm_right,
    output reg pwm_bottom,
    output [2:0] index,
    output reg finish_writing
);
    wire [19:0] count_max;
    wire [19:0] value_claw, value_left, value_right, value_bottom;
    wire [6:0] angle_claw, angle_left, angle_right, angle_bottom;
    reg [3:0] cur_num;
    wire nextIsWriting;
    wire clk_write;


    // Convert the switch value to an angle value.
    sw_to_angle convert(
        .sw(sw),
        .angle_claw(angle_claw),
        .angle_left(angle_left),
        .angle_right(angle_right),
        .angle_bottom(angle_bottom),
        .num(cur_num),
        .en(en),
        .finish_writing(finish_writing),
        .nextIsWriting(nextIsWriting),
        .clk(clk),
        .clk_write(clk_write),
        .index(index),
        .rst(rst)
        );

    clock_divider #(27) divider(
        .clk(clk),
        .en(en),
        .clk_div(clk_write)
    );
    
    // Convert the angle value to 
    // the constant value needed for the PWM.
    assign value_claw = (10'd944)*(angle_claw)+ 16'd60000;
    assign value_left = (10'd944)*(angle_left)+ 16'd60000;
    assign value_right = (10'd944)*(angle_right)+ 16'd60000;
    assign value_bottom = (10'd944)*(angle_bottom)+ 16'd60000;
    
    // Compare the count value from the
    // counter, with the constant value set by
    // the switches.

    always @(posedge clk_write, posedge rst) begin
        if(rst) begin
            cur_num <= 4'd10;
            finish_writing <= 1'b0;
        end
        else begin
            if(nextIsWriting == 1'b1) begin
                if(cur_num == 4'd10)
                    cur_num <= num[3:0];
                else
                    cur_num <= cur_num;
                finish_writing <= 1'b0;
            end
            else begin
                if(cur_num == num[3:0] && num[7:4] != 4'd10) begin
                    cur_num <= num[7:4];
                    finish_writing <= 1'b0;
                end
                else if(cur_num == num[7:4] && num[11:8] != 4'd10) begin
                    cur_num <= num[11:8];
                    finish_writing <= 1'b0;
                end
                else if(cur_num == num[11:8] && num[15:12] != 4'd10) begin
                    cur_num <= num[15:12];
                    finish_writing <= 1'b0;
                end
                else begin
                    cur_num <= cur_num;
                    finish_writing <= 1'b1;
                end
            end
        end
    end

    always @(posedge clk, posedge rst) begin
        if(rst) begin
            pwm_claw <= 1'b0;
            pwm_left <= 1'b0;
            pwm_right <= 1'b0;
            pwm_bottom <= 1'b0;
        end
        else begin
            if (count_max < value_claw) pwm_claw <= 1'b1;
            else pwm_claw <= 1'b0;

            if (count_max < value_left) pwm_left <= 1'b1;
            else pwm_left <= 1'b0;

            if (count_max < value_right) pwm_right <= 1'b1;
            else pwm_right <= 1'b0;

            if (count_max < value_bottom) pwm_bottom <= 1'b1;
            else pwm_bottom <= 1'b0;
        end
    end
    // always @ (count_max,value_claw) begin
	//     if (count_max < value_claw) pwm_claw <= 1'b1;
	//     else pwm_claw <= 1'b0;
	// end

    // always @ (count_max,value_left) begin
    //     if (count_max < value_left) pwm_left <= 1'b1;
    //     else pwm_left <= 1'b0;
    // end

    // always @ (count_max,value_right) begin
    //     if (count_max < value_right) pwm_right <= 1'b1;
    //     else pwm_right <= 1'b0;
    // end

    // always @ (count_max,value_bottom) begin
    //     if (count_max < value_bottom) pwm_bottom <= 1'b1;
    //     else pwm_bottom <= 1'b0;
    // end
    // Counts up to a certain value and then resets.
    // This module creates the refresh rate of 20ms.   
    counter count(
        .rst(rst),
        .clk(clk),
        .count(count_max)
        );
        
endmodule

module counter (
	input rst,
	input clk,
	output reg [19:0]count
);

    // Run on the positive edge of the clock
	always @ (posedge clk)
	begin
	    // If the clear button is being pressed or the count
	    // value has been reached, set count to 0.
	    // This constant depends on the refresh rate required by the
	    // servo motor you are using. This creates a refresh rate
	    // of 10ms. 100MHz/(1/10ms) or (system clock)/(1/(Refresh Rate)).
		if (rst == 1'b1 || count == 20'd1000000)
			begin
			count <= 20'b0;
			end
		// If clear is not being pressed and the 
		// count value is not reached, continue to increment
		// count. 
		else
			begin
			count <= count + 1'b1;
			end
	end
endmodule

module sw_to_angle(
    input [3:0] sw,
    input en,
    input [3:0] num,
    input rst,
    input clk,
    input clk_write,
    input finish_writing,
    output reg [6:0] angle_claw,
    output reg [6:0] angle_left,
    output reg [6:0] angle_right,
    output reg [6:0] angle_bottom,
    output reg [2:0] index,
    output reg nextIsWriting
    );
    
    parameter LEFT = 9'b11_0000101;
    parameter RIGHT = 9'b11_0000000;
    parameter FRONT = 9'b10_0001100; // 12 degree
    parameter MIDDLE = 9'b10_0000101; // 5 degree
    parameter BACK = 9'b10_0000000;
    parameter IDLE = 9'b00_0000000;
    parameter UP = 9'b01_0000101;
    // parameter UPWRITE = 9'b01_0000010;
    parameter DOWN = 9'b01_0000000;
    

    reg [8:0] cur_angle_lr, cur_angle_fb;
    reg [7:0] position;
    reg isWriting;

    parameter [8:0] ZERO_lr [0:4] = { //後 前 左 後 右
        IDLE, IDLE, LEFT, LEFT, RIGHT
    };
    parameter [8:0] ZERO_fb [0:4] = { //後 前 左 後 右
        IDLE, FRONT, FRONT, BACK, BACK
    };
    parameter [8:0] ONE_lr [0:2] = {
        IDLE, IDLE, IDLE
    };
    parameter [8:0] ONE_fb [0:2] = {
        IDLE, FRONT, BACK
    };
    parameter [8:0] TWO_lr [0:5] = { //後 左 中 右 前 左 
        IDLE, LEFT, LEFT, RIGHT, RIGHT, LEFT
    };
    parameter [8:0] TWO_fb [0:5] = { //後 左 中 右 前 左 
        IDLE, IDLE, MIDDLE, MIDDLE, FRONT, FRONT
    };
    parameter [8:0] THREE_lr [0:7] = { //後 左 右 中 左 右 前 左 (右)
        IDLE, LEFT, RIGHT, RIGHT, LEFT, RIGHT, RIGHT, LEFT
    };
    parameter [8:0] THREE_fb [0:7] = { //後 左 右 中 左 右 前 左 (右)
        IDLE, IDLE, IDLE, MIDDLE, MIDDLE, MIDDLE, FRONT, FRONT
    };
    parameter [8:0] FOUR_lr [0:4] = { //後 前 中 左 前 中 右
        IDLE, IDLE, IDLE, LEFT, LEFT
    };
    parameter [8:0] FOUR_fb [0:4] = { //後 前 中 左 前 中 右
        IDLE, FRONT, MIDDLE, MIDDLE, FRONT
    };
    parameter [8:0] FIVE_lr [0:7] = { //後 左 右 中 左 前 右
        IDLE, LEFT, RIGHT, RIGHT, LEFT, LEFT, RIGHT, LEFT
    };
    parameter [8:0] FIVE_fb [0:7] = { //後 左 右 中 左 前 右
        IDLE, IDLE, IDLE, MIDDLE, MIDDLE, FRONT, FRONT, FRONT 
    };
    parameter [8:0] SIX_lr [0:6] = { //後 中 左 前 後 右
        IDLE, IDLE, LEFT, LEFT, LEFT, RIGHT, LEFT
    };
    parameter [8:0] SIX_fb [0:6] = { //後 中 左 前 後 右
        IDLE, MIDDLE, MIDDLE, FRONT, BACK, BACK, BACK
    };
    parameter [8:0] SEVEN_lr [0:2] = { //前左
        IDLE, IDLE, LEFT
    };
    parameter [8:0] SEVEN_fb [0:2] = { //前左
        IDLE, FRONT, FRONT
    };
    parameter [8:0] EIGHT_lr [0:6] = { //前左後右中左
        IDLE, IDLE, LEFT, LEFT, RIGHT, RIGHT, LEFT
    };
    parameter [8:0] EIGHT_fb [0:6] = { //前左後右中左
        IDLE, FRONT, FRONT, BACK, BACK, MIDDLE, MIDDLE
    };
    parameter [8:0] NINE_lr [0:7] = { //左右前左後右後
        IDLE, LEFT, RIGHT, RIGHT, LEFT, LEFT, RIGHT, LEFT
    };
    parameter [8:0] NINE_fb [0:7] = { //左右前左後右後
        IDLE, IDLE, IDLE, FRONT, FRONT, MIDDLE, MIDDLE, MIDDLE
    };
    always @(*) begin
        case(num)
            4'd0: cur_angle_fb = ZERO_fb[index];
            4'd1: cur_angle_fb = ONE_fb[index];
            4'd2: cur_angle_fb = TWO_fb[index];
            4'd3: cur_angle_fb = THREE_fb[index];
            4'd4: cur_angle_fb = FOUR_fb[index];
            4'd5: cur_angle_fb = FIVE_fb[index];
            4'd6: cur_angle_fb = SIX_fb[index];
            4'd7: cur_angle_fb = SEVEN_fb[index];
            4'd8: cur_angle_fb = EIGHT_fb[index];
            4'd9: cur_angle_fb = NINE_fb[index];
            default: cur_angle_fb = ZERO_fb[index];
        endcase
    end
    always @(*) begin
        case(num)
            4'd0: cur_angle_lr = ZERO_lr[index];
            4'd1: cur_angle_lr = ONE_lr[index];
            4'd2: cur_angle_lr = TWO_lr[index];
            4'd3: cur_angle_lr = THREE_lr[index];
            4'd4: cur_angle_lr = FOUR_lr[index];
            4'd5: cur_angle_lr = FIVE_lr[index];
            4'd6: cur_angle_lr = SIX_lr[index];
            4'd7: cur_angle_lr = SEVEN_lr[index];
            4'd8: cur_angle_lr = EIGHT_lr[index];
            4'd9: cur_angle_lr = NINE_lr[index];
            default: cur_angle_lr = ZERO_lr[index];
        endcase
    end

    always @(posedge clk_write, posedge rst) begin
        if(rst) 
            position <= 8'd0;
        else begin
            if(nextIsWriting == 1'b0) begin
                position <= angle_bottom + 8'd8;
            end
            else begin
                position <= position;
            end
        end
    end

    always @(posedge clk_write, posedge rst) begin
        if(rst) begin
            isWriting <= 1'b1;
        end
        else begin
            isWriting <= nextIsWriting;
        end
    end

    always @* begin
        if(rst) begin
            nextIsWriting = 1'b1;
        end
        else if(finish_writing == 1'b1) begin
            nextIsWriting = 1'b0;
        end
        else begin
            case(num) 
                4'd0: begin
                    if(index == 3'd4) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd1: begin
                    if(index == 3'd2) begin
                        nextIsWriting = 1'b0;
                    end 
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd2: begin
                    if(index == 3'd5) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd3: begin
                    if(index == 3'd7) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd4: begin
                    if(index == 3'd4) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd5: begin
                    if(index == 3'd7) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd6: begin
                    if(index == 3'd6)  begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd7: begin
                    if(index == 3'd2) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd8: begin
                    if(index == 3'd6) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                4'd9: begin
                    if(index == 3'd7) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
                default: begin
                    if(index == 3'd4) begin
                        nextIsWriting = 1'b0;
                    end
                    else begin
                        nextIsWriting = 1'b1;
                    end
                end
            endcase
        end
    end

    always @(posedge clk_write, posedge rst) begin
        if(rst) begin
            index <= 3'd0;
        end
        else if(finish_writing == 1'b1) begin
            index <= 3'd0;
        end
        else begin
            case(num) 
                4'd0: begin
                    if(index == 3'd4) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd1: begin
                    if(index == 3'd2) begin
                        index <= 3'd0;
                    end 
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd2: begin
                    if(index == 3'd5) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd3: begin
                    if(index == 3'd7) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd4: begin
                    if(index == 3'd4) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd5: begin
                    if(index == 3'd7) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd6: begin
                    if(index == 3'd6)  begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd7: begin
                    if(index == 3'd2) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd8: begin
                    if(index == 3'd6) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                4'd9: begin
                    if(index == 3'd7) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
                default: begin
                    if(index == 3'd4) begin
                        index <= 3'd0;
                    end
                    else begin
                        index <= index + 1'b1;
                    end
                end
            endcase
        end
    end
    
    
    // Run when the value of the switches
    // changes
    // reg claw, left, right, bottom;
    always @ (*) begin
        // if(rst) begin
        //     angle_claw = 7'b0;
        //     angle_left = 7'b0;
        //     angle_right = 7'b0;
        //     angle_bottom = 7'b0;
        // end
        // else begin
            if(sw[0] == 1'b1) 
                angle_claw = 7'b110000;
            else
                angle_claw = 7'b0; // NEED TO CHANGE

            if(cur_angle_fb[8:7] == 2'b00)
                angle_left = 7'b0;
            else if(isWriting == 1'b0) begin
                angle_left = 7'b0000110;
            end
            else if(cur_angle_fb[8:7] == 2'b10 && cur_angle_fb[6:0] == 7'b0001100)
                angle_left = 7'b0000011;
            else
                angle_left = angle_left;
            
            if(cur_angle_fb[8:7] == 2'b00)
                angle_right = 7'b0;
            else if(cur_angle_fb[8:7] == 2'b10)
                angle_right = cur_angle_fb[6:0];
            else
                angle_right = angle_right;

            if(cur_angle_lr[8:7] == 2'b00)
                angle_bottom = position;
            else if(isWriting == 1'b0) begin
                angle_bottom = position;
            end
            else if(cur_angle_lr[8:7] == 2'b11)
                angle_bottom = position + cur_angle_lr[6:0];
            else
                angle_bottom = angle_bottom;
        end
    // end
endmodule
