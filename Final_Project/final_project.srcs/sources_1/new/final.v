`define lc  32'd131   // C3
`define ld  32'd147   // D3
`define lbe 32'd156
`define le  32'd165   // E3
`define lf  32'd174   // F3
`define lg  32'd196   // G3
`define lba 32'd208
`define la  32'd220   // A3
`define lb  32'd247   // B3
`define lbb 32'd233
`define c   32'd262   // C4
`define d   32'd294   // D4
`define be  32'd311
`define e   32'd330   // E4
`define f   32'd349   // F4
`define g   32'd392   // G4
`define ba  32'd415
`define a   32'd440   // A4
`define bb  32'd466
`define b   32'd494   // B4
`define hc  32'd523   // C5
`define hd  32'd587   // D5
`define hbe 32'd622 
`define he  32'd659   // E5
`define hf  32'd698   // F5
`define hg  32'd784   // G5 
`define hba 32'd831 
`define ha  32'd880   // A5
`define hbb 32'd932
`define hb  32'd988   // B5
`define hhc 32'd1047
`define hhe 32'd1319
`define sil   32'd50000000 // slience

module final(
    input wire clk,
    input wire rst,
    input wire btnL,
    input wire btnR,
	input wire SW0,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output reg [15:0] LED,
	output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin, // serial audio data input
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
// Writing
reg finish_writing;
// Audio
wire [15:0] audio_in_left, audio_in_right;
wire [11:0] ibeat1, ibeat2;
wire [11:0] ibeatNum;               // Beat counter
wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3
wire clk_div22;

clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clk_div22));
assign freq_outL = 50000000 / freqL;
assign freq_outR = 50000000 / freqR;
assign ibeatNum = (state == TYPING) ? ibeat1 :
				(state == WRITING) ? ibeat2 : 0;

KeyboardDecoder kbd(
	.key_down(key_down),
	.last_change(last_change),
	.key_valid(key_valid),
	.PS2_DATA(PS2_DATA),
	.PS2_CLK(PS2_CLK),
	.rst(rst),
	.clk(clk)
);

player_control playerCtrl_00 ( 
	.clk(clk_div22),
	.reset(rst),
	.state(state),
	.ibeat1(ibeat1),
	.ibeat2(ibeat2),
	.isPressed(isPressed),
	.key_down(key_down),
	.last_change(last_change),
	.key_valid(key_valid)
);

speaker_control sc(
	.clk(clk), 
	.rst(rst), 
	.audio_in_left(audio_in_left),      // left channel audio data input
	.audio_in_right(audio_in_right),    // right channel audio data input
	.audio_mclk(audio_mclk),            // master clock
	.audio_lrck(audio_lrck),            // left-right clock
	.audio_sck(audio_sck),              // serial clock
	.audio_sdin(audio_sdin)             // serial audio data input
);

note_gen noteGen_00(
	.clk(clk), 
	.rst(rst), 
	.note_div_left(freq_outL), 
	.note_div_right(freq_outR), 
	.audio_left(audio_in_left),     // left sound audio
	.audio_right(audio_in_right)    // right sound audio
);

music music_00 (
	.ibeatNum(ibeatNum),
	.state(state),
	.rst(rst),
	.clk(clk),
	.toneL(freqL),
	.toneR(freqR)
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
// state transition
always @* begin
	if(rst) next_state = IDLE;
	else begin
		next_state = state;
		case (state)
			IDLE: begin
				if(btnR == 1'b1) next_state = TYPING;
			end
			TYPING: begin //enter
				if(key_valid == 1'b1 && key_down[last_change] == 1'b1) begin
					if(last_change == 9'b0_0101_1010) next_state = WRITING;
				end
			end
			WRITING: begin
				if(finish_writing == 1'b1) next_state = IDLE;
			end
			default: next_state = IDLE;
		endcase
	end
end
// state transition
always @(posedge clk or posedge rst) begin
	if(rst) state <= IDLE;
	else state <= next_state;
end

// LED
reg [15:0] next_led;
always @(posedge clk or posedge rst) begin
	if (rst) begin
		LED <= 16'b1111_0000_0000_0000;
	end
	else begin
		LED <= next_led;
	end
end
always @* begin
	if(rst) begin
		next_led = 16'b1111_0000_0000_0000;
	end
	else begin
		next_led = 16'd0;
		case(state)
			IDLE: next_led[15:12] = 4'b1111;
			TYPING: next_led[11:8] = 4'b1111;
			WRITING: next_led[7:4] = 4'b1111;
		endcase

		if(SW0) next_led[0] = 1'b1;
		else next_led[0] = 1'b0;
	end
end

// Write
always @* begin
	if(rst) begin
		finish_writing = 1'b0;
	end
	else begin
		finish_writing = 1'b0;
		if(state == WRITING) begin
			if(btnL == 1'b1) begin
				finish_writing = 1'b1;
			end
		end
	end
end
// num
always @(posedge clk_used, posedge rst) begin
	if(rst) begin
		num[3:0] <= 4'd10;
        num[7:4] <= 4'd10;
        num[11:8] <= 4'd10;
        num[15:12] <= 4'd10;
	end
	else begin
		if(state == IDLE) begin
			num[3:0] <= 4'd10;
			num[7:4] <= 4'd10;
			num[11:8] <= 4'd10;
			num[15:12] <= 4'd10;
		end
		else
        	num <= next_num;
    end
end
// num
always @(*) begin
    if(rst) begin
        next_num[3:0] = 4'd10;
        next_num[7:4] = 4'd10;
        next_num[11:8] = 4'd10;
        next_num[15:12] = 4'd10;
    end
    else begin
        if(state == TYPING) begin
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
                    next_num = next_num;
                end
            end
			else
				next_num = next_num;
		end
		else if(state == WRITING)
			next_num = next_num;
		else begin // IDLE
			next_num[3:0] = 4'd10;
			next_num[7:4] = 4'd10;
			next_num[11:8] = 4'd10;
			next_num[15:12] = 4'd10;
		end
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
		if(state == TYPING) begin
			next_isPressed = 1'b0;
			for(i = 0; i < 22; i = i + 1) begin
				if(key_down[KEY_CODES[i]] == 1'b1)
					next_isPressed = 1'b1;
				else
					next_isPressed = next_isPressed;
			end
		end
		else
			next_isPressed = 1'b0;
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
// BCD
always @(*) begin
	case (state)
	IDLE: begin
		BCD0 = 4'd10;
		BCD1 = 4'd10;
		BCD2 = 4'd10;
		BCD3 = 4'd10;
	end
	default: begin
		BCD0 = num[3:0];
		BCD1 = num[7:4];
		BCD2 = num[11:8];
		BCD3 = num[15:12];
	end
	endcase
end
// display
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

module music (
	input [11:0] ibeatNum,
    input rst,
    input clk,
    input [2:0] state,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);
	// state
	parameter [1:0] IDLE = 2'b00;
	parameter [1:0] TYPING = 2'b01;
	parameter [1:0] WRITING = 2'b10;

    always @* begin
        if(rst) begin
            toneR = `sil;
        end
        else if(state == TYPING) begin
            case(ibeatNum)
				// Start
				12'd0: toneR = `he;  12'd1: toneR = `he;
				12'd2: toneR = `he;  12'd3: toneR = `he;
				12'd4: toneR = `he;  12'd5: toneR = `he;
				12'd6: toneR = `he;  12'd7: toneR = `he;
				12'd8: toneR = `he;  12'd9: toneR = `he;
				12'd10: toneR = `he;  12'd11: toneR = `he;
				12'd12: toneR = `sil;  12'd13: toneR = `sil;
				12'd14: toneR = `sil;  12'd15: toneR = `sil;
				12'd16: toneR = `sil;  12'd17: toneR = `sil;
				12'd18: toneR = `he;  12'd19: toneR = `he;
				12'd20: toneR = `he;  12'd21: toneR = `he;
				12'd22: toneR = `he;  12'd23: toneR = `he;
				12'd24: toneR = `sil;  12'd25: toneR = `sil;
				12'd26: toneR = `sil;  12'd27: toneR = `sil;
				12'd28: toneR = `sil;  12'd29: toneR = `sil;
				12'd30: toneR = `hc;  12'd31: toneR = `hc;
				12'd32: toneR = `hc;  12'd33: toneR = `hc;
				12'd34: toneR = `hc;  12'd35: toneR = `hc;
				12'd36: toneR = `he;  12'd37: toneR = `he;
				12'd38: toneR = `he;  12'd39: toneR = `he;
				12'd40: toneR = `he;  12'd41: toneR = `he;
				12'd42: toneR = `he;  12'd43: toneR = `he;
				12'd44: toneR = `he;  12'd45: toneR = `he;
				12'd46: toneR = `he;  12'd47: toneR = `he;
				12'd48: toneR = `hg;  12'd49: toneR = `hg;
				12'd50: toneR = `hg;  12'd51: toneR = `hg;
				12'd52: toneR = `hg;  12'd53: toneR = `hg;
				12'd54: toneR = `hg;  12'd55: toneR = `hg;
				12'd56: toneR = `hg;  12'd57: toneR = `hg;
				12'd58: toneR = `hg;  12'd59: toneR = `hg;
				// Coin
				12'd60: toneR = `sil;  12'd61: toneR = `hb;
				12'd62: toneR = `hb;  12'd63: toneR = `hb;
				12'd64: toneR = `hb;  12'd65: toneR = `hb;
				12'd66: toneR = `hhe;  12'd67: toneR = `hhe;
				12'd68: toneR = `hhe;  12'd69: toneR = `hhe;
				12'd70: toneR = `hhe;  12'd71: toneR = `hhe;
				12'd72: toneR = `hhe;  12'd73: toneR = `hhe;
				12'd74: toneR = `hhe;  12'd75: toneR = `hhe;
				12'd76: toneR = `hhe;  12'd77: toneR = `hhe;
				12'd78: toneR = `hhe;  12'd79: toneR = `hhe;
				12'd80: toneR = `hhe;  12'd81: toneR = `hhe;
				12'd82: toneR = `hhe;  12'd83: toneR = `hhe;
                default: toneR = `sil;
            endcase
        end
		else if(state == WRITING) begin
            case(ibeatNum)
				// End
				12'd0: toneR = `sil;  12'd1: toneR = `sil;
				12'd2: toneR = `sil;  12'd3: toneR = `sil;
				12'd4: toneR = `c;  12'd5: toneR = `c;
				12'd6: toneR = `c;  12'd7: toneR = `c;
				12'd8: toneR = `e;  12'd9: toneR = `e;
				12'd10: toneR = `e;  12'd11: toneR = `e;
				12'd12: toneR = `g;  12'd13: toneR = `g;
				12'd14: toneR = `g;  12'd15: toneR = `g;
				12'd16: toneR = `hc;  12'd17: toneR = `hc;
				12'd18: toneR = `hc;  12'd19: toneR = `hc;
				12'd20: toneR = `he;  12'd21: toneR = `he;
				12'd22: toneR = `he;  12'd23: toneR = `he;
				12'd24: toneR = `hg;  12'd25: toneR = `hg;
				12'd26: toneR = `hg;  12'd27: toneR = `hg;
				12'd28: toneR = `hg;  12'd29: toneR = `hg;
				12'd30: toneR = `hg;  12'd31: toneR = `hg;
				12'd32: toneR = `hg;  12'd33: toneR = `hg;
				12'd34: toneR = `hg;  12'd35: toneR = `hg;
				12'd36: toneR = `he;  12'd37: toneR = `he;
				12'd38: toneR = `he;  12'd39: toneR = `he;
				12'd40: toneR = `he;  12'd41: toneR = `he;
				12'd42: toneR = `sil;  12'd43: toneR = `sil;
				12'd44: toneR = `sil;  12'd45: toneR = `sil;
				12'd46: toneR = `sil;  12'd47: toneR = `sil;
				12'd48: toneR = `sil;  12'd49: toneR = `sil;
				12'd50: toneR = `sil;  12'd51: toneR = `sil;
				12'd52: toneR = `c;  12'd53: toneR = `c;
				12'd54: toneR = `c;  12'd55: toneR = `c;
				12'd56: toneR = `be;  12'd57: toneR = `be;
				12'd58: toneR = `be;  12'd59: toneR = `be;
				12'd60: toneR = `ba;  12'd61: toneR = `ba;
				12'd62: toneR = `ba;  12'd63: toneR = `ba;
				12'd64: toneR = `hc;  12'd65: toneR = `hc;
				12'd66: toneR = `hc;  12'd67: toneR = `hc;
				12'd68: toneR = `hbe;  12'd69: toneR = `hbe;
				12'd70: toneR = `hbe;  12'd71: toneR = `hbe;
				12'd72: toneR = `hba;  12'd73: toneR = `hba;
				12'd74: toneR = `hba;  12'd75: toneR = `hba;
				12'd76: toneR = `hba;  12'd77: toneR = `hba;
				12'd78: toneR = `hba;  12'd79: toneR = `hba;
				12'd80: toneR = `hba;  12'd81: toneR = `hba;
				12'd82: toneR = `hba;  12'd83: toneR = `hba;
				12'd84: toneR = `hf;  12'd85: toneR = `hf;
				12'd86: toneR = `hf;  12'd87: toneR = `hf;
				12'd88: toneR = `hf;  12'd89: toneR = `hf;
				12'd90: toneR = `sil;  12'd91: toneR = `sil;
				12'd92: toneR = `sil;  12'd93: toneR = `sil;
				12'd94: toneR = `sil;  12'd95: toneR = `sil;
				12'd96: toneR = `sil;  12'd97: toneR = `sil;
				12'd98: toneR = `sil;  12'd99: toneR = `sil;
				12'd100: toneR = `d;  12'd101: toneR = `d;
				12'd102: toneR = `d;  12'd103: toneR = `d;
				12'd104: toneR = `f;  12'd105: toneR = `f;
				12'd106: toneR = `f;  12'd107: toneR = `f;
				12'd108: toneR = `bb;  12'd109: toneR = `bb;
				12'd110: toneR = `bb;  12'd111: toneR = `bb;
				12'd112: toneR = `hd;  12'd113: toneR = `hd;
				12'd114: toneR = `hd;  12'd115: toneR = `hd;
				12'd116: toneR = `hf;  12'd117: toneR = `hf;
				12'd118: toneR = `hf;  12'd119: toneR = `hf;
				12'd120: toneR = `hbb;  12'd121: toneR = `hbb;
				12'd122: toneR = `hbb;  12'd123: toneR = `hbb;
				12'd124: toneR = `hbb;  12'd125: toneR = `hbb;
				12'd126: toneR = `hbb;  12'd127: toneR = `hbb;
				12'd128: toneR = `hbb;  12'd129: toneR = `hbb;
				12'd130: toneR = `hbb;  12'd131: toneR = `hbb;
				12'd132: toneR = `hb;  12'd133: toneR = `hb;
				12'd134: toneR = `sil;  12'd135: toneR = `sil;
				12'd136: toneR = `hb;  12'd137: toneR = `hb;
				12'd138: toneR = `sil;  12'd139: toneR = `sil;
				12'd140: toneR = `hb;  12'd141: toneR = `hb;
				12'd142: toneR = `hb;  12'd143: toneR = `hb;
				12'd144: toneR = `hhc;  12'd145: toneR = `hhc;
				12'd146: toneR = `hhc;  12'd147: toneR = `hhc;
				12'd148: toneR = `hhc;  12'd149: toneR = `hhc;
				12'd150: toneR = `hhc;  12'd151: toneR = `hhc;
				12'd152: toneR = `hhc;  12'd153: toneR = `hhc;
				12'd154: toneR = `hhc;  12'd155: toneR = `hhc;
				12'd156: toneR = `hhc;  12'd157: toneR = `hhc;
				12'd158: toneR = `hhc;  12'd159: toneR = `hhc;
				12'd160: toneR = `hhc;  12'd161: toneR = `hhc;
				12'd162: toneR = `hhc;  12'd163: toneR = `hhc;
				12'd164: toneR = `hhc;  12'd165: toneR = `hhc;
				12'd166: toneR = `hhc;  12'd167: toneR = `hhc;
				12'd168: toneR = `hhc;  12'd169: toneR = `hhc;
				12'd170: toneR = `hhc;  12'd171: toneR = `hhc;
				12'd172: toneR = `hhc;  12'd173: toneR = `hhc;
				12'd174: toneR = `hhc;  12'd175: toneR = `hhc;
				12'd176: toneR = `hhc;  12'd177: toneR = `hhc;
				12'd178: toneR = `hhc;  12'd179: toneR = `hhc;
				12'd180: toneR = `hhc;  12'd181: toneR = `hhc;
				12'd182: toneR = `hhc;  12'd183: toneR = `hhc;
				12'd184: toneR = `hhc;  12'd185: toneR = `hhc;
				12'd186: toneR = `hhc;  12'd187: toneR = `hhc;
				12'd188: toneR = `hhc;  12'd189: toneR = `hhc;
				12'd190: toneR = `hhc;  12'd191: toneR = `hhc;
				default: toneR = `sil;
			endcase
        end
		else
			toneR = `sil;
    end

    always @(*) begin
        if(rst) begin
            toneL = `sil;
        end
        else if(state == TYPING) begin
            case(ibeatNum)
                // Start
				12'd0: toneL= `le;  12'd1: toneL= `le;
				12'd2: toneL= `le;  12'd3: toneL= `le;
				12'd4: toneL= `le;  12'd5: toneL= `le;
				12'd6: toneL= `le;  12'd7: toneL= `le;
				12'd8: toneL= `le;  12'd9: toneL= `le;
				12'd10: toneL= `le;  12'd11: toneL= `le;
				12'd12: toneL= `le;  12'd13: toneL= `le;
				12'd14: toneL= `le;  12'd15: toneL= `le;
				12'd16: toneL= `le;  12'd17: toneL= `le;
				12'd18: toneL= `le;  12'd19: toneL= `le;
				12'd20: toneL= `le;  12'd21: toneL= `le;
				12'd22: toneL= `le;  12'd23: toneL= `le;
				12'd24: toneL= `le;  12'd25: toneL= `le;
				12'd26: toneL= `le;  12'd27: toneL= `le;
				12'd28: toneL= `le;  12'd29: toneL= `le;
				12'd30: toneL= `le;  12'd31: toneL= `le;
				12'd32: toneL= `le;  12'd33: toneL= `le;
				12'd34: toneL= `le;  12'd35: toneL= `le;
				12'd36: toneL= `le;  12'd37: toneL= `le;
				12'd38: toneL= `le;  12'd39: toneL= `le;
				12'd40: toneL= `le;  12'd41: toneL= `le;
				12'd42: toneL= `le;  12'd43: toneL= `le;
				12'd44: toneL= `le;  12'd45: toneL= `le;
				12'd46: toneL= `le;  12'd47: toneL= `le;
				12'd48: toneL= `la;  12'd49: toneL= `la;
				12'd50: toneL= `la;  12'd51: toneL= `la;
				12'd52: toneL= `la;  12'd53: toneL= `la;
				12'd54: toneL= `la;  12'd55: toneL= `la;
				12'd56: toneL= `la;  12'd57: toneL= `la;
				12'd58: toneL = `la;  12'd59: toneL = `la;
				// Coin
				12'd60: toneL = `sil;  12'd61: toneL = `hb;
				12'd62: toneL = `hb;  12'd63: toneL = `hb;
				12'd64: toneL = `hb;  12'd65: toneL = `hb;
				12'd66: toneL = `hhe;  12'd67: toneL = `hhe;
				12'd68: toneL = `hhe;  12'd69: toneL = `hhe;
				12'd70: toneL = `hhe;  12'd71: toneL = `hhe;
				12'd72: toneL = `hhe;  12'd73: toneL = `hhe;
				12'd74: toneL = `hhe;  12'd75: toneL = `hhe;
				12'd76: toneL = `hhe;  12'd77: toneL = `hhe;
				12'd78: toneL = `hhe;  12'd79: toneL = `hhe;
				12'd80: toneL = `hhe;  12'd81: toneL = `hhe;
				12'd82: toneL = `hhe;  12'd83: toneL = `hhe;
                default: toneL= `sil;
            endcase
        end
        else if(state == WRITING) begin
            case(ibeatNum)
				// End
				12'd0: toneL = `lg;  12'd1: toneL = `lg;
				12'd2: toneL = `lg;  12'd3: toneL = `lg;
				12'd4: toneL = `le;  12'd5: toneL = `le;
				12'd6: toneL = `le;  12'd7: toneL = `le;
				12'd8: toneL = `lg;  12'd9: toneL = `lg;
				12'd10: toneL = `lg;  12'd11: toneL = `lg;
				12'd12: toneL = `le;  12'd13: toneL = `le;
				12'd14: toneL = `le;  12'd15: toneL = `le;
				12'd16: toneL = `lg;  12'd17: toneL = `lg;
				12'd18: toneL = `lg;  12'd19: toneL = `lg;
				12'd20: toneL = `c;  12'd21: toneL = `c;
				12'd22: toneL = `c;  12'd23: toneL = `c;
				12'd24: toneL = `e;  12'd25: toneL = `e;
				12'd26: toneL = `e;  12'd27: toneL = `e;
				12'd28: toneL = `e;  12'd29: toneL = `e;
				12'd30: toneL = `e;  12'd31: toneL = `e;
				12'd32: toneL = `e;  12'd33: toneL = `e;
				12'd34: toneL = `e;  12'd35: toneL = `e;
				12'd36: toneL = `c;  12'd37: toneL = `c;
				12'd38: toneL = `c;  12'd39: toneL = `c;
				12'd40: toneL = `c;  12'd41: toneL = `c;
				12'd42: toneL = `sil;  12'd43: toneL = `sil;
				12'd44: toneL = `sil;  12'd45: toneL = `sil;
				12'd46: toneL = `sil;  12'd47: toneL = `sil;
				12'd48: toneL = `lba;  12'd49: toneL = `lba;
				12'd50: toneL = `lba;  12'd51: toneL = `lba;
				12'd52: toneL = `lbe;  12'd53: toneL = `lbe;
				12'd54: toneL = `lbe;  12'd55: toneL = `lbe;
				12'd56: toneL = `la;  12'd57: toneL = `la;
				12'd58: toneL = `la;  12'd59: toneL = `la;
				12'd60: toneL = `le;  12'd61: toneL = `le;
				12'd62: toneL = `le;  12'd63: toneL = `le;
				12'd64: toneL = `la;  12'd65: toneL = `la;
				12'd66: toneL = `la;  12'd67: toneL = `la;
				12'd68: toneL = `c;  12'd69: toneL = `c;
				12'd70: toneL = `c;  12'd71: toneL = `c;
				12'd72: toneL = `be;  12'd73: toneL = `be;
				12'd74: toneL = `be;  12'd75: toneL = `be;
				12'd76: toneL = `be;  12'd77: toneL = `be;
				12'd78: toneL = `be;  12'd79: toneL = `be;
				12'd80: toneL = `be;  12'd81: toneL = `be;
				12'd82: toneL = `be;  12'd83: toneL = `be;
				12'd84: toneL = `c;  12'd85: toneL = `c;
				12'd86: toneL = `c;  12'd87: toneL = `c;
				12'd88: toneL = `c;  12'd89: toneL = `c;
				12'd90: toneL = `sil;  12'd91: toneL = `sil;
				12'd92: toneL = `sil;  12'd93: toneL = `sil;
				12'd94: toneL = `sil;  12'd95: toneL = `sil;
				12'd96: toneL = `lbb;  12'd97: toneL = `lbb;
				12'd98: toneL = `lbb;  12'd99: toneL = `lbb;
				12'd100: toneL = `lf;  12'd101: toneL = `lf;
				12'd102: toneL = `lf;  12'd103: toneL = `lf;
				12'd104: toneL = `lb;  12'd105: toneL = `lb;
				12'd106: toneL = `lb;  12'd107: toneL = `lb;
				12'd108: toneL = `lf;  12'd109: toneL = `lf;
				12'd110: toneL = `lf;  12'd111: toneL = `lf;
				12'd112: toneL = `lb;  12'd113: toneL = `lb;
				12'd114: toneL = `lb;  12'd115: toneL = `lb;
				12'd116: toneL = `d;  12'd117: toneL = `d;
				12'd118: toneL = `d;  12'd119: toneL = `d;
				12'd120: toneL = `f;  12'd121: toneL = `f;
				12'd122: toneL = `f;  12'd123: toneL = `f;
				12'd124: toneL = `f;  12'd125: toneL = `f;
				12'd126: toneL = `f;  12'd127: toneL = `f;
				12'd128: toneL = `f;  12'd129: toneL = `f;
				12'd130: toneL = `f;  12'd131: toneL = `f;
				12'd132: toneL = `d;  12'd133: toneL = `d;
				12'd134: toneL = `d;  12'd135: toneL = `sil;
				12'd136: toneL = `d;  12'd137: toneL = `d;
				12'd138: toneL = `d;  12'd139: toneL = `sil;
				12'd140: toneL = `d;  12'd141: toneL = `d;
				12'd142: toneL = `d;  12'd143: toneL = `d;
				12'd144: toneL = `c;  12'd145: toneL = `c;
				12'd146: toneL = `c;  12'd147: toneL = `c;
				12'd148: toneL = `c;  12'd149: toneL = `c;
				12'd150: toneL = `c;  12'd151: toneL = `c;
				12'd152: toneL = `c;  12'd153: toneL = `c;
				12'd154: toneL = `c;  12'd155: toneL = `c;
				12'd156: toneL = `c;  12'd157: toneL = `c;
				12'd158: toneL = `c;  12'd159: toneL = `c;
				12'd160: toneL = `c;  12'd161: toneL = `c;
				12'd162: toneL = `c;  12'd163: toneL = `c;
				12'd164: toneL = `c;  12'd165: toneL = `c;
				12'd166: toneL = `c;  12'd167: toneL = `c;
				12'd168: toneL = `c;  12'd169: toneL = `c;
				12'd170: toneL = `c;  12'd171: toneL = `c;
				12'd172: toneL = `c;  12'd173: toneL = `c;
				12'd174: toneL = `c;  12'd175: toneL = `c;
				12'd176: toneL = `c;  12'd177: toneL = `c;
				12'd178: toneL = `c;  12'd179: toneL = `c;
				12'd180: toneL = `c;  12'd181: toneL = `c;
				12'd182: toneL = `c;  12'd183: toneL = `c;
				12'd184: toneL = `c;  12'd185: toneL = `c;
				12'd186: toneL = `c;  12'd187: toneL = `c;
				12'd188: toneL = `c;  12'd189: toneL = `c;
				12'd190: toneL = `c;  12'd191: toneL = `c;
				default: toneL = `sil;
			endcase
        end
		else
			toneL = `sil;
    end
endmodule