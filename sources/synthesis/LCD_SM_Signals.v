`timescale 1us / 10ns


module LCD_SM_Signals (
    input clock,
    input reset,
    input [7:0] state,
    input [7:0] new_top_line,
    input [3:0] position_y,
    input [7:0] position_x,
    input [7:0] ascii,
    output res_n,           // Reset, active low
    output a0,
    output led_a,
    output convert_SI,
    output [7:0] data,
    output [7:0] new_state
    );  
        
    reg RST;                // Reset, active high
    reg A0;                 // Data[1]/Command[0] flag
    reg LED_A;              // Background light
    reg [7:0] SI_data;      // Serial Data Output [D7...D0]
    reg [7:0] column;
    reg [3:0] line; 
    reg [4:0] last_state; 
    reg state_changed;
    reg idle_flag;
    reg [7:0] next_state;     
    
    wire address_en;
    reg address_trigger;
    reg clear_lcd;
    assign address_en = address_trigger;
       
    assign new_state    = next_state;        
    assign res_n        = !RST;    
    assign data         = SI_data;
    assign a0           = A0;      
    assign led_a        = LED_A;    
    
    reg set_convert_SI;
    assign convert_SI = set_convert_SI;    
    
    always @(posedge clock) begin: CHECK_FOR_FIRST_TIME_CHANGE_OF_STATE
        if(reset) begin
            last_state      <= `START;
            state_changed   <= 1;
            next_state      <= 0;
            address_trigger <= 0;
        end
        else begin
            next_state      <= state;
            last_state      <= (last_state != state)?state:last_state;
            state_changed   <= (last_state != state)?1:0;
        end
    end
        
    always @(posedge state_changed) begin: Clear_Display
        case(state)
            `START: begin
                        line        <= 0;
                        column      <= 0;
                        idle_flag   <= 0;
                        clear_lcd   <= 0;
                    end
            `CLEAR: begin
                        line        <= 0;
                        column      <= 0;
                        clear_lcd   <= 1;
                        idle_flag   <= 0;
                    end
            `DISP2_1:  begin
                        line        <= line + 1;
                    end     
            `IDLE:  begin
                        line        <= 0;
                        column      <= 0;
                        idle_flag   <= 1;
                        clear_lcd   <= 0;
                    end   
            `WRITE: begin                    
                        line        <= position_y;
                        column      <= position_x;
                    end
        endcase
    end   
    
    always@(posedge state_changed) begin
        case(state)
            `RESET:         begin
                                {RST, A0, LED_A} <= 3'b100;
                                set_convert_SI <= 0;
                                SI_data <= 8'b00000000;
                            end
            `START:         begin
                                {RST, A0, LED_A} <= 3'b000;
                                set_convert_SI <= 0;
                            end
            `LCD_ON:        begin
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 0;
                            end
            `INIT1:         begin             
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {7'b1010001, 1'b0};          // LCD BIAS SETTING (11)
                            end   
            `INIT2:         begin 
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {7'b1010000, 1'b0};          // ADC selection -> vertical/horizontal directon of the Pixels  (8)
                            end   
            `INIT3:         begin 
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= 8'b11001000;                 // COM output state selection (15)
                            end   
            `INIT4:         begin 
                                {RST, A0, LED_A} <= 3'b001;     
                                set_convert_SI <= 1;    
                                SI_data <= {5'b00100,3'b100};           // 5.0 (default) --> V0 = 5.0* Vref(=2.1) * 1- ((63-a)/162);    (17)
                            end                
            `INIT5_1:       begin 
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= 8'b10000001;                 // Electronic Volume Mode Set (Part 1) (18)
                            end                                                            
            `INIT5_2:       begin 
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {2'b00, 6'b111111};          //  Electronic Volume Mode Set (Part 1) (18) (LCD brightness max) 
                            end  
            `INIT6:         begin 
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {5'b00101, 3'b111};          //  power circuit operation mode : all on (last 3 bit) (16)
                            end                 
            `INIT7:         begin 
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {7'b1010111, 1'b1};          // Display on
                            end     
            `DISP0:         begin
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                if(clear_lcd)
                                    SI_data <= {2'b01, 6'd0};     // Display Start Line Set 0-63 (-> pull Line X to the top of the Display and set as new line 0)
                                else
                                    SI_data <= {2'b01, new_top_line};     // Display Start Line Set 0-63 (-> pull Line X to the top of the Display and set as new line 0)
                            end    
            `DISP1:         begin
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {4'b1011, line};             // Page Adress Set 0-8  = 9 Zeilen, die letze hat aber nur h�he 1 und sollte nicht verwendet werden 
                            end
            `DISP2_1:       begin
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {4'b0001, column[7:4]};      // higher column adress           
                            end      
            `DISP2_2:       begin
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 1;
                                SI_data <= {4'b0000, column[3:0]};      // lower column adress           
                            end     
            `DISP3:         begin
                                {RST, A0, LED_A} <= 3'b011;
                                set_convert_SI <= 1;
                                SI_data <= (!idle_flag || clear_lcd)?8'd0:ascii;      // Write data in display data RAM (vertikal, LSB(top)->MSB(bottom))
                            end
            `WAIT:          begin
                                {RST, A0, LED_A} <= 3'b011;             // A0 has to be "1" because its within the SI write process
                                set_convert_SI <= 0;
                            end
            `CLEAR, `WRITE: begin
                                set_convert_SI <= 0;
                                {RST, A0, LED_A} <= 3'b001;
                            end
            `IDLE:          begin
                                {RST, A0, LED_A} <= 3'b001;
                                set_convert_SI <= 0;
                                SI_data <= 8'b00000000;
                            end
        endcase        
    end 
       
endmodule