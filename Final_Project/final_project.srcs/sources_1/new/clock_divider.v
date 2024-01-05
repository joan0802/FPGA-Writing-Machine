module clock_divider #(
    parameter n = 27
)(
    input wire  clk,
    input en,
    output wire clk_div  
);

    reg [n-1:0] num;
    wire [n-1:0] next_num;

    always @(posedge clk) begin
        if(en)
            num <= next_num;
        else
            num <= 0;
    end

    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule