`timescale 1ns / 1ps

// This file has to be a Global Include. Set it by right-clicking on the file.

    
`define Interface    0    // LCD Interface Mode: 8080 [0], 6800 [1] 


`define RESET        0
`define ERROR        0
`define START        1      // Required: Reset = 1 
`define LCD_ON       2      // Required: Reset = 1 
`define INIT1        3      // Initial: LCD BIAS SETTING
`define INIT2        4      // Initial: ADC selection
`define INIT3        5      // Initial: COM output state selection
`define INIT4        6      // Initial: Setting the built-in resistance radio for regulation of the V0 voltage
`define INIT5_1      7      // Initial: Electronic Volume Mode Set (Part 1) (18)
`define INIT5_2      8      // Initial: Electronic Volume Mode Set (Part 2) (18)
`define INIT6        9      // Initial: Power circuit operation mode (16)
`define INIT7       10      // Initial: Display ON/OFF    
`define CLEAR       11      // Clear - Task Disp1-Disp3  
`define DISP0       12      // Page address set
`define DISP1       13      // Page address set
`define DISP2_1     14      // column adress set
`define DISP2_2     15      // column adress set        
`define WAIT        16      // Get Data for DISP3  
`define DISP3       17      // Write data in display data RAM            
`define IDLE        18      // Wait for Input/Changes
`define WRITE       19      // Start writing process to LCD: DISP1->DISP2_1->DISP2_2->WAIT->DISP3....

`define textsize_small      0       // ID for textsize small
`define whitespace_small    1       // Empty Space between the Symbols
`define lineheight_small    1       // Amount of Line-Groups (each with 8 Pixel height) the Symbol need

`define textsize_big        1       // ID for textsize big
`define whitespace_big      1       // Empty Space between the Symbols
`define lineheight_big      2       // Amount of Line-Groups (each with 8 Pixel height) the Symbol need
    
//module LCD_macros(
//        );
//endmodule
