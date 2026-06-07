module instruction_register (
    input  wire       i_clk,
    input  wire       i_rst,
    input  wire       i_enable_in,   // Active-high load enable (II line)
    input  wire       i_enable_out,  // Active-high output enable (IO line)
    inout  wire [7:0] io_bus,        // Bi-directional data bus
    output wire [3:0] o_instruction_out
);

    // Storage register
    reg [7:0] data_reg;

    wire [3:0] memory_address;
    wire [3:0] instruction;

    // Equivalent to the LS173 storage registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            data_reg <= 8'h00;
        end else if (i_enable_in) begin
            data_reg <= io_bus;
        end
    end

    //slices of the internal data register
    assign instruction    = data_reg[7:4]; // Upper 4 bits = Opcode
    assign memory_address = data_reg[3:0]; // Lower 4 bits = Operand/Address

    assign io_bus = i_enable_out ? {4'b0000, memory_address} : 8'bzzzzzzzz;
    
    assign o_instruction_out = instruction;

endmodule
