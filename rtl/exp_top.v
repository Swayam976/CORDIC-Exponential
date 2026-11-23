`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 01:55:27 AM
// Design Name: 
// Module Name: exp_top
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


module exp_top (
    input                     clk, rst,
    input                     start,      // pulse to begin
    input  signed [15:0]      x_in,       // Q4.12
    output reg                done,       // one-cycle pulse when result is ready
    output reg signed [21:0]  mant,       // e^r, Q2.20  (0.70 .. 1.42)
    output reg signed [4:0]   expo        // k:  e^x = mant * 2^expo
);
    // 1. range reduction (combinational): x -> k, r
    wire signed [4:0]  k;
    wire signed [21:0] r;
    range_reduce u_rr (.x_in(x_in), .k(k), .r(r));

    // 2. CORDIC core: r -> e^r, 19 cycles
    wire               core_done, busy;
    wire signed [21:0] e_r;
    cordic u_core (.clk(clk), .rst(rst), .start(start), .r_in(r),
                   .done(core_done), .e_out(e_r), .busy(busy));

    // 3. hold k while the core runs (same load condition as the core)
    reg signed [4:0] k_reg;
    always @(posedge clk)
        if (start && !busy) k_reg <= k;

    // 4. register the outputs
    always @(posedge clk) begin
        if (rst) begin
            done <= 1'b0;
        end else begin
            done <= core_done;
            if (core_done) begin
                mant <= e_r;
                expo <= k_reg;
            end
        end
    end
endmodule
