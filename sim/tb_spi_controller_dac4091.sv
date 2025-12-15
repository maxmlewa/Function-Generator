`timescale 1ns/1ps
`default_nettype none

module tb_spi_controller_dac4091;

    // Clock generation (100 MHz)
    logic clk = 0;
    always #5 clk = ~clk;  // 10 ns period

    // DUT I/O signals
    logic rst;

    logic [11:0] dac_code;
    logic dac_valid;
    logic dac_ready;


    logic cs_n, sclk, copi;

    // Instantiate DUT
    localparam int SCLK_DIV = 6;
    localparam bit CFG_BUF = 1;     // [14]
    localparam bit CFG_GAIN1X = 1;  // [13] (1=1x, 0=2x)
    localparam bit CFG_ACTIVE = 1; 

    spi_controller_dac4091 #(
        .SCLK_DIV(SCLK_DIV),
        .CFG_BUF(CFG_BUF),       // [14]
        .CFG_GAIN1X(CFG_GAIN1X), // [13] (1=1x, 0=2x)
        .CFG_ACTIVE(CFG_ACTIVE) 
    ) dut (
        .clk(clk),
        .rst(rst),

        .dac_code(dac_code),
        .dac_valid(dac_valid),
        .dac_ready(dac_ready),

        .cs_n(cs_n),
        .sclk(sclk),
        .copi(copi)
    );

    // Capture/check variables
    reg [15:0] captured;
    reg [15:0] expected;
    integer i;
    integer frame_idx;
    integer pass_cnt;

    time t_start, t_end;
    real t_frame_ns, t_frame_us, kframes_per_s;



    // Main test
    initial begin
        // init
        rst = 1'b1;
        dac_valid = 1'b0;
        dac_code  = 12'h000;

        pass_cnt = 0;

        // reset
        repeat (5) @(posedge clk);
        rst = 1'b0;
        repeat (2) @(posedge clk);

        // small idle settle
        repeat (5) @(posedge clk);

        // Run 5 frames back2back
        for (frame_idx = 0; frame_idx < 5; frame_idx = frame_idx + 1) begin

            // picking deterministic-ish (arbitrarily)  codes (easy to recognize in waves)
            case (frame_idx)
                0: dac_code = 12'h2B7;
                1: dac_code = 12'h123;
                2: dac_code = 12'hFFF;
                3: dac_code = 12'h000;
                default: dac_code = 12'hA5A;
            endcase

            expected = {1'b0, 1'b1, 1'b1, 1'b1, dac_code};

            // wait until ready then pulse valid for 1 cycle
            wait (dac_ready === 1'b1);
            @(posedge clk);
            dac_valid = 1'b1;
            @(posedge clk);
            dac_valid = 1'b0;

            // wait for transaction start
            wait (cs_n === 1'b0);
            t_start = $time;

            // capture 16 bits on rising edges of sclk
            captured = 16'h0000;
            for (i = 0; i < 16; i = i + 1) begin
                @(posedge sclk);
                captured = {captured[14:0], copi};
            end

            // wait for cs_n to return high (latch)
            wait (cs_n === 1'b1);
            t_end = $time;

            // timing calc
            t_frame_ns   = (t_end - t_start);      // in ns
            t_frame_us   = t_frame_ns / 1000.0;   // us
            kframes_per_s = 1000.0 / t_frame_us;  // kframes/sec

            // print results
            $display("------------------------------------------------------------");
            $display("Frame %0d", frame_idx);
            $display("Expected: 0x%04h  Captured: 0x%04h", expected, captured);
            $display("Frame time: %0.3f us   (~%0.1f kFrames/s)", t_frame_us, kframes_per_s);

            if (captured === expected) begin
                $display("STATUS: PASS");
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("STATUS: FAIL");
            end
            $display("------------------------------------------------------------");

            // small pause between frames (optional)
            repeat (3) @(posedge clk);

        end

        $display("PASS COUNT: %0d / 5", pass_cnt);
        if (pass_cnt == 5) $display("ALL TESTS PASSED");
        else $display("ONE OR MORE TESTS FAILED");


        
        #2000;
        $finish;
    end

endmodule

`default_nettype wire
