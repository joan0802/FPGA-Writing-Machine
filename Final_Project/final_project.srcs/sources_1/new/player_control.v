module player_control (
	input clk, 
	input reset, 
	input [1:0] state, 
	input [125:0] key_down,
	input isPressed,
	input [8:0] last_change,
	input key_valid,
	output reg [11:0] ibeat1,
    output reg [11:0] ibeat2
);
	// state
	parameter IDLE = 2'b00;
	parameter TYPING = 2'b01;
	parameter WRITING = 2'b10;

	parameter LEN_start = 60;
	parameter LEN_end = 192;
	parameter coin_end = 84;
    
	reg [11:0] next_ibeat1, next_ibeat2;
	// assign ibeat = (state == TYPING) ? next_ibeat1 : next_ibeat2;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat1 <= 0;
            ibeat2 <= 0;
		end 
        else begin
			if((key_valid == 1'b1 && key_down[last_change] == 1'b1 && (isPressed == 1'b0)))
				ibeat1 <= 61;
			else
            	ibeat1 <= next_ibeat1;
            ibeat2 <= next_ibeat2;
        end
	end

    always @* begin
		if(reset) begin
			next_ibeat1 = 0;
			next_ibeat2 = 0;
		end
		else begin
			if(state == TYPING) begin
				if(ibeat1 > 60) begin	
					next_ibeat1 = 0;
					// next_ibeat1 = (ibeat1 + 1 < coin_end) ? (ibeat1 + 1) : coin_end;
				end
				else
					next_ibeat1 = (ibeat1 + 2 < LEN_start) ? (ibeat1 + 2) : LEN_start;
				next_ibeat2 = 0;
			end
			else if(state == WRITING) begin
				next_ibeat2 = (ibeat2 + 1 < LEN_end) ? (ibeat2 + 1) : LEN_end;
				next_ibeat1 = 0;
			end
			else begin
				next_ibeat1 = 0;
				next_ibeat2 = 0;
			end
		end
	end

endmodule
