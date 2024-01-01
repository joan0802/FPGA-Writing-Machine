`define c   32'd262   
`define g   32'd392   
`define b   32'd494   
`define hc  32'd524   
`define hd  32'd588   
`define he  32'd660   
`define hf  32'd698   
`define hg  32'd784   

`define sil   32'd50000000 // slience

module music_example (
	input [11:0] ibeatNum,
	input en,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
        if(en == 1) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `hg;      12'd1: toneR = `hg; // HG (half-beat)
                12'd2: toneR = `hg;      12'd3: toneR = `hg;
                12'd4: toneR = `hg;      12'd5: toneR = `hg;
                12'd6: toneR = `hg;      12'd7: toneR = `hg;
                12'd8: toneR = `he;      12'd9: toneR = `he; // HE (half-beat)
                12'd10: toneR = `he;     12'd11: toneR = `he;
                12'd12: toneR = `he;     12'd13: toneR = `he;
                12'd14: toneR = `he;     12'd15: toneR = `sil; // (Short break for repetitive notes: high E)

                12'd16: toneR = `he;     12'd17: toneR = `he; // HE (one-beat)
                12'd18: toneR = `he;     12'd19: toneR = `he;
                12'd20: toneR = `he;     12'd21: toneR = `he;
                12'd22: toneR = `he;     12'd23: toneR = `he;
                12'd24: toneR = `he;     12'd25: toneR = `he;
                12'd26: toneR = `he;     12'd27: toneR = `he;
                12'd28: toneR = `he;     12'd29: toneR = `he;
                12'd30: toneR = `he;     12'd31: toneR = `he;

                12'd32: toneR = `hf;     12'd33: toneR = `hf; // HF (half-beat)
                12'd34: toneR = `hf;     12'd35: toneR = `hf;
                12'd36: toneR = `hf;     12'd37: toneR = `hf;
                12'd38: toneR = `hf;     12'd39: toneR = `hf;
                12'd40: toneR = `hd;     12'd41: toneR = `hd; // HD (half-beat)
                12'd42: toneR = `hd;     12'd43: toneR = `hd;
                12'd44: toneR = `hd;     12'd45: toneR = `hd;
                12'd46: toneR = `hd;     12'd47: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd48: toneR = `hd;     12'd49: toneR = `hd; // HD (one-beat)
                12'd50: toneR = `hd;     12'd51: toneR = `hd;
                12'd52: toneR = `hd;     12'd53: toneR = `hd;
                12'd54: toneR = `hd;     12'd55: toneR = `hd;
                12'd56: toneR = `hd;     12'd57: toneR = `hd;
                12'd58: toneR = `hd;     12'd59: toneR = `hd;
                12'd60: toneR = `hd;     12'd61: toneR = `hd;
                12'd62: toneR = `hd;     12'd63: toneR = `hd;

                // --- Measure 2 ---
                12'd64: toneR = `hc;     12'd65: toneR = `hc; // HC (half-beat)
                12'd66: toneR = `hc;     12'd67: toneR = `hc;
                12'd68: toneR = `hc;     12'd69: toneR = `hc;
                12'd70: toneR = `hc;     12'd71: toneR = `hc;
                12'd72: toneR = `hd;     12'd73: toneR = `hd; // HD (half-beat)
                12'd74: toneR = `hd;     12'd75: toneR = `hd;
                12'd76: toneR = `hd;     12'd77: toneR = `hd;
                12'd78: toneR = `hd;     12'd79: toneR = `hd;

                12'd80: toneR = `he;     12'd81: toneR = `he; // HE (half-beat)
                12'd82: toneR = `he;     12'd83: toneR = `he;
                12'd84: toneR = `he;     12'd85: toneR = `he;
                12'd86: toneR = `he;     12'd87: toneR = `he;
                12'd88: toneR = `hf;     12'd89: toneR = `hf; // HF (half-beat)
                12'd90: toneR = `hf;     12'd91: toneR = `hf;
                12'd92: toneR = `hf;     12'd93: toneR = `hf;
                12'd94: toneR = `hf;     12'd95: toneR = `hf;

                12'd96: toneR = `hg;     12'd97: toneR = `hg; // HG (half-beat)
                12'd98: toneR = `hg;     12'd99: toneR = `hg;
                12'd100: toneR = `hg;    12'd101: toneR = `hg;
                12'd102: toneR = `hg;    12'd103: toneR = `sil; // (Short break for repetitive notes: high D)
                12'd104: toneR = `hg;    12'd105: toneR = `hg; // HG (half-beat)
                12'd106: toneR = `hg;    12'd107: toneR = `hg;
                12'd108: toneR = `hg;    12'd109: toneR = `hg;
                12'd110: toneR = `hg;    12'd111: toneR = `sil; // (Short break for repetitive notes: high D)

                12'd112: toneR = `hg;    12'd113: toneR = `hg; // HG (one-beat)
                12'd114: toneR = `hg;    12'd115: toneR = `hg;
                12'd116: toneR = `hg;    12'd117: toneR = `hg;
                12'd118: toneR = `hg;    12'd119: toneR = `hg;
                12'd120: toneR = `hg;    12'd121: toneR = `hg;
                12'd122: toneR = `hg;    12'd123: toneR = `hg;
                12'd124: toneR = `hg;    12'd125: toneR = `hg;
                12'd126: toneR = `hg;    12'd127: toneR = `hg;

                default: toneR = `sil;
            endcase
        end else begin
            toneR = `sil;
        end
    end

    always @(*) begin
        if(en == 1)begin
            case(ibeatNum)
                12'd0: toneL = `hc;  	12'd1: toneL = `hc; // HC (two-beat)
                12'd2: toneL = `hc;  	12'd3: toneL = `hc;
                12'd4: toneL = `hc;	    12'd5: toneL = `hc;
                12'd6: toneL = `hc;  	12'd7: toneL = `hc;
                12'd8: toneL = `hc;	    12'd9: toneL = `hc;
                12'd10: toneL = `hc;	12'd11: toneL = `hc;
                12'd12: toneL = `hc;	12'd13: toneL = `hc;
                12'd14: toneL = `hc;	12'd15: toneL = `hc;

                12'd16: toneL = `hc;	12'd17: toneL = `hc;
                12'd18: toneL = `hc;	12'd19: toneL = `hc;
                12'd20: toneL = `hc;	12'd21: toneL = `hc;
                12'd22: toneL = `hc;	12'd23: toneL = `hc;
                12'd24: toneL = `hc;	12'd25: toneL = `hc;
                12'd26: toneL = `hc;	12'd27: toneL = `hc;
                12'd28: toneL = `hc;	12'd29: toneL = `hc;
                12'd30: toneL = `hc;	12'd31: toneL = `hc;

                12'd32: toneL = `g;	    12'd33: toneL = `g; // G (one-beat)
                12'd34: toneL = `g;	    12'd35: toneL = `g;
                12'd36: toneL = `g;	    12'd37: toneL = `g;
                12'd38: toneL = `g;	    12'd39: toneL = `g;
                12'd40: toneL = `g;	    12'd41: toneL = `g;
                12'd42: toneL = `g;	    12'd43: toneL = `g;
                12'd44: toneL = `g;	    12'd45: toneL = `g;
                12'd46: toneL = `g;	    12'd47: toneL = `g;

                12'd48: toneL = `b;	    12'd49: toneL = `b; // B (one-beat)
                12'd50: toneL = `b;	    12'd51: toneL = `b;
                12'd52: toneL = `b;	    12'd53: toneL = `b;
                12'd54: toneL = `b;	    12'd55: toneL = `b;
                12'd56: toneL = `b;	    12'd57: toneL = `b;
                12'd58: toneL = `b;	    12'd59: toneL = `b;
                12'd60: toneL = `b;	    12'd61: toneL = `b;
                12'd62: toneL = `b;	    12'd63: toneL = `b;

                12'd64: toneL = `hc;	12'd65: toneL = `hc; // HC (two-beat)
                12'd66: toneL = `hc;    12'd67: toneL = `hc;
                12'd68: toneL = `hc;	12'd69: toneL = `hc;
                12'd70: toneL = `hc;	12'd71: toneL = `hc;
                12'd72: toneL = `hc;	12'd73: toneL = `hc;
                12'd74: toneL = `hc;	12'd75: toneL = `hc;
                12'd76: toneL = `hc;	12'd77: toneL = `hc;
                12'd78: toneL = `hc;	12'd79: toneL = `hc;

                12'd80: toneL = `hc;	12'd81: toneL = `hc;
                12'd82: toneL = `hc;    12'd83: toneL = `hc;
                12'd84: toneL = `hc;    12'd85: toneL = `hc;
                12'd86: toneL = `hc;    12'd87: toneL = `hc;
                12'd88: toneL = `hc;    12'd89: toneL = `hc;
                12'd90: toneL = `hc;    12'd91: toneL = `hc;
                12'd92: toneL = `hc;    12'd93: toneL = `hc;
                12'd94: toneL = `hc;    12'd95: toneL = `hc;

                12'd96: toneL = `g;	    12'd97: toneL = `g; // G (one-beat)
                12'd98: toneL = `g; 	12'd99: toneL = `g;
                12'd100: toneL = `g;	12'd101: toneL = `g;
                12'd102: toneL = `g;	12'd103: toneL = `g;
                12'd104: toneL = `g;	12'd105: toneL = `g;
                12'd106: toneL = `g;	12'd107: toneL = `g;
                12'd108: toneL = `g;	12'd109: toneL = `g;
                12'd110: toneL = `g;	12'd111: toneL = `g;

                12'd112: toneL = `b;	12'd113: toneL = `b; // B (one-beat)
                12'd114: toneL = `b;	12'd115: toneL = `b;
                12'd116: toneL = `b;	12'd117: toneL = `b;
                12'd118: toneL = `b;	12'd119: toneL = `b;
                12'd120: toneL = `b;	12'd121: toneL = `b;
                12'd122: toneL = `b;	12'd123: toneL = `b;
                12'd124: toneL = `b;	12'd125: toneL = `b;
                12'd126: toneL = `b;	12'd127: toneL = `b;

                default : toneL = `sil;
            endcase
        end
        else begin
            toneL = `sil;
        end
    end
endmodule