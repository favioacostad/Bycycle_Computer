`timescale 1us/10ns

module blinker (
    input wire clk,
    input wire reset,
    input wire [6:0] kmh,
    output reg blink
);

    // Parameters
    localparam ON_CYCLES  = 12'd1024;  // 0.5 seconds at 2.048 kHz
    localparam OFF_CYCLES = 12'd2048;  // 1.0 seconds at 2.048 kHz

    // Registers
    reg [11:0] counter;
    reg state_on;  // 1 = ON period, 0 = OFF period

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter   <= 12'd0;
            blink     <= 1'b0;
            state_on  <= 1'b1;
        end else begin
            if (kmh <= 7'd65) begin
                // Normal case: not blinking
                blink <= 1'b0;
                counter <= 12'd0;
                state_on <= 1'b1;
            end else begin
                // Blinking logic
                counter <= counter + 1;

                if (state_on && counter >= ON_CYCLES - 1) begin
                    blink <= 1'b0;
                    counter <= 12'd0;
                    state_on <= 1'b0;
                end else if (!state_on && counter >= OFF_CYCLES - 1) begin
                    blink <= 1'b1;
                    counter <= 12'd0;
                    state_on <= 1'b1;
                end
            end
        end
    end

endmodule
