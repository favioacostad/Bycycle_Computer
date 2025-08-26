`timescale 1us/10ns

module average_speed (
    input wire clk,
    input wire reset,
    input wire tick_1s,               // 1 Hz update rate
    input wire [13:0] day,            // Distance in 0.1 km
    input wire [19:0] tim,            // Time in seconds
    output reg [9:0] avs              // Average speed (0.1 km/h)
);

    // Internal 32-bit register to hold scaled numerator
    reg [31:0] numerator;
    reg [31:0] numerator_prev;

    always @(posedge clk or posedge reset) begin
        numerator_prev <= numerator;
    
        if (reset) begin
            avs <= 10'd0;
            numerator_prev <= 32'd0;
        end else if (tick_1s) begin
            if (tim != 0) begin
                // Compute numerator = DAY * 3600
                // Since DAY is in 0.1 km, result is in tenths of km/h
                numerator = day * 32'd3600;

                // Division: AVS = (DAY * 3600) / TIM
                if(numerator_prev != numerator) begin
                    avs <= numerator / tim;
                end

                // Optionally clamp to max 999 (99.9 km/h)
                if (numerator / tim > 999)
                    avs <= 10'd999;
            end else begin
                avs <= 10'd0;  // Avoid division by 0
            end
        end
    end

endmodule
