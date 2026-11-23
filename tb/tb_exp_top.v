`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/16/2026 01:57:31 AM
// Design Name: 
// Module Name: tb_exp_top
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


module tb_exp_top;
    reg                 clk = 0, rst = 1, start = 0;
    reg  signed [15:0]  x_in = 0;
    wire                done;
    wire signed [21:0]  mant;
    wire signed [4:0]   expo;

    exp_top dut (.clk(clk), .rst(rst), .start(start), .x_in(x_in),
                 .done(done), .mant(mant), .expo(expo));

    always #5 clk = ~clk;

    integer fd, n;
    reg [15:0] x_val;         
    reg [21:0] m_exp;
    reg [4:0]  k_exp;
    integer checked = 0, skipped = 0, errors = 0, cycles;

    initial begin
        fd = $fopen("C:/Xilinx Projects/CORDIC/top_vectors.txt", "r");
        if (fd == 0) begin $display("ERROR: could not open top_vectors.txt"); $finish; end

        repeat (3) @(posedge clk);
        rst = 0;

        while (!$feof(fd)) begin
            n = $fscanf(fd, "%h %h %h\n", x_val, m_exp, k_exp);
            if (n == 3) begin
                @(negedge clk);
                x_in  = x_val;
                start = 1;
                @(negedge clk);
                start = 0;
                x_in  = 16'h7FFF;        // change x right away: proves k is held

                cycles = 1;
                while (!done) begin @(negedge clk); cycles = cycles + 1; end

                checked = checked + 1;
                if (mant !== m_exp || expo !== k_exp) begin
                    errors = errors + 1;
                    if (errors <= 5)
                        $display("MISMATCH x=%0d  got m=%0d k=%0d  exp m=%0d k=%0d",
                                 x_val, mant, expo, m_exp, k_exp);
                end
            end
            else begin
                skipped = skipped + 1;
                if (skipped <= 3) $display("SKIPPED line, fscanf returned %0d", n);
            end
        end
        $fclose(fd);
        $display("------------------------------------------");
        $display("checked=%0d  skipped=%0d  errors=%0d  last_x=%0d  latency=%0d cycles",
         checked, skipped, errors, x_val, cycles);        if (checked > 0 && errors == 0) $display("PASS"); else $display("FAIL");
        $display("------------------------------------------");
        $finish;
    end

    initial begin #100_000_000; $display("TIMEOUT"); $finish; end
endmodule
