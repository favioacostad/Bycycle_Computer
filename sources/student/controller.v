`timescale 1us/10ns

module controller (
    input wire clk,
    input wire reset,
    input wire mode_button,
    input wire tick_1s,
    output reg [1:0] mode_flags,     // 00 = DAY, 01 = AVS, 10 = TIM, 11 = MAX
    output reg start_bcd             // 1-cycle pulse to update display
);

    // Internal mode register
    reg [1:0] mode_reg;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            mode_reg <= 2'd0;
        end else if (mode_button) begin
            mode_reg <= (mode_reg + 2'd1) % 4;
        end
    end

    // Assign current mode to output
    always @(*) begin
        mode_flags = mode_reg;
    end

    // START_BCD pulse generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            start_bcd <= 1'b0;
        end else begin
            // Pulse for 1 cycle on tick_1s or mode_button
            start_bcd <= tick_1s | mode_button;
        end
    end
endmodule