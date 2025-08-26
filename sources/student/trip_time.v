`timescale 1us/10ns

module trip_time (
    input wire clk,              // 2.048 kHz system clock
    input wire reset,
    input wire reed,             // 1-cycle pulse per wheel rotation
    input wire tick_1s,          // 1-cycle pulse every 1 second
    input wire [6:0] kmh,        // Instantaneous speed (0-99 km/h)
    output reg [19:0] tim        // Trip time in seconds (excluding <5km/h)
);

    // Constants
    localparam TIMEOUT_SECONDS = 3'd4;  // Timeout for inactivity

    // Internal registers
    reg [2:0] timeout_seconds;
    reg active;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tim <= 20'd0;
            timeout_seconds <= 3'd0;
            active <= 1'b0;
        end else begin
            if (reed) begin
                active <= 1'b1;
                timeout_seconds <= 3'd0;
            end

            if (tick_1s) begin
                if (active) begin
                    // Only count time if speed >= 5 km/h
                    if (kmh >= 7'd5) begin
                        tim <= tim + 1;
                    end

                    // If no REED pulse, increment timeout
                    if (!reed) begin
                        timeout_seconds <= timeout_seconds + 1;

                        if (timeout_seconds + 1 >= TIMEOUT_SECONDS) begin
                            active <= 1'b0;
                            timeout_seconds <= 3'd0;
                        end
                    end
                end
            end
        end
    end

endmodule
