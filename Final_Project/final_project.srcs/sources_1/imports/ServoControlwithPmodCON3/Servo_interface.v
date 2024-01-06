`timescale 1ns / 1ps

module Servo_interface (
    input [3:0] sw,
    input rst,
    input clk,
    input en,
    input direction,
    input [15:0] num,
    output reg pwm_claw,
    output reg pwm_left,
    output reg pwm_right,
    output reg pwm_bottom,
    output [2:0] index
);
    wire [17:0] count_max;
    wire [17:0] value_claw, value_left, value_right, value_bottom;
    wire [6:0] angle_claw, angle_left, angle_right, angle_bottom;


    // Convert the switch value to an angle value.
    sw_to_angle convert(
        .sw(sw),
        .angle_claw(angle_claw),
        .angle_left(angle_left),
        .angle_right(angle_right),
        .angle_bottom(angle_bottom),
        .num(num[3:0]),
        .en(en),
        .clk(clk),
        .index(index),
        .rst(rst)
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

    // always @* begin
    //     if (count_max < value_claw) pwm_claw = 1'b1;
	//     else pwm_claw = 1'b0;

    //     if (count_max < value_left) pwm_left = 1'b1;
    //     else pwm_left = 1'b0;

    //     if (count_max < value_right) pwm_right = 1'b1;
    //     else pwm_right = 1'b0;

    //     if (count_max < value_bottom) pwm_bottom = 1'b1;
    //     else pwm_bottom = 1'b0;
    // end
    always @ (count_max,value_claw) begin
	    if (count_max < value_claw) pwm_claw <= 1'b1;
	    else pwm_claw <= 1'b0;
	end

    always @ (count_max,value_left) begin
        if (count_max < value_left) pwm_left <= 1'b1;
        else pwm_left <= 1'b0;
    end

    always @ (count_max,value_right) begin
        if (count_max < value_right) pwm_right <= 1'b1;
        else pwm_right <= 1'b0;
    end

    always @ (count_max,value_bottom) begin
        if (count_max < value_bottom) pwm_bottom = 1'b1;
        else pwm_bottom <= 1'b0;
    end
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
    output reg [6:0] angle_claw,
    output reg [6:0] angle_left,
    output reg [6:0] angle_right,
    output reg [6:0] angle_bottom,
    output reg [2:0] index
    );

    parameter LEFT = 9'b11_0011000;
    parameter RIGHT = 9'b11_0000000;
    parameter FRONT = 9'b10_1001000;
    parameter MIDDLE = 9'b10_0100100;
    parameter BACK = 9'b10_0000000;
    parameter IDLE = 9'b00_0000000;
    

    reg [8:0] cur_angle;
    wire clk_write;

    clock_divider #(27) divider(
        .clk(clk),
        .en(en),
        .clk_div(clk_write)
    );
    parameter [8:0] ZERO [0:4] = { //後 前 左 後 右
        IDLE, FRONT, LEFT, BACK, RIGHT
    };
    parameter [8:0] ONE [0:2] = {
        IDLE, FRONT, BACK
    };
    parameter [8:0] TWO [0:6] = { //後 左 中 右 前 左 右 
        IDLE, LEFT, MIDDLE, RIGHT, FRONT, LEFT, RIGHT
    };
    parameter [8:0] THREE [0:7] = { //後 左 右 中 左 右 前 左 (右)
        IDLE, LEFT, RIGHT, MIDDLE, LEFT, RIGHT, FRONT, LEFT
    };
    parameter [8:0] FOUR [0:6] = { //後 前 中 左 前 中 右
        IDLE, FRONT, MIDDLE, LEFT, FRONT, MIDDLE, RIGHT
    };
    parameter [8:0] FIVE [0:6] = { //後 左 右 中 左 前 右
        IDLE, LEFT, RIGHT, MIDDLE, LEFT, FRONT, RIGHT 
    };
    parameter [8:0] SIX [0:5] = { //後 中 左 前 後 右
        IDLE, MIDDLE, LEFT, FRONT, BACK, RIGHT
    };
    parameter [8:0] SEVEN [0:4] = { //前左右後
        IDLE, FRONT, LEFT, RIGHT, BACK
    };
    parameter [8:0] EIGHT [0:7] = { //左前右左前右後
        IDLE, LEFT, MIDDLE, RIGHT, LEFT, FRONT, RIGHT, BACK
    };
    parameter [8:0] NINE [0:7] = { //左右前左後右後
        IDLE, LEFT, RIGHT, FRONT, LEFT, MIDDLE, RIGHT, BACK
    };
    always @(*) begin
        case(num)
            4'd0: cur_angle = ZERO[index];
            4'd1: cur_angle = ONE[index];
            4'd2: cur_angle = TWO[index];
            4'd3: cur_angle = THREE[index];
            4'd4: cur_angle = FOUR[index];
            4'd5: cur_angle = FIVE[index];
            4'd6: cur_angle = SIX[index];
            4'd7: cur_angle = SEVEN[index];
            4'd8: cur_angle = EIGHT[index];
            4'd9: cur_angle = NINE[index];
            default: cur_angle = ONE[index];
        endcase
    end
    always @(posedge clk_write, posedge rst) begin
        if(rst)
            index <= 3'd0;
        else begin
            case(num) 
                4'd0: begin
                    if(index == 3'd4) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd1: begin
                    if(index == 3'd2) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd2: begin
                    if(index == 3'd6) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd3: begin
                    if(index == 3'd7) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd4: begin
                    if(index == 3'd6) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd5: begin
                    if(index == 3'd6) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd6: begin
                    if(index == 3'd5) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd7: begin
                    if(index == 3'd4) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd8: begin
                    if(index == 3'd7) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                4'd9: begin
                    if(index == 3'd7) index <= 3'd0;
                    else index <= index + 1'b1;
                end
                default: begin
                    if(index == 3'd2) index <= 3'd0;
                    else index <= index + 1'b1;
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

            if(cur_angle[8:7] == 2'b00)
                angle_left = 7'b0;
            else if(cur_angle[8:7] == 2'b01)
                angle_left = cur_angle[6:0];
            // else if(sw[1] == 1'b1) 
            //     angle_left = 7'b110000;
            else
                angle_left = angle_left;

            if(cur_angle[8:7] == 2'b00)
                angle_right = 7'b0;
            else if(cur_angle[8:7] == 2'b10)
                angle_right = cur_angle[6:0];
            // else if(sw[2] == 1'b1)
            //     angle_right = 7'b110000;
            else
                angle_right = angle_right;

            if(cur_angle[8:7] == 2'b00)
                angle_bottom = 7'b0;
            else if(cur_angle[8:7] == 2'b11)
                angle_bottom = cur_angle[6:0];
            // else if(sw[3] == 1'b1)
            //     angle_bottom = 7'b110000;
            else
                angle_bottom = angle_bottom;
        end
    // end
endmodule
