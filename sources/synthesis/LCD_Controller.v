`include "LCD_macros.v"
`timescale 1us/10ns


module LCD_Controller (
    input CLK_I,
    input RST_I,
    input AVS,
    input DAY,
    input MAX,
    input TIM,
    input POINT,
    input COLON,
    input KMH,
    input [7:0] LOWER1_ASCII,
    input [7:0] LOWER10_ASCII,
    input [7:0] LOWER100_ASCII,
    input [7:0] LOWER1000_ASCII,
    input [7:0] UPPER1_ASCII,
    input [7:0] UPPER10_ASCII,
    output RES_N_O,       // Reset, active low
    output CS1_N_O,
    output SI_O,
    output A0_O,
    output C86_O,
    output LED_A_O,
    output SCL_O
    );       
    
    reg avs_old, day_old, max_old, tim_old, point_old, colon_old, kmh_old;
    reg [7:0] lower1_ascii_old, lower10_ascii_old, lower100_ascii_old, lower1000_ascii_old, upper1_ascii_old, upper10_ascii_old;   
    reg [7:0] update_value;
    reg [7:0] top_line;
    reg [3:0] position_y;
    reg [7:0] position_x;
    reg [2:0] cycles, cycles_int;  
    reg change_to_write_first, change_to_write_cycles;
    reg [7:0] address_char, address_1, address_2, address_3;      
    reg [4:0] old_state, last_state;     
    reg [7:0] str_length;
    reg textsize; 
    reg [7:0] column_counter;
    reg start_flag;
        
                                       
    wire [7:0] state;
    wire convert_SI;
    wire clk;
    wire change_state; 
    wire [7:0] new_state;
    wire [7:0] next_state;
    wire [7:0] data, data_stream;
    wire a0_tmp, led_a_tmp;
    wire CS;  
    wire [3:0] count;  
    wire si_conv_timed;
    wire [7:0] pos_x;
    wire [7:0] new_top_line;
    wire [3:0] pos_y;
    wire [7:0] ascii_small, ascii_big, ascii;
    wire [14:0] address;
    wire change_to_WRITE;
    wire [7:0] column_write;
    wire [3:0] line_write;
    wire [4:0] symbolwidth_small, symbolwidth_big, symbolwidth;
    wire [2:0] address_en;  
                                  
    assign address_en[0]    = state != last_state && state == `WAIT && last_state == `DISP3?1:0;   
    assign address_en[1]    = state != last_state && state == `DISP1 && last_state == `DISP3?1:0;   
    assign address_en[2]    = state != last_state && state == `WRITE?1:0;   
    assign CS1_N_O          = !CS;    
    assign C86_O            = `Interface;        
    assign pos_y            = position_y;
    assign pos_x            = position_x;
    assign address          = $signed(address_char);
    assign change_to_WRITE  = change_to_write_first;
    assign ascii            = textsize == `textsize_small?ascii_small:ascii_big;
    assign line_write       = textsize == `textsize_small?`lineheight_small:`lineheight_big;
    assign symbolwidth      = textsize == `textsize_small?symbolwidth_small+`whitespace_small:symbolwidth_big+`whitespace_big;
    assign column_write     = str_length*symbolwidth;                           // symbols*symbol_width == used colums on the display, maximum is 129
    assign new_top_line     = top_line;
    
    
    LCD_ClockDivider lcd_clocks(
        .clock(CLK_I),
        .reset(RST_I),
        .scl_lcd(SCL_O),
        .scl_func(clk)
        );
        
    LCD_Control lcd_controller(        
        .clock(CLK_I),
        .reset(RST_I),
        .convert_SI(convert_SI),
        .change_to_WRITE(change_to_WRITE),
        .state(state),
        .new_state(new_state),
        .data(data),
        .count(count),
        .led_a_tmp(led_a_tmp),
        .a0_tmp(a0_tmp),
        .si_conv_timed(si_conv_timed),
        .change_state(change_state),
        .data_stream(data_stream), 
        .led_a(LED_A_O),
        .a0(A0_O)
        
    );
              
    LCD_SM_States state_machine_states (
        .clock(CLK_I),
        .reset(RST_I),
        .change_state(change_state),
        .column_write(column_write),
        .line_write(line_write),
        .state(state),
        .state_next(next_state)
    );
        
    LCD_SM_Signals state_machine_signals (
        .clock(CLK_I),
        .reset(RST_I),
        .state(state),
        .res_n(RES_N_O),      
        .a0(a0_tmp),
        .led_a(led_a_tmp),
        .new_top_line(new_top_line),
        .position_y(pos_y),
        .position_x(pos_x),
        .convert_SI(convert_SI),
        .ascii(ascii),
        .data(data),
        .new_state(new_state) 
    );       
    
    LCD_PS_Converter stream_data(
        .clock(clk),
        .reset(RST_I),
        .stream(data_stream),
        .si_conv(si_conv_timed),
        .state_next(next_state),
        .count(count),
        .CS(CS),
        .SI(SI_O)
    );
    
    
    always @(posedge CLK_I) begin
        if(RST_I) begin
            update_value            <= 0;
            change_to_write_first   <= 0;  
            {lower1_ascii_old, lower10_ascii_old, lower100_ascii_old, lower1000_ascii_old, upper1_ascii_old, upper10_ascii_old} <= 0;
            avs_old                 <= 0;
            day_old                 <= 0;
            max_old                 <= 0;
            tim_old                 <= 0; 
            point_old               <= 0;
            colon_old               <= 0;
            kmh_old                 <= 0;
            start_flag              <= 0;
        end
        else begin         
            last_state <= state;           
            if(state == `IDLE) begin     // In here, because somewhere in the state IDLE there could be the change -> always @state looks only in the beginning     
                start_flag              <= 1;            
                if(change_to_write_first==0) begin
                    
                    if (kmh_old != KMH)
                        begin update_value <= 7; kmh_old <= KMH; change_to_write_first <= 1;end
                    else if (avs_old != AVS)
                        begin update_value <= 8; avs_old <= AVS; change_to_write_first <= 1;end
                    else if (day_old != DAY)
                        begin update_value <= 9; day_old <= DAY; change_to_write_first <= 1;end
                    else if (max_old != MAX)
                        begin update_value <= 10; max_old <= MAX; change_to_write_first <= 1;end
                    else if (tim_old != TIM)
                        begin update_value <= 11; tim_old <= TIM; change_to_write_first <= 1;end
                    else if (point_old != POINT)
                        begin update_value <= 12; point_old <= POINT; change_to_write_first <= 1; lower1_ascii_old<=lower1_ascii_old+1; lower10_ascii_old<=lower10_ascii_old+1; end
                    else if (colon_old != COLON)
                        begin update_value <= 13; colon_old <= COLON; change_to_write_first <= 1; lower10_ascii_old<=lower10_ascii_old+1; lower100_ascii_old<=lower100_ascii_old+1; end
                    else if(lower1_ascii_old != LOWER1_ASCII)
                        begin update_value <= 1; lower1_ascii_old <= LOWER1_ASCII; change_to_write_first <= 1;end              
                    else if(lower10_ascii_old != LOWER10_ASCII)
                        begin update_value <= 2; lower10_ascii_old <= LOWER10_ASCII; change_to_write_first <= 1;end                 
                    else if(lower100_ascii_old != LOWER100_ASCII)
                        begin update_value <= 3; lower100_ascii_old <= LOWER100_ASCII; change_to_write_first <= 1;end                 
                    else if(lower1000_ascii_old != LOWER1000_ASCII)
                        begin update_value <= 4; lower1000_ascii_old <= LOWER1000_ASCII; change_to_write_first <= 1;end               
                    else if(upper1_ascii_old != UPPER1_ASCII)
                        begin update_value <= 5; upper1_ascii_old <= UPPER1_ASCII; change_to_write_first <= 1;end                 
                    else if(upper10_ascii_old != UPPER10_ASCII)
                        begin update_value <= 6; upper10_ascii_old <= UPPER10_ASCII; change_to_write_first <= 1;end
                        
                    else
                        begin update_value <= 0; change_to_write_first <= 0; end                       
                end 
            end
            else begin
                change_to_write_first <= 0;    
            end
        end
    end    
    
    always @(update_value) begin :LCD_Mask            
        case(update_value)
            0:  begin                   // Internal Reset
                    str_length  <= 8'd0;
                    textsize    <= `textsize_small;
                    top_line    <= 0;
                    position_y  <= 0;
                    position_x  <= 0;
                    address_1   <= 8'h0;
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
            1:  begin   // lower1_ascii
                    str_length  <= 8'd1;        
                    textsize    <= `textsize_big;   
                    top_line    <= 0;  
                    position_y  <= 5;
                    position_x  <= 105; // 105
                    address_1   <= LOWER1_ASCII; 
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;    
                end
            2:  begin   // lower10_ascii
                    str_length  <= 8'd1;    
                    textsize    <= `textsize_big;    
                    top_line    <= 0;
                    position_y  <= 5;
                    position_x  <= 87;
                    address_1   <= LOWER10_ASCII; 
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
            3:  begin   // lower100_ascii
                    str_length  <= 8'd1;
                    textsize    <= `textsize_big;
                    top_line    <= 0;    
                    position_y  <= 5;
                    position_x  <= 69;
                    address_1   <= LOWER100_ASCII; 
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
            4:  begin   // lower1000_ascii
                    str_length  <= 8'd1;
                    textsize    <= `textsize_big;
                    top_line    <= 0;
                    position_y  <= 5;
                    position_x  <= 51;
                    address_1   <= LOWER1000_ASCII; 
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
            5:  begin   // upper1_ascii
                    str_length  <= 8'd1;
                    textsize    <= `textsize_big;
                    top_line    <= 0;
                    position_y  <= 1;
                    position_x  <= 87;
                    cycles      <= 1;
                    address_1   <= UPPER1_ASCII; 
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
            6:  begin   // upper10_ascii
                    str_length  <= 8'd1;
                    textsize    <= `textsize_big;
                    top_line    <= 0;
                    position_y  <= 1;
                    position_x  <= 75;
                    address_1   <= UPPER10_ASCII; 
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
            7:  begin   // kmh
                    str_length  <= 8'd3;
                    textsize    <= `textsize_small;
                    top_line    <= 0;
                    position_y  <= 2; // 2
                    position_x  <= 105;
                    if(KMH == 1) begin
                        address_1   <= 8'h6B;    //ASCII: "k"
                        address_2   <= 8'h6D;    //ASCII: "m"
                        address_3   <= 8'h68;    //ASCII: "h"
                    end
                    else begin
                        address_1   <= 8'h0;
                        address_2   <= 8'h0;
                        address_3   <= 8'h0;
                    end
                end
            8:  begin   // avs
                    str_length  <= 8'd3;     
                    textsize    <= `textsize_small;    
                    top_line    <= 0;  
                    position_y  <= 3;
                    position_x  <= 15;
                    if(AVS==1) begin
                        address_1   <= 8'h41;    //ASCII: "A"
                        address_2   <= 8'h56;    //ASCII: "v"
                        address_3   <= 8'h53;    //ASCII: "s"
                    end
                    else begin
                        address_1   <= 8'h0;
                        address_2   <= 8'h0;
                        address_3   <= 8'h0;
                    end         
                end
            9:  begin   // day
                    str_length  <= 8'd3;
                    textsize    <= `textsize_small;
                    top_line    <= 0;
                    position_y  <= 2;
                    position_x  <= 15;
                    if(DAY == 1) begin
                        address_1   <= 8'h44;    //ASCII: "D"
                        address_2   <= 8'h41;    //ASCII: "A"
                        address_3   <= 8'h59;    //ASCII: "Y"
                    end
                    else begin
                        address_1   <= 8'h0;
                        address_2   <= 8'h0;
                        address_3   <= 8'h0;
                    end
                end
            10: begin   // max                    
                    str_length  <= 8'd3;
                    textsize    <= `textsize_small;
                    top_line    <= 0;
                    position_y  <= 5;
                    position_x  <= 15;
                    if(MAX == 1) begin
                        address_1   <= 8'h4D;    //ASCII: "M"
                        address_2   <= 8'h41;    //ASCII: "A"
                        address_3   <= 8'h58;    //ASCII: "X"
                    end
                    else begin
                        address_1   <= 8'h0;
                        address_2   <= 8'h0;
                        address_3   <= 8'h0;
                    end
                end
            11: begin   // tim
                    str_length  <= 8'd3;
                    textsize    <= `textsize_small;
                    top_line    <= 0;
                    position_y  <= 4;
                    position_x  <= 15;
                    if(TIM == 1) begin
                        address_1   <= 8'h54;    //ASCII: "T"
                        address_2   <= 8'h49;    //ASCII: "I"
                        address_3   <= 8'h4D;    //ASCII: "M"
                    end
                    else begin
                        address_1   <= 8'h0;
                        address_2   <= 8'h0;
                        address_3   <= 8'h0;
                    end
                end
            12: begin   // point
                    str_length  <= 8'd1;
                    textsize    <= `textsize_big;
                    top_line    <= 0;
                    position_y  <= 5; // 5
                    position_x  <= 96;
                    if(POINT == 1)
                        address_1   <= 8'h2E;
                    else
                        address_1   <= 8'h00;                       
                    address_2   <= 8'h00;
                    address_3   <= 8'h00;
                end
            13: begin   // colon
                    str_length  <= 8'd1;
                    textsize    <= `textsize_big;
                    top_line    <= 0;
                    position_y  <= 4'h5;
                    position_x  <= 79; // 78
                    if(COLON == 1)
                        address_1   <= 8'h3A;
                    else
                        address_1   <= 8'h0;
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end 
            default:    begin
                    str_length  <= 8'd0;
                    textsize    <= `textsize_small;
                    top_line    <= 0;                    
                    position_y  <= 0;
                    position_x  <= 0;
                    address_1   <= 8'h0;
                    address_2   <= 8'h0;
                    address_3   <= 8'h0;
                end
        endcase
    end    
           
    always @(posedge CLK_I) begin
        if(RST_I) begin            
           column_counter  <= 0;
           address_char    <= 0;
        end
        else begin
            if(state == `RESET || state == `CLEAR || state == `IDLE) begin
               column_counter  <= 0;
               address_char    <= 0;
            end
            else begin
                column_counter <= column_counter+(start_flag*address_en[0]);
                if(column_counter < 1*symbolwidth*line_write)
                    address_char <= address_1;
                else if(column_counter < 2*symbolwidth*line_write)
                    address_char <= address_2;
                else
                    address_char <= address_3;
            end
        end          
    end              
        
    LCD_Bram_Small symbols_small (
        .clock(CLK_I),
        .reset(RST_I),
        .address(address),
        .enable(address_en),
        .symbolwidth(symbolwidth_small),
        .out(ascii_small)    
    );
    
    LCD_Bram_Big symbols_big (
        .clock(CLK_I),
        .reset(RST_I),
        .address(address),
        .enable(address_en),
        .symbolwidth(symbolwidth_big),
        .out(ascii_big)    
    );
    
endmodule