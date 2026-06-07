module output_module (
    input  wire        i_clk        ,
    input  wire        i_rst        ,
    input  wire        i_in_en      , 
    input  wire [7:0]  i_bus_data   , 
    output wire [6:0]  o_digital_tube, 
    output wire        o_sel            
);

    localparam [6:0] SEG_0     = 7'b0000001;
    localparam [6:0] SEG_1     = 7'b1111001;
    localparam [6:0] SEG_2     = 7'b0010010;
    localparam [6:0] SEG_3     = 7'b0110000;
    localparam [6:0] SEG_4     = 7'b1101000;
    localparam [6:0] SEG_5     = 7'b0100100;
    localparam [6:0] SEG_6     = 7'b0000100;
    localparam [6:0] SEG_7     = 7'b1110001;
    localparam [6:0] SEG_8     = 7'b0000000;
    localparam [6:0] SEG_9     = 7'b0100000;
    localparam [6:0] SEG_BLANK = 7'b1111111;

    reg [23:0] refresh_counter;
    reg        digit_select;
    reg  [6:0] selected_segment;

    reg [7:0] captured_value;
    reg        is_overflow;

    reg [24:0] scroll_counter; 
    reg [1:0]  scroll_state;   

    wire [6:0] h_seg, t_seg, o_seg; 

    assign o_sel = digit_select;

    function [6:0] bcd_to_seg(input [3:0] bcd);
        case (bcd)
            4'd0: bcd_to_seg = SEG_0;
            4'd1: bcd_to_seg = SEG_1;
            4'd2: bcd_to_seg = SEG_2;
            4'd3: bcd_to_seg = SEG_3;
            4'd4: bcd_to_seg = SEG_4;
            4'd5: bcd_to_seg = SEG_5;
            4'd6: bcd_to_seg = SEG_6;
            4'd7: bcd_to_seg = SEG_7;
            4'd8: bcd_to_seg = SEG_8;
            4'd9: bcd_to_seg = SEG_9;
            default: bcd_to_seg = SEG_BLANK;
        endcase
    endfunction

    assign h_seg = bcd_to_seg(captured_value / 8'd100);
    assign t_seg = bcd_to_seg((captured_value % 8'd100) / 8'd10);
    assign o_seg = bcd_to_seg(captured_value % 8'd10);

    always @(posedge i_clk or posedge i_rst) begin
        if (i_rst) begin
            refresh_counter  <= 24'd0;
            scroll_counter   <= 25'd0;
            digit_select     <= 1'b0;
            captured_value   <= 8'd0;
            is_overflow      <= 1'b0;
            scroll_state     <= 2'b00;
        end else begin
            if (i_in_en) begin
                captured_value <= i_bus_data;
                is_overflow    <= (i_bus_data > 8'd99);
                scroll_state   <= 2'b00; 
            end

            if (is_overflow) begin
                if (scroll_counter >= 25'd12_000_000) begin 
                    scroll_counter <= 25'd0;
                    scroll_state   <= scroll_state + 1'b1;
                end else begin
                    scroll_counter <= scroll_counter + 1'b1;
                end
            end else begin
                scroll_counter <= 25'd0;
            end

            if (refresh_counter >= 24'd300_000) begin
                refresh_counter <= 24'd0;
                digit_select    <= ~digit_select;
            end else begin
                refresh_counter <= refresh_counter + 1'b1;
            end
        end
    end

    always @(*) begin
        if (!is_overflow) begin
            if (digit_select == 1'b1) begin
                selected_segment = (captured_value < 8'd10) ? SEG_BLANK : t_seg;
            end else begin
                selected_segment = o_seg;
            end
        end else begin
            case (scroll_state)
                2'b00: selected_segment = (digit_select) ? SEG_BLANK : h_seg;
                2'b01: selected_segment = (digit_select) ? h_seg     : t_seg;
                2'b10: selected_segment = (digit_select) ? t_seg     : o_seg;
                2'b11: selected_segment = (digit_select) ? o_seg     : SEG_BLANK;
                default: selected_segment = SEG_BLANK;
            endcase
        end
    end

    assign o_digital_tube = selected_segment;
    
endmodule
