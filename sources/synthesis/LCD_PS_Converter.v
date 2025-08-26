`timescale 1us / 10ns

module LCD_PS_Converter (
        input clock,
        input reset,
        input [7:0] stream,
        input si_conv,
        input [7:0] state_next,
        output [3:0] count,
        output CS,
        output SI
    );   
    
    reg cs;  
    reg SI_data; 
    reg [3:0] Count;   
    
    always @(posedge clock) begin: CONVERT_PARALLEL_1x8BIT_TO_SERIELL_8x1BIT
        if(reset) begin
            cs <= 0;
            SI_data <= 0;
            Count <= 15;         // Standardm��ig auf 15, f�r kein SI-convert, kommt sonst NIEMALS wieder auf 15
        end
        else begin
            if(si_conv) begin
                if(Count<9)begin   
                    if(Count<8) begin               // For Count > 0
                        if(state_next == `WRITE) begin
                            cs <= Count==0?0:cs;
                        end
                        else begin
                            cs <= 1;
                        end
                        SI_data <= (cs==0 && state_next == `WRITE)?0:stream[7-Count];
                    end
                    else begin
                        cs <= 0;                    // For the time Count==0 lasts, cs <= 0
                        SI_data <= 0; //stream[0];
                    end
                    Count <= Count==8?0:Count + 1;                
                end
                else begin                    
                    Count <= 0;
                end      
            end
        end    
    end 
        
    assign SI = SI_data;   
    assign CS = cs; 
    assign count = Count;
        
endmodule