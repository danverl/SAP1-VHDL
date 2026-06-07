module clock_module (
    input  wire i_mclk,   // Master clock
    input  wire i_rst,    // Reset button (Active High)
    input  wire i_hlt,    // Halt processor signal from control word (Active High)
    output wire o_clk,    // Main system clock out
    output wire o_nclk    // Inverted system clock out
);

    reg [21:0] count;
    reg clk_state;

    always @(posedge i_mclk or posedge i_rst) begin
        if (i_rst) begin
            count     <= 22'd0;
            clk_state <= 1'b0;
        end else if (count >= 22'd500000) begin 
            count     <= 22'd0;
            clk_state <= ~clk_state;
        end else begin
            count     <= count + 1'b1;
        end
    end 

    assign o_clk  = i_hlt ? 1'b0 : clk_state;
    assign o_nclk = i_hlt ? 1'b1 : ~clk_state;
    
endmodule
