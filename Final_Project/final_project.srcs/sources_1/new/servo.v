module servo(
    input clk,
    input rst,
    input SW0,
    input [2:0]mode,
    // output [3:0]pwm,
    output reg r_IN,
    output reg l_IN,
    output reg claw_IN,
    output reg b_IN
);

    wire left_pwm, right_pwm, claw_pwm, bottom_pwm;
    reg[1:0] l_state, r_state, claw_state, b_state;

    parameter IDLE  = 0;  
    parameter LEFT  = 1;  
    parameter RIGHT = 2; 

    servo_pwm m0(clk, rst, l_state, left_pwm);
    servo_pwm m1(clk, rst, r_state, right_pwm);
    servo_pwm m2(clk, rst, claw_state, claw_pwm);
    servo_pwm m3(clk, rst, b_state, bottom_pwm);

    // assign pwm = {claw_pwm, left_pwm, right_pwm, bottom_pwm};

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            l_IN <= 0;
            r_IN <= 0;
            claw_IN <= 0;
            b_IN <= 0;
        end
        else begin
            if (claw_pwm)
                claw_IN <= 1;
            else
                claw_IN <= 0;
            if (left_pwm)
                l_IN <= 1;
            else
                l_IN <= 0;
            if (right_pwm)
                r_IN <= 1;
            else
                r_IN <= 0;
            if (bottom_pwm)
                b_IN <= 1;
            else
                b_IN <= 0;
        end
    end


    always @(*) begin
        if(rst) begin
            l_state = IDLE;
            r_state = IDLE;
            claw_state = IDLE;
            b_state = IDLE;
        end
        else begin
            claw_state = (SW0 == 1'b1) ? LEFT : RIGHT;
            l_state = LEFT;
            r_state = RIGHT;
        end
    end

endmodule

module servo_pwm (
    input clk,
    input reset,
    input [1:0] state,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .state(state), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
    input [1:0] state,
    output reg PWM
);
    parameter idle_state  = 75000;
    parameter left_state  = 25000;
    parameter right_state = 125000; 
    wire [16:0] duty = (state == 2'b00) ? idle_state : 
                        (state == 2'b01) ? left_state : right_state; 
    parameter count_max = 1000000;
    reg [21:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            if(count < duty)
                PWM <= 1;
            else
                PWM <= 0;
        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule
