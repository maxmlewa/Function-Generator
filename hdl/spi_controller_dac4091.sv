`timescale 1ns/1ps
`default_nettype none

// MCP4921 (12-bit) SPI interface (SPI Mode 0)
// 16-bit MSB-first frame:
// [15] 0       (don't care for MCP4921 single-channel; keeping as 0)
// [14] BUF     (1=buffered Vref, 0=unbuffered)
// [13] GA      (1=1x, 0=2x)
// [12] SHDN    (1=active, 0=shutdown)
// [11:0] DATA  (12-bits)
//
// Data latched on SCLK rising edges
// COPI updated on SCLK falling edges
// CS_n low during entire 16-bit transfer; rising edge latches the code
//
// Input handshake:
//  dac_valid = 1 : request to send dac_code (12-bit) + config bits
// dac_ready = 1 : module is idle and can accept the request

module spi_controller_dac4091 #(
    parameter int SCLK_DIV = 10,    // sys_clk cycles per FULL SCLK period
    // CONFIG inputs
    parameter bit CFG_BUF = 1,     // [14]
    parameter bit CFG_GAIN1X = 1,  // [13] (1=1x, 0=2x)
    parameter bit CFG_ACTIVE = 1  // [12] (1=active, 0=shutdown)
)(
    input wire clk,
    input wire rst,

    // interface
    input wire [11:0] dac_code,
    input wire dac_valid,
    output logic dac_ready,

    // SPI pins to DAC
    output logic cs_n,
    output logic sclk,
    output logic copi
);

    localparam int DATA_WIDTH = 16;

    typedef enum logic [1:0] {
        IDLE,
        SHIFT,
        DONE
    } state_t;

    state_t state;

    localparam int HALF_DIV = (SCLK_DIV >> 1);
    localparam int FULL_DIV = (HALF_DIV << 1);

    // Counters and shift reg
    logic [$clog2(FULL_DIV):0] clk_count;
    logic [$clog2(DATA_WIDTH):0] bit_count;
    logic [DATA_WIDTH-1:0] shift_reg;

    // State machine
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cs_n <= 1'b1;
            sclk <= 1'b0;
            copi <= 1'b0;
            dac_ready <= 1'b1;

            shift_reg <= '0;
            bit_count <= '0;
            clk_count <= '0;
        end else begin
            case (state)

            // IDLE: Waiting for a valid request
            IDLE: begin
                cs_n <= 1'b1;
                sclk <= 1'b0;
                dac_ready <= 1'b1;
                clk_count <= '0;

                if (dac_valid) begin
                    // Prepare 16-bit frame
                    copi <= 1'b0;
                    shift_reg <= {1'b0, CFG_BUF, CFG_GAIN1X, CFG_ACTIVE, dac_code} << 1;

                    // MSB sent immediately, always 0
                    copi <= 1'b0;

                    bit_count <= 'd1;
                    clk_count <= '0;

                    dac_ready <= 1'b0;
                    cs_n <= 1'b0; // start transaction
                    state <= SHIFT;
                end
            end

            // SHIFT: Clock out remaining bits, MSB-first
            SHIFT: begin
                dac_ready <= 1'b0;
                clk_count <= clk_count + 1;

                // Rising edge
                if (clk_count == HALF_DIV-1) begin
                    sclk <= 1'b1;
                end

                // Falling edge: shift point, update COPI for next rising edge
                if (clk_count == FULL_DIV-1) begin
                    clk_count <= '0;
                    sclk      <= 1'b0;

                    if (bit_count == DATA_WIDTH) begin
                        state <= DONE;
                    end else begin
                        copi <= shift_reg[15];
                        shift_reg <= shift_reg << 1;
                        bit_count <= bit_count + 1;
                    end
                end
            end

            // DONE: deassert CS high to latch the new DAC value
            DONE: begin
                cs_n <= 1'b1;     // rising edge latches frame
                dac_ready <= 1'b1;
                sclk <= 1'b0;
                state <= IDLE;
            end

            default: begin
                state <= IDLE;
            end

            endcase
        end
    end

endmodule

`default_nettype wire
