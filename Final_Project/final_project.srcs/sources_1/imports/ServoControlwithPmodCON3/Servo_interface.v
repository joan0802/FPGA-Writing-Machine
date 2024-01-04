`timescale 1ns / 1ps

module Servo_interface (
    input sw,
    input rst,
    input clk,
    input direction,
    output PWM
    );
    
    wire [17:0] A_net;
    wire [17:0] value_net;
    wire [6:0] angle_net;

    // Convert the switch value to an angle value.
    sw_to_angle convert(
        .sw(sw),
        .angle(angle_net)
        );
    
    // Convert the angle value to 
    // the constant value needed for the PWM.
    angle_decoder decode(
        .direction(direction),
        .angle(angle_net),
        .value(value_net)
        );
    
    // Compare the count value from the
    // counter, with the constant value set by
    // the switches.
    comparator compare(
        .A(A_net),
        .B(value_net),
        .PWM(PWM)
        );
      
    // Counts up to a certain value and then resets.
    // This module creates the refresh rate of 20ms.   
    counter count(
        .rst(rst),
        .clk(clk),
        .count(A_net)
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
        if(direction == 1'b1) 
            value = (10'd944)*(angle)+ 16'd60000;
        else 
            value = 16'd60000 - (10'd150)*(angle);
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
    input sw,
    output reg [6:0] angle
    );
    
    // Run when the value of the switches
    // changes
    always @ (sw)
    begin
        if(sw == 1'b0) angle = 7'd0;
        else angle = 7'd120;
    end
endmodule
