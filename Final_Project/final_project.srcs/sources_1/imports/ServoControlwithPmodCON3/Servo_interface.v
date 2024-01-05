`timescale 1ns / 1ps

module Servo_interface (
    input [3:0] sw,
    input rst,
    input clk,
    input en,
    input direction,
    input [15:0] num,
    output pwm_claw,
    output pwm_left,
    output pwm_right,
    output pwm_bottom
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
        .rst(rst)
        );
    
    // Convert the angle value to 
    // the constant value needed for the PWM.
    angle_decoder decode_claw(
        .direction(direction),
        .angle(angle_claw),
        .value(value_claw)
        );
    angle_decoder decode_left(
        .direction(direction),
        .angle(angle_left),
        .value(value_left)
        );
    angle_decoder decode_right(
        .direction(direction),
        .angle(angle_right),
        .value(value_right)
        );
    angle_decoder decode_bottom(
        .direction(direction),
        .angle(angle_bottom),
        .value(value_bottom)
        );
    
    // Compare the count value from the
    // counter, with the constant value set by
    // the switches.
    comparator compare_claw(
        .A(count_max),
        .B(value_claw),
        .PWM(pwm_claw)
        );
    comparator compare_left(
        .A(count_max),
        .B(value_left),
        .PWM(pwm_left)
        );
    comparator compare_right(
        .A(count_max),
        .B(value_right),
        .PWM(pwm_right)
        );
    comparator compare_bottom(
        .A(count_max),
        .B(value_bottom),
        .PWM(pwm_bottom)
        );
      
    // Counts up to a certain value and then resets.
    // This module creates the refresh rate of 20ms.   
    counter count(
        .rst(rst),
        .clk(clk),
        .count(count_max)
        );
        
endmodule

module angle_decoder(
    input [6:0] angle,
    input direction,
    output reg [17:0] value
    );
    
    // Run when angle changes
    always @ (angle, direction)begin
        // The angle gets converted to the 
        // constant value. This equation
        // depends on the servo motor you are 
        // using. To get this equation I used 
        // trial and error to get the 0
        // and 360 values and created an equation
        // based on those two points. 

        // value = 16'd60000 - (10'd300)*(angle);
        // if(direction == 1'b1) 
        value = (10'd944)*(angle)+ 16'd60000;
        // else 
        //     // value = 25000;
        //     value = (10'd944)*(angle)+ 16'd25000;
            // value = 16'd60000 - (10'd300)*(angle);
        // value = (10'd944)*(angle)+ 16'd60000;
    end
endmodule

module comparator (
	input [19:0] A,
	input [19:0] B,
	output reg PWM
);

    // Run when A or B change
	always @ (A,B)
	begin
	// If A is less than B
	// output is 1.
	if (A < B)
		begin
		PWM <= 1'b1;
		end
	// If A is greater than B
	// output is 0.
	else 
		begin
		PWM <= 1'b0;
		end
	end
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
    output reg [6:0] angle_claw,
    output reg [6:0] angle_left,
    output reg [6:0] angle_right,
    output reg [6:0] angle_bottom
    );

    reg [8:0] cur_angle;
    reg [2:0] index;
    wire clk_write;

    clock_divider #(27) divider(
        .clk(clk),
        .en(en),
        .clk_div(clk_write)
    );
    // parameter [9:0] ZERO [0:3] = {
    //     9'b10_1001000,
    // };
    parameter [8:0] ONE [0:2] = {
        9'b10_0, 9'b10_1001000, 9'b10_0
    };
    // parameter [8:0] TWO [0:21] = {

    // };
    // parameter [8:0] THREE [0:21] = {

    // };
    // parameter [8:0] FOUR [0:21] = {

    // };
    // parameter [8:0] FIVE [0:21] = {

    // };
    // parameter [8:0] SIX [0:21] = {

    // };
    // parameter [8:0] SEVEN [0:21] = {

    // };
    // parameter [8:0] EIGHT [0:21] = {

    // };
    // parameter [8:0] NINE [0:21] = {

    // };
    always @(*) begin
        case(num)
            // 4'd0: cur_angle = ZERO[index];
            4'd1: cur_angle = ONE[index];
            // 4'd2: cur_angle = TWO[index];
            // 4'd3: cur_angle = THREE[index];
            // 4'd4: cur_angle = FOUR[index];
            // 4'd5: cur_angle = FIVE[index];
            // 4'd6: cur_angle = SIX[index];
            // 4'd7: cur_angle = SEVEN[index];
            // 4'd8: cur_angle = EIGHT[index];
            // 4'd9: cur_angle = NINE[index];
            default: cur_angle = ONE[index];
        endcase
    end
    always @(posedge clk_write, posedge rst) begin
        if(rst)
            index <= 3'd0;
        else begin
            if(index == 3'd2)
                index <= 3'd0;
            else
                index <= index + 1'b1;
        end
    end
    
    
    // Run when the value of the switches
    // changes
    // reg claw, left, right, bottom;
    always @ (*)
    begin
        // if(sw[0] == 1'b0) 
        //     angle_claw = 7'd0; // counterclockwise
        // else if(sw[0] == 1'b1)
        //     angle_claw = 7'b110000;
        if(sw[0] == 1'b1) 
            angle_claw = 7'b0;
        else
            angle_claw = 7'b110000;

        if(cur_angle[8:7] == 2'b01)
            angle_left = cur_angle[6:0];
        else if(sw[1] == 1'b1) 
            angle_left = 7'b110000;
        else
            angle_left = 7'd0;

        if(cur_angle[8:7] == 2'b10)
            angle_right = cur_angle[6:0];
        else if(sw[2] == 1'b1)
            angle_right = 7'b110000;
        else
            angle_right = 7'd0;

        if(cur_angle[8:7] == 2'b11)
            angle_bottom = cur_angle[6:0];
        else if(sw[3] == 1'b1)
            angle_bottom = 7'b110000;
        else
            angle_bottom = 7'd0;
    end
endmodule
