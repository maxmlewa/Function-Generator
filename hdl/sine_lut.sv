`timescale 1ns/1ps
`default_nettype none

// implemented from the previous sine LUT 
// wrapper for the single port BRAM with same interface 
// as the infered ROM

module sine_lut #(
    
    parameter int PHASE_WIDTH = 10,   // address width (ROM_DEPTH = 2^PHASE_WIDTH)
    parameter int AMP_WIDTH = 16,   // output width
    parameter string INIT_FILE  = "sine_lut.mem",
    parameter string RAM_PERFORMANCE = "HIGH_PERFORMANCE" // 2-cycle read latency

)(
    input  wire  clk,
    input  wire [PHASE_WIDTH-1:0]  phase,
    output logic [AMP_WIDTH-1:0]    sine_out
);

    localparam int ROM_DEPTH = 1 << PHASE_WIDTH;

    // BRAM wrapper
    xilinx_single_port_ram_read_first #(
        .RAM_WIDTH (AMP_WIDTH),
        .RAM_DEPTH (ROM_DEPTH),
        .RAM_PERFORMANCE(RAM_PERFORMANCE),
        .INIT_FILE (INIT_FILE)
    ) u_sine_bram (
        .addra  (phase),     // address from phase accumulator
        .dina ('0),        // read-only
        .clka (clk),
        .wea (1'b0),      // no writes
        .ena (1'b1),
        .rsta (1'b0),      // no output reset needed
        .regcea (1'b1),
        .douta (sine_out)
    );
       
endmodule

`default_nettype wire