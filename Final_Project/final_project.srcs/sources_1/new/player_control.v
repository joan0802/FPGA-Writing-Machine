module player_control (
	input clk, 
	input reset, 
	input state, 
	output reg [11:0] ibeat
);
	// state
	parameter [1:0] IDLE = 2'b00;
	parameter [1:0] TYPING = 2'b01;
	parameter [1:0] WRITING = 2'b10;
	reg [11:0] LEN;
    reg [11:0] next_ibeat;

	always @(*) begin
		if(state == IDLE) begin
			LEN = 12'd0;
		end 
		else if(state == TYPING) begin
			LEN = 12'd512;
		end 
		else if(state == WRITING) begin
			LEN = 12'd192;
		end
	end

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
		end else begin
            ibeat <= next_ibeat;
		end
	end

    always @* begin
        next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : LEN-1;
    end

endmodule