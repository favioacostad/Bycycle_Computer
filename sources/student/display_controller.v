`timescale 1us/10ns

module display_controller (
    input wire clock,
    input wire reset,
    input wire blink,
    input wire tick_1s,
    input wire start_bcd,
    input wire [1:0] mode_flags,
    input wire [6:0] kmh,
    input wire [13:0] day,
    input wire [19:0] tim,
    input wire [6:0] max,
    input wire [9:0] avs,

    output reg AVS_OUT,
    output reg DAY_OUT,
    output reg MAX_OUT,
    output reg TIM_OUT,

    output reg [7:0] upper10,
    output reg [7:0] upper01,
    output reg [7:0] lower1000,
    output reg [7:0] lower0100,
    output reg [7:0] lower0010,
    output reg [7:0] lower0001,

    output reg point,
    output reg col
);

    // -----------------------------------
    // KMH / BCD / ASCII (Upper display)
    // -----------------------------------
    wire [15:0] kmh_bcd;
    wire kmh_finish;
    reg start_bcd_sync;

    dual2bcd #(
        .dualwidth(14),
        .bcdwidth(16)
    ) kmh_to_bcd (
        .clock(clock),
        .reset(reset),
        .start(start_bcd_sync),
        .dual({7'd0, kmh}),
        .finish(kmh_finish),
        .bcd(kmh_bcd)
    );

    wire [3:0] kmh_10 = kmh_bcd[7:4];
    wire [3:0] kmh_01 = kmh_bcd[3:0];
    wire [7:0] ascii_kmh_10;
    wire [7:0] ascii_kmh_01;

    bcd2ascii kmh_tens (
        .bcd(kmh_10),
        .displ(ascii_kmh_10)
    );

    bcd2ascii kmh_ones (
        .bcd(kmh_01),
        .displ(ascii_kmh_01)
    );

    // -------------------------------
    // BCD / ASCII Conversion Signals
    // -------------------------------
    reg [15:0] selected_value;
    wire [15:0] bcd_out;
    wire finish_bcd;

    dual2bcd #(
        .dualwidth(16),
        .bcdwidth(16)
    ) bcd_converter (
        .clock(clock),
        .reset(reset),
        .start(start_bcd_sync),
        .dual(selected_value),
        .finish(finish_bcd),
        .bcd(bcd_out)
    );

    wire [3:0] bcd_0001 = bcd_out[3:0];
    wire [3:0] bcd_0010 = bcd_out[7:4];
    wire [3:0] bcd_0100 = bcd_out[11:8];
    wire [3:0] bcd_1000 = bcd_out[15:12];

    wire [7:0] asc_0001, asc_0010, asc_0100, asc_1000;

    bcd2ascii d0 (.bcd(bcd_0001), .displ(asc_0001));
    bcd2ascii d1 (.bcd(bcd_0010), .displ(asc_0010));
    bcd2ascii d2 (.bcd(bcd_0100), .displ(asc_0100));
    bcd2ascii d3 (.bcd(bcd_1000), .displ(asc_1000));

    // -------------------------------
    // COL toggle
    // -------------------------------
    reg col_state;

    always @(posedge clock or posedge reset) begin
        if (reset)
            col_state <= 1'b0;
        else if (tick_1s)
            col_state <= ~col_state;
    end

    // -------------------------------
    // Mode blinking logic
    // -------------------------------
    reg [3:0] mode_out_all;

    // -------------------------------
    // TIM format split (HH:MM or MM:SS)
    // -------------------------------
    reg [7:0] tim_high_bin, tim_low_bin;

    always @(*) begin
        if (tim < 3600) begin
            tim_high_bin = tim / 60;        // MM
            tim_low_bin  = tim % 60;        // SS
        end else begin
            tim_high_bin = tim / 3600;      // HH
            tim_low_bin  = (tim / 60) % 60; // MM
        end
    end

    wire [15:0] bcd_high, bcd_low;
    wire finish_high, finish_low;

    dual2bcd #(.dualwidth(14), .bcdwidth(16)) conv_high (
        .clock(clock),
        .reset(reset),
        .start(start_bcd_sync),
        .dual({6'd0, tim_high_bin}),
        .finish(finish_high),
        .bcd(bcd_high)
    );

    dual2bcd #(.dualwidth(14), .bcdwidth(16)) conv_low (
        .clock(clock),
        .reset(reset),
        .start(start_bcd_sync),
        .dual({6'd0, tim_low_bin}),
        .finish(finish_low),
        .bcd(bcd_low)
    );

    wire [3:0] bcd_high_1 = bcd_high[3:0];
    wire [3:0] bcd_high_10 = bcd_high[7:4];
    wire [3:0] bcd_low_1 = bcd_low[3:0];
    wire [3:0] bcd_low_10 = bcd_low[7:4];

    wire [7:0] asc_high_1, asc_high_10, asc_low_1, asc_low_10;

    bcd2ascii bh0 (.bcd(bcd_high_1),  .displ(asc_high_1));
    bcd2ascii bh1 (.bcd(bcd_high_10), .displ(asc_high_10));
    bcd2ascii bl0 (.bcd(bcd_low_1),   .displ(asc_low_1));
    bcd2ascii bl1 (.bcd(bcd_low_10),  .displ(asc_low_10));

    // -------------------------------
    // Start signal sync
    // -------------------------------
    always @(posedge clock or posedge reset) begin
        if (reset)
            start_bcd_sync <= 0;
        else
            start_bcd_sync <= start_bcd;
    end

    // -------------------------------
    // Mode selection and outputs
    // -------------------------------
    always @(*) begin
        // Defaults
        point = 0;
        col = 0;
        selected_value = 16'd0;
        mode_out_all = 4'd0;

        case (mode_flags)
            2'b00: begin // DAY
                selected_value = {2'b00, day};
                point = 1;
                mode_out_all = {blink, blink, blink, 1'b1}; // MAX, AVS, TIM, DAY
            end
            2'b01: begin // AVS
                selected_value = {6'd0, avs};
                point = 1;
                mode_out_all = {blink, blink, 1'b1, blink};
            end
            2'b10: begin // TIM
                // Uses separate bcd_high and bcd_low instead
                col = col_state;
                mode_out_all = {blink, 1'b1, blink, blink};
            end
            2'b11: begin // MAX
                selected_value = {9'd0, max};
                mode_out_all = {1'b1, blink, blink, blink};
            end
        endcase
    end

    always @(*) begin
        MAX_OUT = mode_out_all[3];
        TIM_OUT = mode_out_all[2];
        AVS_OUT = mode_out_all[1];
        DAY_OUT = mode_out_all[0];
    end

    // -------------------------------
    // Display digit update
    // -------------------------------
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            upper10     <= 8'd0;
            upper01     <= 8'd0;
            lower1000   <= 8'd0;
            lower0100   <= 8'd0;
            lower0010   <= 8'd0;
            lower0001   <= 8'd0;
        end else begin
            // Always update upper display with KMH
            upper10 <= ascii_kmh_10;
            upper01 <= ascii_kmh_01;
            
            // Update lower display
            if (mode_flags == 2'b10 && finish_high && finish_low) begin
                // TIM: MM:SS or HH:MM
                lower1000   <= asc_high_10;
                lower0100   <= asc_high_1;
                lower0010   <= asc_low_10;
                lower0001   <= asc_low_1;
            end else if (finish_bcd && mode_flags != 2'b10) begin
                // Other modes
                lower1000   <= asc_1000;
                lower0100   <= asc_0100;
                lower0010   <= asc_0010;
                lower0001   <= asc_0001;
            end
        end
    end

endmodule
