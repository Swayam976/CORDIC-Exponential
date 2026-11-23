`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 01:29:35 AM
// Design Name: 
// Module Name: range_reduce
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module range_reduce (
    input  signed [15:0] x_in,    // Q4.12
    output signed [4:0]  k,       // integer, -12..+12
    output signed [21:0] r        // Q2.20
);
    localparam signed [17:0] INV_LN2 = 18'sd94548;
    localparam signed [24:0] LN2_HI  = 25'sd11629080;
    
    wire signed [33:0] prod = x_in * INV_LN2;
    assign k = (prod + (1 << 27)) >>> 28;
    wire signed [33:0] r24  = (x_in <<< 12) - k * LN2_HI;
    assign r = (r24 + (1 << 3)) >>> 4; 
endmodule
