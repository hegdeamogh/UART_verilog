// =============================================================================
// Testbench   : tb_uart_loopback
// Description : Cycle-accurate self-checking testbench for UART TX + RX.
//               - Connects TX serial output directly to RX serial input
//               - Sends a sequence of test bytes
//               - Automatically checks each received byte against sent byte
//               - Reports PASS/FAIL per transaction and overall result
//
// Simulation  : ModelSim / Questa / Icarus Verilog / Xilinx Vivado Simulator
//   iverilog -o sim tb/tb_uart_loopback.v rtl/uart_tx.v rtl/uart_rx.v && vvp sim
// =============================================================================

`timescale 1ns / 1ps

module tb_uart_loopback;

    // ------------------------------------------------------------------
    // Parameters - must match DUT
    // ------------------------------------------------------------------
    localparam CLK_FREQ      = 100_000_000; // 100 MHz
    localparam BAUD_RATE     = 115_200;
    localparam CLKS_PER_BIT  = CLK_FREQ / BAUD_RATE; // 868
    localparam CLK_PERIOD_NS = 10;                    // 10 ns -> 100 MHz
    localparam BIT_PERIOD_NS = CLK_PERIOD_NS * CLKS_PER_BIT;

    // ------------------------------------------------------------------
    // DUT signals
    // ------------------------------------------------------------------
    reg        clk      = 0;
    reg        rst_n    = 0;
    reg        tx_valid = 0;
    reg  [7:0] tx_byte  = 0;
    wire       tx_serial;
    wire       tx_done;
    wire       tx_active;
    wire [7:0] rx_byte;
    wire       rx_done;
    wire       rx_active;

    // ------------------------------------------------------------------
    // DUT instantiation (loopback: tx_serial -> i_rx_serial)
    // ------------------------------------------------------------------
    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_tx (
        .i_clk      (clk),
        .i_rst_n    (rst_n),
        .i_tx_valid (tx_valid),
        .i_tx_byte  (tx_byte),
        .o_tx_serial(tx_serial),
        .o_tx_done  (tx_done),
        .o_tx_active(tx_active)
    );

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_rx (
        .i_clk      (clk),
        .i_rst_n    (rst_n),
        .i_rx_serial(tx_serial),  // loopback
        .o_rx_byte  (rx_byte),
        .o_rx_done  (rx_done),
        .o_rx_active(rx_active)
    );

    // ------------------------------------------------------------------
    // Clock generation
    // ------------------------------------------------------------------
    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    // ------------------------------------------------------------------
    // Test vectors
    // ------------------------------------------------------------------
    reg [7:0] test_bytes [0:7];
    integer   pass_count = 0;
    integer   fail_count = 0;
    integer   i;

    initial begin
        test_bytes[0] = 8'h55; // alternating bits
        test_bytes[1] = 8'hAA; // alternating bits (inverted)
        test_bytes[2] = 8'hFF; // all ones
        test_bytes[3] = 8'h00; // all zeros
        test_bytes[4] = 8'h41; // ASCII 'A'
        test_bytes[5] = 8'h5A; // ASCII 'Z'
        test_bytes[6] = 8'h0F; // nibble boundary
        test_bytes[7] = 8'hA3; // random pattern
    end

    // ------------------------------------------------------------------
    // Waveform dump (for GTKWave)
    // ------------------------------------------------------------------
    initial begin
        $dumpfile("uart_loopback.vcd");
        $dumpvars(0, tb_uart_loopback);
    end

    // ------------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------------
    task send_byte;
        input [7:0] data;
        begin
            @(posedge clk);
            tx_byte  <= data;
            tx_valid <= 1'b1;
            @(posedge clk);
            tx_valid <= 1'b0;

            // Wait for TX to complete
            @(posedge tx_done);
            @(posedge clk);
        end
    endtask

    task check_rx;
        input [7:0] expected;
        begin
            // Wait for RX done pulse
            @(posedge rx_done);
            @(posedge clk);

            if (rx_byte === expected) begin
                $display("[PASS] Sent: 0x%02X | Received: 0x%02X", expected, rx_byte);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Sent: 0x%02X | Received: 0x%02X  <-- MISMATCH", expected, rx_byte);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("  UART 8-N-1 Loopback Testbench");
        $display("  CLK: %0d MHz | Baud: %0d | CLKS_PER_BIT: %0d",
                 CLK_FREQ/1_000_000, BAUD_RATE, CLKS_PER_BIT);
        $display("========================================");

        // Reset
        rst_n = 0;
        repeat(5) @(posedge clk);
        rst_n = 1;
        repeat(2) @(posedge clk);

        // Send all test vectors
        for (i = 0; i < 8; i = i + 1) begin
            fork
                send_byte(test_bytes[i]);
                check_rx(test_bytes[i]);
            join
            // Inter-frame gap
            repeat(10) @(posedge clk);
        end

        // Summary
        $display("========================================");
        $display("  Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED - review waveform");
        $display("========================================");

        $finish;
    end

    // ------------------------------------------------------------------
    // Timeout watchdog
    // ------------------------------------------------------------------
    initial begin
        #(BIT_PERIOD_NS * 15 * 8 * 10); // 10 full frames timeout
        $display("[TIMEOUT] Simulation exceeded expected duration.");
        $finish;
    end

endmodule
