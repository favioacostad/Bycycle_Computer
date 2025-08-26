`timescale 1us / 10ns

module LCD_ClockDivider #(
        parameter threshold = 7
    )(
    input clock,
    input reset,
    output scl_lcd,
    output scl_func
    );
            
    reg clock_intern;
    reg [3:0] counter;
    reg flag;
    
    always @(posedge clock) begin
        if(reset && flag!=1) begin              // In case of a reset (not a starting reset), the clock is running through
            counter <= threshold;
            clock_intern <= 0;
            flag <= 1;
        end
        else begin
            if(counter == threshold) begin
                clock_intern <= ~clock_intern;
                counter <= 0;
            end
            else begin
                counter <= counter + 1;
            end
        end
    end  
    
    assign scl_lcd = clock_intern;
    assign scl_func = !clock_intern;
        
endmodule