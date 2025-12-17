`timescale 1ns/1ps
`default_nettype none

// Direct Digital Synthesis (DDS) Core
// - 16-bit frequency word in Hz
// - Waveforms: Sine, Square, Triangle, Ramp, DC
// - 12-bit unsigned output for DAC (0–4095)
//
// freq_word = 1 => 1 Hz output when sample rate = 1.0411 MS/s

module dds_core #(
    parameter int PHASE_WIDTH = 24,     // NCO phase accumulator width
    parameter int AMP_WIDTH = 12,       // DAC resolution
    parameter int LUT_ADDR_BITS = 10,   // Sine LUT address bits
    parameter int FS_HZ = 1_041_100,     // sample/update rate in Hz for 6 clock cycles [unused]
    parameter int F_CLK_SYS = 100_000_000 // system clock frequency
)(
    input  wire clk,
    input  wire rst,
 
    input  wire [15:0] freq_word,   // Frequency input (in Hz, 16-bit)
    input  wire [2:0] wave_sel,     // Waveform select: 0=sine, 1=square, 2=triangle, 3=ramp, 4=DC
    input  wire [AMP_WIDTH-1:0]  dc_level,  // DC output override (when wave_sel=4)
    output logic [AMP_WIDTH-1:0] wave_out   // DAC output sample 
);

    // Phase increment computation
    //   frequency word => desired frequency
    //   phase_inc = freq_word * (2 ^ PHASE_WIDTH) / FS_HZ
    // using MULT = ((2 ^ PHASE_WIDTH) / F_CLK_SYS )* 2^SCALER to maintain precision
    localparam int SCALER = 12;
    localparam logic [127:0] MULT = (1 << (PHASE_WIDTH + SCALER)) / F_CLK_SYS; // to be descaled down by 2^SCALER
    logic [PHASE_WIDTH-1:0] phase_inc;
    logic [PHASE_WIDTH + 15 + SCALER:0] phase_inc_scaled;

    // frequency calibration and descaling logic
    always_ff@(posedge clk) begin
        if (rst) begin
            phase_inc_scaled <= '0;
            phase_inc <= '0;
        end else begin
            phase_inc_scaled <= freq_word * MULT;
            phase_inc <= phase_inc_scaled >> SCALER; 
        end
    end


    // Phase accumulator incrementation
    logic [PHASE_WIDTH-1:0] phase_acc;

    always_ff @(posedge clk) begin
        if (rst)
            phase_acc <= '0;
        else
            phase_acc <= phase_acc + phase_inc;
    end



    // Waveform computations
    localparam logic [AMP_WIDTH-1:0] MID = 1 << (AMP_WIDTH-1);
    localparam logic [AMP_WIDTH-1:0] MAX = {AMP_WIDTH{1'b1}};

    logic [AMP_WIDTH-1:0] ramp_val, tri_val, square_val, sine_val;


    // RAMP (sawtooth)
    assign ramp_val = phase_acc[PHASE_WIDTH-1 -: AMP_WIDTH];

    // SQUARE
    assign square_val = phase_acc[PHASE_WIDTH-1] ? MAX : '0;

    // TRIANGLE
    logic [PHASE_WIDTH-2:0] max_tri;
    logic [PHASE_WIDTH-2:0] tri_intermediate;

    assign max_tri = {PHASE_WIDTH{1'b1}};
    always_comb begin
        
        if (phase_acc[PHASE_WIDTH-1])
            tri_intermediate = ~phase_acc[PHASE_WIDTH-2:0]; // equivalent to {(PHASE_WIDTH -2){1'b1}} - phase_acc[PHASE_WIDTH-2:0]
        else
            tri_intermediate = phase_acc[PHASE_WIDTH-2:0];
        tri_val = tri_intermediate[PHASE_WIDTH-2 -: AMP_WIDTH-1];
        
    end

    

    // SINE (ROM-based lookup)  2 cycle latency
    sine_lut #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .LUT_ADDR_BITS(LUT_ADDR_BITS),
        .AMP_WIDTH (AMP_WIDTH),
        .RAM_PERFORMANCE ("HIGH_PERFORMANCE")
    ) lut_inst (
        .clk (clk),
        .phase_acc (phase_acc),
        .sine_out (sine_val)
    );



    // Output mux
    always_ff @(posedge clk) begin
        if (rst)
            wave_out <= MID;
        else begin
            unique case (wave_sel)
                3'd0: wave_out <= sine_val;
                3'd1: wave_out <= square_val;
                3'd2: wave_out <= tri_val << 1; // rescaling to the VDD-GND range
                3'd3: wave_out <= ramp_val;
                3'd4: wave_out <= dc_level;
                default: wave_out <= dc_level;
            endcase
        end
    end

endmodule

`default_nettype wire
