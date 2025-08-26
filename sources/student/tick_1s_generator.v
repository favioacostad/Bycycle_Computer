`timescale 1us/10ns

module tick_1s_generator (
    input wire clk,
    input wire reset,
    output reg tick_1s
);

// 1 Second ON - 1 Second OFF

    localparam integer MAX_COUNT = 2047;  // 2048 cycles total

    reg [10:0] counter;  // 2^11 = 2048

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            counter <= 11'd0;
            tick_1s <= 1'b0;
        end else begin
            if (counter == MAX_COUNT) begin
                counter <= 11'd0;
                tick_1s <= 1'b1;  // 1-cycle pulse
            end else begin
                counter <= counter + 1;
                tick_1s <= 1'b0;
            end
        end
    end
endmodule