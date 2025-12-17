`timescale 1ns/1ps
`default_nettype none

module top_level #(
    parameter int SCLK_DIV = 6,          // divider [#clock cycles(sets DAC update rate )
    parameter int PHASE_WIDTH = 24,
    parameter int LUT_ADDR_BITS = 10,
    parameter int FS_HZ = 1_041_100,    // update rate
    parameter int F_CLK_SYS = 100_000_000
)(
    input wire clk_100mhz,       // 100 MHz
    // simple controls (map to switches later)
    // input wire [15:0] freq_word,  // Hz
    // input wire [2:0]  wave_sel,
    // input wire [11:0] dc_level,
    input wire [15:0] sw,
    
    input wire btnC,

    output logic [15:0] led,

    // DAC pins (MCP4921)
    output wire dac_cs_n,
    output wire dac_sclk,
    output wire dac_copi,
    output wire dac_ldac
);

    // board connections
    logic rst;
    logic [15:0] freq_word;
    logic [2:0] wave_sel;
    logic [11:0] dc_level;
    
    always_comb begin
        rst = btnC;
        freq_word = {3'b0, sw[12:0]};
        wave_sel = sw[15:13];
        dc_level = sw[11:0];
    end

    assign led = sw;
    assign dac_ldac = 1'b0;

    // DDS sample generation
    logic [11:0] dds_sample;

    dds_core #(
        .PHASE_WIDTH (PHASE_WIDTH),
        .AMP_WIDTH (12),
        .LUT_ADDR_BITS (LUT_ADDR_BITS),
        .FS_HZ (FS_HZ),
        .F_CLK_SYS (F_CLK_SYS)
    ) u_dds (
        .clk (clk_100mhz),
        .rst (rst),
        .freq_word(freq_word),
        .wave_sel (wave_sel),
        .dc_level (dc_level),
        .wave_out (dds_sample)
    );


    // SPI DAC controller handshake
    logic dac_valid, dac_ready;
    logic [11:0] dac_code_reg;

    // when SPI is ready, latch the current DDS sample and assert valid for 1 clk.
    always_ff @(posedge clk_100mhz) begin
        if (rst) begin
            dac_valid <= 1'b0;
            dac_code_reg <= 12'd2048;
        end else begin
            dac_valid <= 1'b0; // default

            if (dac_ready) begin
                dac_code_reg <= dds_sample;
                dac_valid <= 1'b1;  // one-cycle pulse
            end
        end
    end

    // MCP4921 SPI controller
    spi_controller_dac4091 #(
        .SCLK_DIV (SCLK_DIV),
        .CFG_BUF (1),
        .CFG_GAIN1X (1),
        .CFG_ACTIVE (1)
    ) u_dac_spi (
        .clk (clk_100mhz),
        .rst (rst),
        .dac_code (dac_code_reg),
        .dac_valid (dac_valid),
        .dac_ready (dac_ready),
        .cs_n (dac_cs_n),
        .sclk (dac_sclk),
        .copi (dac_copi)
    );

endmodule

`default_nettype wire
