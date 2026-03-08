// =============================================================================
// Module      : uart_top
// Description : Top-level wrapper connecting uart_tx and uart_rx.
//               Internally connects TX serial output to RX serial input,
//               forming a loopback path for self-test.
//               Instantiate this in your design or testbench top level.
// =============================================================================

module uart_top #(
    parameter CLKS_PER_BIT = 868   // 100 MHz / 115200 baud
)(
    input  wire       i_clk,
    input  wire       i_rst_n,

    // TX interface
    input  wire       i_tx_valid,
    input  wire [7:0] i_tx_byte,
    output wire       o_tx_serial,
    output wire       o_tx_done,
    output wire       o_tx_active,

    // RX interface (driven from external serial line)
    input  wire       i_rx_serial,
    output wire [7:0] o_rx_byte,
    output wire       o_rx_done,
    output wire       o_rx_active
);

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_tx_valid (i_tx_valid),
        .i_tx_byte  (i_tx_byte),
        .o_tx_serial(o_tx_serial),
        .o_tx_done  (o_tx_done),
        .o_tx_active(o_tx_active)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .i_clk      (i_clk),
        .i_rst_n    (i_rst_n),
        .i_rx_serial(i_rx_serial),
        .o_rx_byte  (o_rx_byte),
        .o_rx_done  (o_rx_done),
        .o_rx_active(o_rx_active)
    );

endmodule
