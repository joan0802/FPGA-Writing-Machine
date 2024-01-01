def expand_tone_sequence(original_sequence):
    expanded_sequence = ""
    for index in range(0, len(original_sequence), 1 ):
        original_index = original_sequence[index].split(':')[0].strip()
        tone_value = original_sequence[index].split('=')[1].strip()
        new_index_1 = int(original_index.split('\'d')[1]) * 2
        new_index_2 = new_index_1 + 1
        expanded_sequence += f"12'd{new_index_1}: toneR = {tone_value};  12'd{new_index_2}: toneR = {tone_value};\n"
    return expanded_sequence

original_sequence = [
"12'd0: toneL = `lg",  	"12'd1: toneL = `lg", 
                "12'd2: toneL = `le",  	"12'd3: toneL = `le",
                "12'd4: toneL = `lg",	    "12'd5: toneL = `lg",
                "12'd6: toneL = `le",  	"12'd7: toneL = `le",
                "12'd8: toneL = `lg",	    "12'd9: toneL = `lg",
                "12'd10: toneL = `c",	"12'd11: toneL = `c",

                "12'd12: toneL = `e",	"12'd13: toneL = `e",
                "12'd14: toneL = `e",	"12'd15: toneL = `e",
                "12'd16: toneL = `e",	"12'd17: toneL = `e",
                "12'd18: toneL = `c",	"12'd19: toneL = `c",
                "12'd20: toneL = `c",	"12'd21: toneL = `sil",
                "12'd22: toneL = `sil",	"12'd23: toneL = `sil",

                "12'd24: toneL = `lba",	"12'd25: toneL = `lba",
                "12'd26: toneL = `lbe",	"12'd27: toneL = `lbe",
                "12'd28: toneL = `la",	"12'd29: toneL = `la",
                "12'd30: toneL = `le",	"12'd31: toneL = `le",
                "12'd32: toneL = `la",	"12'd33: toneL = `la", 
                "12'd34: toneL = `c",	    "12'd35: toneL = `c",

                "12'd36: toneL = `be",	"12'd37: toneL = `be",
                "12'd38: toneL = `be",	"12'd39: toneL = `be",
                "12'd40: toneL = `be",	"12'd41: toneL = `be",
                "12'd42: toneL = `c",	    "12'd43: toneL = `c",
                "12'd44: toneL = `c",	    "12'd45: toneL = `sil",
                "12'd46: toneL = `sil",	"12'd47: toneL = `sil",

                "12'd48: toneL = `lbb",	"12'd49: toneL = `lbb", 
                "12'd50: toneL = `lf",	    "12'd51: toneL = `lf",
                "12'd52: toneL = `lb",	    "12'd53: toneL = `lb",
                "12'd54: toneL = `lf",	    "12'd55: toneL = `lf",
                "12'd56: toneL = `lb",	    "12'd57: toneL = `lb",
                "12'd58: toneL = `d",	    "12'd59: toneL = `d",

                "12'd60: toneL = `f",	    "12'd61: toneL = `f",
                "12'd62: toneL = `f",	    "12'd63: toneL = `f",
                "12'd64: toneL = `f",	"12'd65: toneL = `f",
                "12'd66: toneL = `d",    "12'd67: toneL = `sil",
                "12'd68: toneL = `d",	"12'd69: toneL = `sil",
                "12'd70: toneL = `d",	"12'd71: toneL = `d",

                "12'd72: toneL = `c",	"12'd73: toneL = `c",
                "12'd74: toneL = `c",	"12'd75: toneL = `c",
                "12'd76: toneL = `c",	"12'd77: toneL = `c",
                "12'd78: toneL = `c",	"12'd79: toneL = `c",
                "12'd80: toneL = `c",	"12'd81: toneL = `c",
                "12'd82: toneL = `c",    "12'd83: toneL = `c",

                "12'd84: toneL = `c",    "12'd85: toneL = `c",
                "12'd86: toneL = `c",    "12'd87: toneL = `c",
                "12'd88: toneL = `c",    "12'd89: toneL = `c",
                "12'd90: toneL = `c",    "12'd91: toneL = `c",
                "12'd92: toneL = `c",    "12'd93: toneL = `c",
                "12'd94: toneL = `c",    "12'd95: toneL = `c",
        ]

expanded_sequence = expand_tone_sequence(original_sequence)
#print(expanded_sequence)
with open("expanded_sequence.txt", "w") as file:
    file.write(expanded_sequence)


