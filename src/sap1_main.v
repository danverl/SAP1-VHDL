module sap1_main (
    input  wire       i_mclk        , // Master clock
    input  wire       i_rst         , // Master reset
    output wire [7:0] o_led_1       , // Register A display
    output wire [7:0] o_led_2       , // Register B display
    output wire [6:0] o_digital_tube, // 7-Segment segment outputs (A to G)
    output wire       o_sel         , // Multiplexer digit selector
    output wire       o_ready,
    output wire test
    );

    //internals
    wire  [7:0] r_data_bus       ;
    wire [18:0] r_ctrl_word      ;
    wire  [3:0] r_mem_bus        ;

    wire        clk              ;
    wire        nclk             ;

    wire        zF               ;
    wire        cF               ;

    wire  [3:0] o_instruction_out;
    wire  [7:0] o_alu_out_a      ;
    wire  [7:0] o_alu_out_b      ;

    clock_module u_clock_module(
        .i_mclk (i_mclk        ),
        .i_hlt  (r_ctrl_word[0]),
        .i_rst (i_rst),
        .o_clk  (clk           ),
        .o_nclk (nclk          )
        );

    control_logic u_control_logic(
        .i_nclk         (nclk              ),
        .i_clr          (r_ctrl_word[6]   ),
        .i_rst          (i_rst            ),
        .i_zf           (zF               ),
        .i_cf           (cF               ),
        .i_instruction  (o_instruction_out),
        .o_control_word (r_ctrl_word      )
        );

    register u_registera(
        .i_clk        (clk            ),
        .i_rst        (i_rst          ),
        .i_enable_in  (r_ctrl_word[11]),
        .i_enable_out (r_ctrl_word[10]),
        .io_bus       (r_data_bus     ),
        .o_alu_out    (o_alu_out_a    ),
        .o_led        (o_led_1        )
        );

    register u_registerb(
        .i_clk        (clk           ),
        .i_rst        (i_rst         ),
        .i_enable_in  (r_ctrl_word[4]),
        .i_enable_out (r_ctrl_word[3]),
        .io_bus       (r_data_bus    ),
        .o_alu_out    (o_alu_out_b   ),
        .o_led        (o_led_2       )
        );

    alu u_alu(
        .clk        (clk           ),
        .enable_out (r_ctrl_word[8]),
        .a          (o_alu_out_a   ),
        .b          (o_alu_out_b   ),
        .su         (r_ctrl_word[7]),
        .bus        (r_data_bus    ),
        .zF         (zF            ),
        .cF         (cF            ),
        .FI         (r_ctrl_word[9])
        );

    instruction_register u_instruction_register(
        .i_clk             (clk              ),
        .i_rst             (i_rst            ),
        .i_enable_in       (r_ctrl_word[17]  ),
        .i_enable_out      (r_ctrl_word[18]  ),
        .io_bus            (r_data_bus       ),
        .o_instruction_out (o_instruction_out)
        );

    mem_address_register u_mem_address_register(
        .i_clk         (clk            ),
        .i_rst         (i_rst          ),
        .i_enable_in   (r_ctrl_word[12]),
        .i_bus         (r_data_bus[3:0]), 
        .o_mem_address (r_mem_bus      )
        );

    output_module u_output_module(
        .i_clk          (i_mclk            ),
        .i_rst          (i_rst          ),
        .i_in_en        (r_ctrl_word[16]),
        .i_bus_data     (r_data_bus     ),
        .o_digital_tube (o_digital_tube ),
        .o_sel          (o_sel          )
        );

program_counter u_program_counter(
    .i_clk      (clk            ),
    .i_rst      (i_rst          ),
    .i_clr      (r_ctrl_word[6] ),
    .i_bus_data (r_data_bus[3:0]),
    .o_bus_val  (r_data_bus     ),
    .CE         (r_ctrl_word[14]),
    .CO         (r_ctrl_word[13]),
    .JUMP       (r_ctrl_word[15])
    );

    ram u_ram(
        .i_clk         (clk           ),
        .i_ram_in      (r_ctrl_word[2]),
        .i_ram_out     (r_ctrl_word[1]),
        .i_mem_address (r_mem_bus     ),
        .io_bus        (r_data_bus    )
        );


assign o_ready = clk; //led to show clock
assign test = clk; //pin to output clock, for use with logic analyzer

endmodule
