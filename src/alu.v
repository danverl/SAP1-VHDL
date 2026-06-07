module alu (
    input  wire       clk,
    input  wire       enable_out,
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       su,
    input  wire       FI,         
    inout  wire [7:0] bus,
    output reg        zF,         
    output reg        cF          
);

    wire [8:0] math_result;
    //Casting so result can be 9 bits. this is to capture the carry.
    assign math_result = su ? ({1'b0, a} + ~{1'b0, b} + 9'd1) : ({1'b0, a} + {1'b0, b});

    always @(posedge clk) begin
        if (FI) begin
            zF <= (math_result[7:0] == 8'b0);
            cF <= math_result[8];
        end
    end

    assign bus = enable_out ? math_result[7:0] : 8'bzzzzzzzz;

endmodule
