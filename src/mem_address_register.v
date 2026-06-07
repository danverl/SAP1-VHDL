module mem_address_register (
    input  wire       i_clk,
    input  wire       i_rst,
    input  wire       i_enable_in,
    input  wire [3:0] i_bus,
    output wire [3:0] o_mem_address
);

    // 4-bit internal storage register (74LS173 equivalent)
    reg [3:0] data_reg;

    always @(posedge i_clk) begin
        if (i_rst) begin             // Reset takes priority
            data_reg <= 4'b0000;
        end else if (i_enable_in) begin
            data_reg <= i_bus[3:0];  // Latch the lower 4 bits of the bus
        end
    end

    assign o_mem_address = data_reg;

endmodule
