`timescale 1us/10ns

module trip_distance (
    input wire clk,
    input wire reset,
    input wire reed,
    input wire [7:0] circ,         // wheel circumference in cm
    input wire [6:0] kmh,          // Instantaneous speed (0-99 km/h)
    output reg [13:0] day          // distance in 0.1 km units
);

    reg [23:0] distance_cm;        // Accumulator for total distance in cm
    reg reed_prev;

    wire reed_pulse;
    assign reed_pulse = (reed && !reed_prev);  // rising edge detector

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            distance_cm <= 24'd0;
            day <= 14'd0;
            reed_prev <= 1'b0;
        end else begin
            reed_prev <= reed;  // store previous reed state
            
            if (reed_pulse) begin
                // Only count time if speed >= 5 km/h
                if (kmh >= 7'd5) begin
                    // Add wheel circumference to total distance
                    distance_cm <= distance_cm + circ;
                    
                    // Check if enough cm accumulated to increment DAY
                    if (distance_cm + circ >= 10000) begin
                        // Compute how many 0.1 km units (10,000 cm)
                        // and subtract those from cm accumulator
                        // while updating DAY
                        distance_cm <= (distance_cm + circ) % 10000;
                        day <= day + ((distance_cm + circ) / 10000);
                    end
                end
            end
        end
    end

endmodule
