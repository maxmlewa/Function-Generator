`timescale 1ns/1ps
`default_nettype none

module tb_dds_core;

  // 100 MHz clock
  logic clk = 1'b0;
  always #5 clk = ~clk;

  // DUT signals
  logic rst;

  logic [15:0] freq_word;
  logic [2:0]  wave_sel;
  logic [11:0] dc_level;
  logic [11:0] wave_out;



  // Instantiate DUT
  dds_core #(
    .PHASE_WIDTH(24),
    .AMP_WIDTH(12),
    .LUT_ADDR_BITS(10),
    .FS_HZ(1_041_100)
  ) dut (
    .clk(clk),
    .rst(rst),
    .freq_word(freq_word),
    .wave_sel(wave_sel),
    .dc_level(dc_level),
    .wave_out(wave_out)
  );


  // Helpers 
  task automatic run_cycles(input int n);
    int k;
    begin
      for (k = 0; k < n; k = k + 1) @(posedge clk);
    end
  endtask

  task automatic show_samples(input string label, input int count, input int stride);
    int k;
    begin
      $display("---- %s ----", label);
      for (k = 0; k < count; k = k + 1) begin
        run_cycles(stride);
        $display("t=%0t ns  wave_out=0x%03h (%0d)", $time, wave_out, wave_out);
      end
    end
  endtask



  // Test sequence
  initial begin
    // init
    rst       = 1'b1;
    freq_word = 16'd0;
    wave_sel  = 3'd4;        // DC
    dc_level  = 12'h800;     // midscale

    // reset
    run_cycles(10);
    rst = 1'b0;
    run_cycles(10);


    // 1) DC sanity
    wave_sel  = 3'd4;
    freq_word = 16'd0;
    dc_level  = 12'h555;
    run_cycles(50);
    show_samples("DC @ 0x555", 6, 20);



    // 2) Ramp @ 10 kHz (expecting to visibly climb)
    wave_sel  = 3'd3;        // ramp
    freq_word = 16'd10000;   // 10 kHz
    run_cycles(50);
    show_samples("RAMP @ 10kHz", 10, 200); // smaller stride to see the climbing



    // 3) Triangle @ 10 kHz
    wave_sel  = 3'd2;        // triangle
    freq_word = 16'd10000;
    run_cycles(50);
    show_samples("TRI @ 10kHz", 10, 200);


    // 4) Square @ 25 kHz (expecting to toggle)
    wave_sel  = 3'd1;        // square
    freq_word = 16'd25000;
    run_cycles(50);
    show_samples("SQUARE @ 25kHz", 12, 80);



    // 5) Sine @ 5 kHz (verify LUT loads + output not flat)
    //  Expected  2-cycle latency on the wave output does not affect the form
    wave_sel  = 3'd0;        // sine
    freq_word = 16'd5000;    // 5 kHz
    run_cycles(200);
    show_samples("SINE @ 5kHz", 20, 400);

    $display("DDS_CORE TB DONE");
    run_cycles(50);
    $finish;
  end

endmodule

`default_nettype wire
