module program_counter (
    input wire       i_clk,
    input wire       i_rst,
    input wire       i_clr,
    input wire       CE,
    input wire       CO,
    input wire       JUMP,
    input wire [3:0] i_bus_data, 
    output wire [7:0] o_bus_val
);

    reg [3:0] instruction_count;
    
    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst || i_clr) instruction_count <= 4'b0;
        else if (JUMP)      instruction_count <= i_bus_data;
        else if (CE)        instruction_count <= instruction_count + 1'b1;
    end

    assign o_bus_val = CO ? {4'b0000, instruction_count} : 8'bzzzzzzzz;
endmodule
