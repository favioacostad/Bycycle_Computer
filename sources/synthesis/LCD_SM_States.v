`timescale 1us / 10ns


module LCD_SM_States(
    input clock,
    input reset,
    input change_state,
    input [7:0] column_write,
    input [3:0] line_write,
    output [7:0] state,  
    output [7:0] state_next
    );
    
    parameter line_max          =    8;
    parameter column_max        =  129;     
    parameter delay_max         =  400;//1029;

    reg [7:0] last_state, this_state, next_state, next_state_2;
    reg new_state;
    reg [11:0] delay;
    reg [7:0] column, column_limit;
    reg [3:0] line, line_limit; 
    
    assign state = this_state;    
    assign state_next = next_state;    
         
    always @(posedge clock) begin:  STATE_CONTROL
        if(reset) begin
            this_state  <= `RESET;
            new_state   <= 0;
            delay       <= 0;
        end
        else begin      
            new_state   <= new_state + change_state;                    //change_state has a length of only 1 clock cycle
            if(next_state == `LCD_ON && delay < delay_max) begin
                delay       <= delay + 1;
            end
            else begin
                if(new_state>0) begin
                    delay       <= 0;
                    new_state   <= new_state - 1 ;
                    this_state  <= next_state;                  
                end
                else begin
                    delay       <= delay;
                end
            end
        end
    end
     
          
    always @(posedge new_state) begin: WRITE_COUNTER
        case(this_state)
            `START:  begin
                        column_limit    <= 0;
                        line_limit      <= 0;
                        column          <= 0;
                        line            <= 0;
                    end
            `CLEAR:  begin
                        column_limit    <= column_max;         
                        line_limit      <= line_max;
                        column          <= 0;
                        line            <= 0;          
                    end
            `DISP1:  begin
                        line    <= line + 1;
                        column  <= 0;
                    end
            `DISP3:  begin
                        column <= column + 1;
                    end        
            `IDLE:   begin                        
                        column_limit    <= 0;
                        line_limit      <= 0;
                        column          <= 0;
                        line            <= 0;
                    end    
            `WRITE:  begin
                        column_limit    <= column_write<column_max? column_write:column_max;
                        line_limit      <= line_write  <line_max?   line_write  :line_max;                        
                    end         
        endcase
     end    
     
    always @(this_state) begin        
        case(this_state)  
            `RESET:             next_state <= `START;       
            `START:             next_state <= `LCD_ON;          
            `LCD_ON:            next_state <= `INIT1;    
            `INIT1:             next_state <= `INIT2;    
            `INIT2:             next_state <= `INIT3;    
            `INIT3:             next_state <= `INIT4;        
            `INIT4:             next_state <= `INIT5_1;  
            `INIT5_1:           next_state <= `INIT5_2;       
            `INIT5_2:           next_state <= `INIT6;    
            `INIT6:             next_state <= `INIT7;    
            `INIT7:             next_state <= `CLEAR;    
            `CLEAR, `WRITE:     next_state <= `DISP0;     
            `DISP0:             next_state <= `DISP1;  
            `DISP1:             next_state <= `DISP2_1;  
            `DISP2_1:           next_state <= `DISP2_2;  
            `DISP2_2:           next_state <= `WAIT;     
            `DISP3:             begin   
                                    if(column < column_limit)
                                        next_state <= `WAIT;
                                    else
                                        if(line < line_limit)
                                            next_state <= `DISP1;
                                        else
                                            next_state <= `IDLE;    
                                end
            `WAIT:              next_state <= `DISP3;    
            `IDLE:              next_state <= `WRITE;
            default:            next_state <= `ERROR;    
        endcase
    end 
endmodule
