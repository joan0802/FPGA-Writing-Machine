module player_control (
	input clk, 
	input reset, 
	input state, 
	output reg [11:0] ibeat
);
	// state
	parameter IDLE = 2'b00;
	parameter TYPING = 2'b01;
	parameter WRITING = 2'b10;

	parameter LEN_start = 60;
	parameter LEN_end = 192;
    
	reg [11:0] next_ibeat1, next_ibeat2;
	// assign ibeat = (state == TYPING) ? next_ibeat1 : next_ibeat2;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
		end else begin
			if(state == TYPING)
				ibeat <= next_ibeat1;
			else if(state == WRITING)
				ibeat <= next_ibeat2;
            else
				ibeat <= 0;
		end
	end

    always @* begin
		if(reset) begin
			next_ibeat1 = 0;
			next_ibeat2 = 0;
		end
		else begin
			if(state == TYPING) begin
				next_ibeat1 = (ibeat + 1 < LEN_start) ? (ibeat + 1) : LEN_start;
				next_ibeat2 = 0;
			end
			else if(state == WRITING) begin
				next_ibeat2 = (ibeat + 1 < LEN_end) ? (ibeat + 1) : LEN_end;
				next_ibeat1 = 0;
			end
			else begin
				next_ibeat1 = 0;
				next_ibeat2 = 0;
			end
		end
	end

endmodule
