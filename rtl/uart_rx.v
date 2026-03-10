
module uart_rx #(
    parameter CLKS_PER_BIT = 868
)(
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_rx_serial,
    output reg  [7:0] o_rx_byte,
    output reg        o_rx_done,
    output reg        o_rx_active
);

    // FSM state encoding
    localparam IDLE      = 3'd0;
    localparam START_BIT = 3'd1;
    localparam DATA_BITS = 3'd2;
    localparam STOP_BIT  = 3'd3;
    localparam CLEANUP   = 3'd4;

    // Sample at mid-bit point
    localparam HALF_BIT = CLKS_PER_BIT / 2;

    reg [2:0]                       r_state;
    reg [$clog2(CLKS_PER_BIT)-1:0] r_clk_count;
    reg [2:0]                       r_bit_index;

    // Double-flop synchroniser for metastability
    reg r_rx_d1, r_rx_d2;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_rx_d1 <= 1'b1;
            r_rx_d2 <= 1'b1;
        end else begin
            r_rx_d1 <= i_rx_serial;
            r_rx_d2 <= r_rx_d1;
        end
    end

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_state     <= IDLE;
            o_rx_byte   <= 8'h00;
            o_rx_done   <= 1'b0;
            o_rx_active <= 1'b0;
            r_clk_count <= 0;
            r_bit_index <= 0;
        end else begin
            o_rx_done <= 1'b0;

            case (r_state)

                IDLE: begin
                    o_rx_active <= 1'b0;
                    r_clk_count <= 0;
                    r_bit_index <= 0;

                    // Falling edge = start bit detected
                    if (r_rx_d2 == 1'b0)
                        r_state <= START_BIT;
                end

                // Verify start bit is still low at mid-point
                START_BIT: begin
                    if (r_clk_count == HALF_BIT - 1) begin
                        if (r_rx_d2 == 1'b0) begin
                            r_clk_count <= 0;
                            r_state     <= DATA_BITS;
                            o_rx_active <= 1'b1;
                        end else begin
                            r_state <= IDLE; // false start
                        end
                    end else begin
                        r_clk_count <= r_clk_count + 1;
                    end
                end

                // Sample each data bit at its center
                DATA_BITS: begin
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count                <= 0;
                        o_rx_byte[r_bit_index]     <= r_rx_d2; // LSB first
                        if (r_bit_index < 7) begin
                            r_bit_index <= r_bit_index + 1;
                        end else begin
                            r_bit_index <= 0;
                            r_state     <= STOP_BIT;
                        end
                    end
                end

                // Validate stop bit (line must be HIGH)
                STOP_BIT: begin
                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 0;
                        o_rx_done   <= 1'b1; // frame valid
                        r_state     <= CLEANUP;
                    end
                end

                CLEANUP: begin
                    o_rx_active <= 1'b0;
                    r_state     <= IDLE;
                end

                default: r_state <= IDLE;

            endcase
        end
    end

endmodule
