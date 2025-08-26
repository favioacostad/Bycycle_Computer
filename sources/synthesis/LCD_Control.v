`include "LCD_macros.v"
`timescale 1ns / 1ps


module LCD_Control(
    input clock,
    input reset,
    input convert_SI,
    input change_to_WRITE,
    input [7:0] state,
    input [7:0] new_state,
    input [7:0] data,
    input [3:0] count,
    input led_a_tmp,
    input a0_tmp,
    output si_conv_timed,
    output change_state,
    output [7:0] data_stream, 
    output led_a,
    output a0
    );
    
    reg order_state;
    reg pulse_was_sent;
    reg [7:0] state_curr;
    reg [7:0] stream;           
    reg a0_contr, led_a_contr;
    reg si_conv;
    reg stored_order;
    
    
    assign led_a            = led_a_contr;
    assign a0               = a0_contr;
    assign data_stream      = stream;
    assign change_state     = order_state;// + change_to_WRITE;
    assign si_conv_timed    = si_conv;    
        
        
    always @(change_to_WRITE, pulse_was_sent, stored_order) begin
        if(change_to_WRITE)
            stored_order    <= 1;
        else
            if(pulse_was_sent)
                stored_order    <= 0;
            else
                stored_order    <= stored_order;                
    end
    
    always @(posedge clock) begin :ORDER_STATE_AND_SAFE_VALUES_TILL_NEEDED
        if(reset) begin
            order_state     <= 0;
            pulse_was_sent  <= 0;
            state_curr      <= 0;
            stream          <= 8'b00000000;
            si_conv         <= 0;       
        end
        else begin    
            if(!convert_SI) begin                           // No command/data is needed [RESET/START/LCD_ON/IDLE]
                if(state != `IDLE) begin
                    if(state<`INIT1) begin                  // Without -> the states change to early and an unwanted code is send 
                        led_a_contr     <= led_a_tmp;
                        a0_contr        <= a0_tmp; 
                    end                    
                    if(!pulse_was_sent) begin
                        order_state     <= 1;
                        pulse_was_sent  <= 1;
                        state_curr      <= state_curr;
                    end
                    else begin
                        order_state     <= 0;
                        state_curr      <= state_curr != new_state?new_state:state_curr;
                        pulse_was_sent  <= state_curr != new_state?0:1;
                    end                    
                end
                else begin
                    led_a_contr     <= led_a_tmp;
                    a0_contr        <= a0_tmp;
                    if(!pulse_was_sent) begin
                        order_state     <= order_state + stored_order;
                        pulse_was_sent  <= order_state?1:0;
                        state_curr      <= state_curr;
                    end
                    else begin
                        order_state     <= 0;
                        state_curr      <= state_curr != new_state?new_state:state_curr;
                        pulse_was_sent  <= state_curr != new_state?0:1;
                    end
                end
            end
            else begin                                          // command/data is needed 
                case(count)
                    0: begin                                    // Convert the SI_Data from last last Step
                            led_a_contr     <= led_a_tmp;
                            a0_contr        <= a0_tmp;
                            si_conv         <= convert_SI;
                            order_state     <= 0;
                            pulse_was_sent  <= 0;
                            stream          <= data;
                            state_curr      <= new_state;      
                       end
                    1: begin                                    // Trigger New State = grap the futur SI_Data and hold till count==0        
                            if(!pulse_was_sent) begin                        
                                order_state     <= 1;
                                pulse_was_sent  <= 1;
                            end
                            else begin
                                pulse_was_sent  <= 1;
                                order_state     <= 0;
                            end      
                        end   
                    15: begin
                            si_conv         <= convert_SI;
                            order_state     <= 0;
                            pulse_was_sent  <= 0;  
                        end
                    default: begin
                            order_state     <= 0;
                            pulse_was_sent  <= 0;
                         end
                endcase          
            end          
        end
    end
endmodule
