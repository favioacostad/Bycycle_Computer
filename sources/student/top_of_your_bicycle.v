`timescale 1us/10ns

module TOP_OF_YOUR_BICYCLE (
  input wire clock,
  input wire mode,
  input wire reed,
  input wire reset,
  input wire [7:0] circ,
  output wire AVS,
  output wire DAY,
  output wire MAX,
  output wire TIM,
  output wire col,
  output wire point,
  output wire [7:0] lower0001,
  output wire [7:0] lower0010,
  output wire [7:0] lower0100,
  output wire [7:0] lower1000,
  output wire [7:0] upper01,
  output wire [7:0] upper10
);


// Place your code here
// Internal signals
wire [6:0] kmh;
wire [6:0] max_kmh;
wire [13:0] day;
wire [19:0] tim;
wire [9:0] avs;
wire tick_1s;
wire [1:0] mode_flags;
wire blink;
wire start_bcd;

// Blinker
blinker blinker_unit (
    .clk(clock),
    .reset(reset),
    .kmh(kmh),
    .blink(blink)
);

// Tick generator: 1Hz
tick_1s_generator tick_1s_generator_unit (
    .clk(clock),
    .reset(reset),
    .tick_1s(tick_1s)
);

// Instantaneous speed
instantaneous_speed instantaneous_speed_unit (
    .clk(clock),
    .reset(reset),
    .reed(reed),
    .circ(circ),
    .kmh(kmh)
);

// Max speed
max_speed max_speed_unit (
    .clk(clock),
    .reset(reset),
    .kmh(kmh),
    .max(max_kmh)
);

// Trip distance
trip_distance trip_distance_unit (
    .clk(clock),
    .reset(reset),
    .reed(reed),
    .circ(circ),
    .kmh(kmh),
    .day(day)
);

// Trip time
trip_time trip_time_unit (
    .clk(clock),
    .reset(reset),
    .reed(reed),
    .tick_1s(tick_1s),
    .kmh(kmh),
    .tim(tim)
);

// Average speed
average_speed average_speed_unit (
    .clk(clock),
    .reset(reset),
    .tick_1s(tick_1s),
    .day(day),
    .tim(tim),
    .avs(avs)
);

// Mode controller
controller controller_unit (
    .clk(clock),
    .reset(reset),
    .mode_button(mode),
    .tick_1s(tick_1s),
    .start_bcd(start_bcd),
    .mode_flags(mode_flags)
);

// Display controller
display_controller display_driver (
    .clock(clock),
    .reset(reset),
    .blink(blink),
    .tick_1s(tick_1s),
    .start_bcd(start_bcd),
    .mode_flags(mode_flags),
    .day(day),
    .tim(tim),
    .avs(avs),
    .max(max_kmh),
    .kmh(kmh),

    .AVS_OUT(AVS),
    .DAY_OUT(DAY),
    .MAX_OUT(MAX),
    .TIM_OUT(TIM),
    
    .upper10(upper10),
    .upper01(upper01),
    .lower1000(lower1000),
    .lower0100(lower0100),
    .lower0010(lower0010),
    .lower0001(lower0001),

    .point(point),
    .col(col)
);

// Placeholders
/*assign lower0001 = 8'h00;
assign lower0010 = 8'h00;
assign lower0100 = 8'h00;
assign lower1000 = 8'h00;

assign point = 1'b0;
assign col   = 1'b0;

assign DAY = (mode_flags == 2'b00);
assign AVS = (mode_flags == 2'b01);
assign TIM = (mode_flags == 2'b10);
assign MAX = (mode_flags == 2'b11);*/

endmodule
