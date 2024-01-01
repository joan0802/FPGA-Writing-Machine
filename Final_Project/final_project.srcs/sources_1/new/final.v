`timescale 1ns / 1ps

module final(
    input wire clk,
    input wire rst,
    input wire btnL,
    input wire btnR,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output reg [15:0] LED,
    output reg [3:0] digit,
    output reg [6:0] display
);

// state
parameter [1:0] IDLE = 2'b00;
parameter [1:0] TYPING = 2'b01;
parameter [1:0] WRITING = 2'b10;
reg [2:0] state, next_state;
// KEYBOARD
wire [125:0] key_down;
wire [8:0] last_change;
reg [8:0] pre_last_change, next_pre_last_change;
wire key_valid;
reg [3:0] key_num;
reg isPressed, next_isPressed;
integer i;
reg[15:0] num, next_num;
// 7-segment
reg [3:0] BCD0, BCD1, BCD2, BCD3;
reg [3:0] value;
wire clk_used;
clock_divider #(14) div1(.clk(clk), .clk_div(clk_used));

KeyboardDecoder kbd(
	.key_down(key_down),
	.last_change(last_change),
	.key_valid(key_valid),
	.PS2_DATA(PS2_DATA),
	.PS2_CLK(PS2_CLK),
	.rst(rst),
	.clk(clk)
);

parameter [8:0] KEY_CODES [0:21] = {
	9'b0_0100_0101,	// 0 => 45
	9'b0_0001_0110,	// 1 => 16
	9'b0_0001_1110,	// 2 => 1E
	9'b0_0010_0110,	// 3 => 26
	9'b0_0010_0101,	// 4 => 25
	9'b0_0010_1110,	// 5 => 2E
	9'b0_0011_0110,	// 6 => 36
	9'b0_0011_1101,	// 7 => 3D
	9'b0_0011_1110,	// 8 => 3E
	9'b0_0100_0110,	// 9 => 46
	
	9'b0_0111_0000, // right_0 => 70
	9'b0_0110_1001, // right_1 => 69
	9'b0_0111_0010, // right_2 => 72
	9'b0_0111_1010, // right_3 => 7A
	9'b0_0110_1011, // right_4 => 6B
	9'b0_0111_0011, // right_5 => 73
	9'b0_0111_0100, // right_6 => 74
	9'b0_0110_1100, // right_7 => 6C
	9'b0_0111_0101, // right_8 => 75
	9'b0_0111_1101, // right_9 => 7D
    9'b0_0110_0110, // BACK
    9'b0_0101_1010  // ENTER
};

always @(posedge clk_used, posedge rst) begin
	if(rst) begin
		num[3:0] <= 4'd10;
        num[7:4] <= 4'd10;
        num[11:8] <= 4'd10;
        num[15:12] <= 4'd10;
	end
	else begin
        num <= next_num;
    end
end

always @(*) begin
    if(rst) begin
        next_num[3:0] = 4'd10;
        next_num[7:4] = 4'd10;
        next_num[11:8] = 4'd10;
        next_num[15:12] = 4'd10;
    end
    else  begin
        // if(state == TYPING)
            if(key_valid == 1'b1 && key_down[last_change] == 1'b1 && (isPressed == 1'b0)) begin
                if(key_num <= 4'd9 && key_num >= 0) begin
                    next_num[15:12] = num[11:8];
                    next_num[11:8] = num[7:4];
                    next_num[7:4] = num[3:0];
                    next_num[3:0] = key_num;
                end
                else if(last_change == 9'b0_0110_0110) begin //BACK
                    next_num[3:0] = num[7:4];
                    next_num[7:4] = num[11:8];
                    next_num[11:8] = num[15:12];
                    next_num[15:12] = 4'd10;
                end
                else begin
                    next_num[3:0] = num[3:0];
                    next_num[7:4] = num[7:4];
                    next_num[11:8] = num[11:8];
                    next_num[15:12] = num[15:12];
                end
            end
        // end
    end
end

// KEYBOARD - KEY_CODES map to key_num
always @ (*) begin
	case (last_change)
		KEY_CODES[00] : key_num = 4'b0000;
		KEY_CODES[01] : key_num = 4'b0001;
		KEY_CODES[02] : key_num = 4'b0010;
		KEY_CODES[03] : key_num = 4'b0011;
		KEY_CODES[04] : key_num = 4'b0100;
		KEY_CODES[05] : key_num = 4'b0101;
		KEY_CODES[06] : key_num = 4'b0110;
		KEY_CODES[07] : key_num = 4'b0111;
		KEY_CODES[08] : key_num = 4'b1000;
		KEY_CODES[09] : key_num = 4'b1001;

		KEY_CODES[10] : key_num = 4'b0000;
		KEY_CODES[11] : key_num = 4'b0001;
		KEY_CODES[12] : key_num = 4'b0010;
		KEY_CODES[13] : key_num = 4'b0011;
		KEY_CODES[14] : key_num = 4'b0100;
		KEY_CODES[15] : key_num = 4'b0101;
		KEY_CODES[16] : key_num = 4'b0110;
		KEY_CODES[17] : key_num = 4'b0111;
		KEY_CODES[18] : key_num = 4'b1000;
		KEY_CODES[19] : key_num = 4'b1001;
		default		  : key_num = 4'b1111;
	endcase
end

// KEYBOARD - detect whether there are multiple keys pressed
always @(posedge clk, posedge rst) begin
	if(rst)
		isPressed <= 1'b0;
	else
		isPressed <= next_isPressed;	
end

always @(*) begin
	if(rst)
		next_isPressed = 1'b0;
	else begin
		// if(state == TYPING) begin
			next_isPressed = 1'b0;
			for(i = 0; i < 22; i = i + 1) begin
				if(key_down[KEY_CODES[i]] == 1'b1)
					next_isPressed = 1'b1;
				else
					next_isPressed = next_isPressed;
			end
		// end
		// else
		// 	next_isPressed = 1'b0;
	end
end

// 7 segment display
always @(posedge clk_used) begin
    case (digit)
        4'b1110 : begin
            value = BCD1;
            digit = 4'b1101;
        end
        4'b1101 : begin
            value = BCD2;
            digit = 4'b1011;
        end
        4'b1011 : begin
            value = BCD3;
            digit = 4'b0111;
        end
        4'b0111 : begin
            value = BCD0;
            digit = 4'b1110;
        end
        default : begin
            value = BCD0;
            digit = 4'b1110;
        end
    endcase
end

always @(*) begin
	case (state)
	// IDLE: begin
	// 	BCD0 = 4'd10;
	// 	BCD1 = 4'd10;
	// 	BCD2 = 4'd10;
	// 	BCD3 = 4'd10;
	// end
    // TYPING: begin
    // end
    // WRITING begin
    // end
	default: begin
		BCD0 = num[3:0];
		BCD1 = num[7:4];
		BCD2 = num[11:8];
		BCD3 = num[15:12];
	end
	endcase
end

always @(*) begin
    case(value)
        4'd0 : display = 7'b100_0000;
        4'd1 : display = 7'b111_1001;
        4'd2 : display = 7'b010_0100;
        4'd3 : display = 7'b011_0000;
        4'd4 : display = 7'b001_1001;
        4'd5 : display = 7'b001_0010;
        4'd6 : display = 7'b000_0010;
        4'd7 : display = 7'b111_1000;
        4'd8 : display = 7'b000_0000;
        4'd9 : display = 7'b001_0000;
        4'd10: display = 7'b011_1111; // NONE(-)
        default : display = 7'b111_1111;
    endcase
end

endmodule
