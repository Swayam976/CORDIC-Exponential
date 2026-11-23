`timescale 1ns/1ps
module cordic_tb();

    // ---------------- DUT signals ----------------
    reg                 clk = 0, rst = 1, start = 0;
    reg  signed [21:0]  r_in = 0;
    wire                done;
    wire signed [21:0]  e_out;

    cordic dut (.clk(clk), .rst(rst), .start(start),
                .r_in(r_in), .done(done), .e_out(e_out));

    always #5 clk = ~clk;                     // 100 MHz

    // ---------------- bookkeeping ----------------
    integer fd, n;                            // file handle, items read
    integer r_val, exp_val;                   // one line of the file
    integer checked = 0, errors = 0;
    integer cycles;                           // latency of the last test

    initial begin
        // 1. open the vector file
        fd = $fopen("C:/Xilinx Projects/CORDIC/vectors.txt", "r");
        if (fd == 0) begin
            $display("ERROR: could not open vectors.txt");
            $finish;
        end

        // 2. reset
        repeat (3) @(posedge clk);
        rst = 0;

        // 3. one test per line
        while (!$feof(fd)) begin
            n = $fscanf(fd, "%d %d\n", r_val, exp_val);
            if (n == 2) begin
                // drive input and pulse start for one cycle
                @(negedge clk);
                r_in  = r_val;
                start = 1;
                @(negedge clk);
                start = 0;

                // wait for done, counting cycles
                cycles = 1;
                while (!done) begin
                    @(negedge clk);
                    cycles = cycles + 1;
                end

                // compare, bit for bit
                checked = checked + 1;
                if (e_out !== exp_val[21:0]) begin
                    errors = errors + 1;
                    if (errors <= 5)
                        $display("MISMATCH r=%0d  got=%0d  expected=%0d",
                                 r_val, e_out, exp_val);
                end
            end
        end

        // 4. summary
        $fclose(fd);
        $display("------------------------------------------");
        $display("checked=%0d  errors=%0d  latency=%0d cycles",
                 checked, errors, cycles);
        if (checked > 0 && errors == 0) $display("PASS");
        else                            $display("FAIL");
        $display("------------------------------------------");
        $finish;
    end

    // 5. watchdog: if done never arrives, don't hang forever
    initial begin
        #50_000_000;
        $display("TIMEOUT: done never asserted");
        $finish;
    end
endmodule
