`timescale 1us/10ns

module instantaneous_speed (
    input wire clk,
    input wire reset,
    input wire reed,               // Reed switch (level or pulse)
    input wire [7:0] circ,         // Wheel circumference in cm
    output reg [6:0] kmh           // Instantaneous speed (0-99 km/h)
);

    // Constants
    localparam TIMEOUT_MAX = 14'd16000;  // ~8 seconds at clk rate
    localparam KMH_MAX     = 7'd99;     // Maximum displayable speed

    // Registers
    reg [14:0] count;                // Counts cycles between pulses
    reg measuring;                   // Are we currently measuring?
    reg [15:0] constant;             // Precomputed scaling factor
    reg [13:0] timeout_count;        // Watchdog timer
    reg [6:0] kmh_prep;        

    // Edge detection
    reg reed_prev;                   // Delay register to detect rising edge
    wire reed_rising;

    assign reed_rising = (reed && !reed_prev);  // rising edge detector

    // Main speed measurement logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            count <= 15'd0;
            measuring <= 1'b0;
            kmh <= 7'd0;
            timeout_count <= 14'd0;
            constant <= 16'd0;
            reed_prev <= 1'b0;
        end else begin
            // For rising edge detection
            reed_prev <= reed;  // store previous reed state

            // Constant value scaler
            //constant <= ((circ * 18874) >> 8);  // Scaled constant
            constant <= ((circ * 295) >> 2);  // Scaled constant

            // Timeout handling: if no pulse for a long time → kmh=0
            if (timeout_count >= TIMEOUT_MAX - 1) begin
                kmh <= 7'd0;
                measuring <= 1'b0;
                count <= 15'd0;
                timeout_count <= 14'd0;
            end else begin
                timeout_count <= timeout_count + 1;
            end

            // Rising edge of reed detected
            if (reed_rising) begin
                timeout_count <= 14'd0;
                
                if (!measuring) begin
                    // First pulse: start timer
                    count <= 15'd0;
                    measuring <= 1'b1;
                end else begin
                    // Second pulse: calculate speed
                    if (count != 0) begin
                        kmh_prep <= (constant + (count >> 1)) / count;  // Rounded division
                        if (kmh_prep > KMH_MAX) begin
                            kmh <= KMH_MAX;
                        end else begin
                            kmh <= kmh_prep;
                        end
                        
                    end else begin
                        kmh <= 7'd0;
                    end
                    measuring <= 1'b0;
                    count <= 15'd0;
                end
            end else if (measuring) begin
                count <= count + 1;  // Increment counter while waiting for next pulse
            end
        end
    end

endmodule
