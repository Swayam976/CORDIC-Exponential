`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/15/2026 08:34:27 PM
// Design Name: 
// Module Name: cordic
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


module cordic(
    input clk, rst,
    input start,
    input signed [21:0] r_in,
    output reg done,
    output reg signed [21:0] e_out,
    output busy    
    );
    reg signed [21:0] x;
    reg signed [21:0] y;
    reg signed [21:0] z;
    reg signed [21:0] atanh;
    reg [4:0] shift_wire;    
    reg [4:0] state;
    reg start_latched;
    
    wire signed [21:0] xs = y >>> shift_wire;
    wire signed [21:0] ys = x >>> shift_wire;
    wire signed [21:0] x_next = z[21] ? x - xs : x + xs;    
    wire signed [21:0] y_next = z[21] ? y - ys : y + ys;
    wire signed [21:0] z_next = z[21] ? z + atanh : z - atanh;
    assign busy = start_latched;
    
    always @ (*) begin
        case (state) 
            5'd0    : shift_wire = 5'd1;
            5'd1    : shift_wire = 5'd2;
            5'd2    : shift_wire = 5'd3;
            5'd3    : shift_wire = 5'd4;
            5'd4    : shift_wire = 5'd4;
            5'd5    : shift_wire = 5'd5;
            5'd6    : shift_wire = 5'd6;
            5'd7    : shift_wire = 5'd7;
            5'd8    : shift_wire = 5'd8;
            5'd9    : shift_wire = 5'd9;
            5'd10   : shift_wire = 5'd10;
            5'd11   : shift_wire = 5'd11;
            5'd12   : shift_wire = 5'd12;
            5'd13   : shift_wire = 5'd13;
            5'd14   : shift_wire = 5'd13;
            5'd15   : shift_wire = 5'd14;
            5'd16   : shift_wire = 5'd15;
            5'd17   : shift_wire = 5'd16;
            default : shift_wire = 5'd0;
        endcase
    end
    
    always @ (*) begin
        case (state)
            5'd0    : atanh = 22'sd575989;
            5'd1    : atanh = 22'sd267820;
            5'd2    : atanh = 22'sd131761;
            5'd3    : atanh = 22'sd65622;
            5'd4    : atanh = 22'sd65622;
            5'd5    : atanh = 22'sd32779;
            5'd6    : atanh = 22'sd16385;
            5'd7    : atanh = 22'sd8192;
            5'd8    : atanh = 22'sd4096;
            5'd9    : atanh = 22'sd2048;
            5'd10   : atanh = 22'sd1024;
            5'd11   : atanh = 22'sd512;
            5'd12   : atanh = 22'sd256;
            5'd13   : atanh = 22'sd128;
            5'd14   : atanh = 22'sd128;
            5'd15   : atanh = 22'sd64;
            5'd16   : atanh = 22'sd32;
            5'd17   : atanh = 22'sd16;
            default : atanh = 22'sd0;
        endcase
    end
    
    always @ (posedge clk) begin
        if (rst) begin
            start_latched <= 1'b0;
            x <= 22'd0;
            y <= 22'd0;
            z <= 22'd0;
            state <= 5'd0;
            done <= 1'b0;
        end
        
        else begin
            done <= 0;
            if (start && !start_latched) begin
                start_latched <= 1;
                x <= 22'd1266152;
                y <= 22'd0;
                z <= r_in;
                state <= 5'd0;
            end
        
            else if (start_latched) begin
                if (state < 5'd17) begin
                    state <= state + 1;
                    x <= x_next;
                    y <= y_next;
                    z <= z_next; 
                end            
                
                else begin
                    state <= 5'd0;
                    e_out <= x_next + y_next;
                    start_latched <= 0;
                    done <= 1;
                end
            end
        end
    end
endmodule
