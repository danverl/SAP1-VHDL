module register (
    input  wire       i_clk,
    input  wire       i_rst,         
    input  wire       i_enable_in,   
    input  wire       i_enable_out,  
    inout  wire [7:0] io_bus,        
    output wire [7:0] o_alu_out,     
    output wire [7:0] o_led          
);

    reg [7:0] data_reg;

    always @(posedge i_clk) begin
        if (i_rst) begin
            data_reg <= 8'h00;       
        end else if (i_enable_in) begin
            data_reg <= io_bus;      
        end
    end

    assign o_alu_out = data_reg;
    assign o_led     = ~data_reg;     

    assign io_bus = i_enable_out ? data_reg : 8'bzzzzzzzz;

endmodule
