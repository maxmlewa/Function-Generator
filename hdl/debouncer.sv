`timescale 1ps/
`default_nettype 

// debouncer module: might come in handy when using buttons for user inputs [not used in the project]

module debouncer #(
    parameter CLK_FREQ = 100_000_000,    // Clock frequency in Hz
    parameter DEBOUNCE_TIME_MS = 20,     // Debounce time in milliseconds
    parameter DATA_WIDTH = 16
)(
    input wire clk,     // System clock
    input wire rst,     // Active low reset
    input wire [DATA_WIDTH-1:0] data_in,     // Raw input 
    output reg [DATA_WIDTH-1:0] data_out     // Debounced output
);

    localparam COUNTER_MAX = (CLK_FREQ / 1000) * DEBOUNCE_TIME_MS;
    localparam COUNTER_WIDTH = $clog2(COUNTER_MAX + 1);


    logic [COUNTER_WIDTH-1:0] counter;
    logic [DATA_WIDTH-1:0] data_sync_0, data_sync_1;

    // synchronizer
    always @(posedge clk) begin
        if (rst) begin
            data_sync_0 <= '0;
            data_sync_1 <= '0;
        end else begin
            data_sync_0 <= data_in;
            data_sync_1 <= data_sync_0;
        end
    end

    // Debounce logic: count on mismatch and reset counter on match
    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            data_out <= '0;
        end else begin
            if (data_sync_1 != data_out) begin
                counter <= counter + 1;
                if (counter >= COUNTER_MAX) begin
                    button_out <= button_sync_1;
                    counter <= 0;
                end

            end else begin
                counter <= 0;
            end
        end
    end

endmodule // debouncer module

`default_nettype wire
