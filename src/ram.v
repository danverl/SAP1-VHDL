module ram (
    input  wire       i_clk,
    //input  wire       i_rst,
    input  wire       i_ram_in,
    input  wire       i_ram_out,
    input  wire [3:0] i_mem_address,
    inout  wire [7:0] io_bus
);

    reg [7:0] storage_blocks [0:15]; 

    // Synchronous write
    always @(posedge i_clk) begin
        if (i_ram_in) begin
            storage_blocks[i_mem_address] <= io_bus;
        end
    end

    // Tri-state output buffer
    assign io_bus = i_ram_out ? storage_blocks[i_mem_address] : 8'bzzzzzzzz;

    initial begin
        $readmemb("add3.txt", storage_blocks);
    end

endmodule
