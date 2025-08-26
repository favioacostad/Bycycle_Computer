`timescale 1us/10ns

// I prepared tthis testbench to simulate a minimal setup for my modules for now!

module tb_top_minimal;

    reg clk = 0;
    reg reset = 0;
    reg mode = 0;
    reg reed = 0;
    reg [7:0] circ = 8'd220;

    wire AVS, DAY, MAX, TIM;
    wire [7:0] upper01, upper10;
    wire [7:0] lower0001, lower0010, lower0100, lower1000;
    wire point, col;

    TOP_OF_YOUR_BICYCLE dut (
        .clock(clk),
        .mode(mode),
        .reed(reed),
        .reset(reset),
        .circ(circ),
        .AVS(AVS),
        .DAY(DAY),
        .MAX(MAX),
        .TIM(TIM),
        .col(col),
        .point(point),
        .lower0001(lower0001),
        .lower0010(lower0010),
        .lower0100(lower0100),
        .lower1000(lower1000),
        .upper01(upper01),
        .upper10(upper10)
    );

    // Clock generation
    always #0.244 clk = ~clk;  // ~2.048 kHz → 488.28 us per period

    // Stimulus
    initial begin
        // Start with reset
        reset = 1;
        #10;
        reset = 0;

        // Trigger mode switch (simulate MODE press)
        #2000;
        mode = 1;
        #1;
        mode = 0;

        #4000;
        mode = 1;
        #1;
        mode = 0;

        // Trigger REED pulses to simulate wheel revolutions
        #3000;
        reed = 1;
        #1;
        reed = 0;

        #8000;
        reed = 1;
        #1;
        reed = 0;

        // Wait
        #10000;

        $finish;
    end

endmodule
