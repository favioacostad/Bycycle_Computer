`timescale 1us/10ns

module max_speed (
    input wire clk,               // Clock signal
    input wire reset,             // Reset signal
    input wire [6:0] kmh,         // Instantaneous speed (0-99)
    output reg [6:0] max          // Maximum speed recorded
);

    localparam KMH_MAX     = 7'd99;     // Maximum displayable speed

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            max <= 7'd0;
        end else if (kmh > max) begin
            // Compare current KMH with MAX and update if greater
            if (kmh > KMH_MAX) begin
                max <= KMH_MAX;
            end else begin
                max <= kmh;
            end
            // Else hold current max
        end
    end

endmodule
