
module uart_tx #(
    parameter CLKS_PER_BIT = 868
)(
    input  wire       i_clk,
    input  wire       i_rst_n,
    input  wire       i_tx_valid,
    input  wire [7:0] i_tx_byte,
    output reg        o_tx_serial,
    output reg        o_tx_done,
    output reg        o_tx_active
);

    // FSM state encoding
    localparam IDLE      = 3'd0;
    localparam START_BIT = 3'd1;
    localparam DATA_BITS = 3'd2;
    localparam STOP_BIT  = 3'd3;
    localparam CLEANUP   = 3'd4;

    reg [2:0]                        r_state;
    reg [$clog2(CLKS_PER_BIT)-1:0]  r_clk_count;
    reg [2:0]                        r_bit_index;
    reg [7:0]                        r_tx_data;

    always @(posedge i_clk) begin
        if (!i_rst_n) begin
            r_state     <= IDLE;
            o_tx_serial <= 1'b1;   // idle line high
            o_tx_done   <= 1'b0;
            o_tx_active <= 1'b0;
            r_clk_count <= 0;
            r_bit_index <= 0;
            r_tx_data   <= 8'h00;
        end else begin
            o_tx_done <= 1'b0; // default: not done

            case (r_state)

                IDLE: begin
                    o_tx_serial <= 1'b1;
                    o_tx_active <= 1'b0;
                    r_clk_count <= 0;
                    r_bit_index <= 0;

                    if (i_tx_valid) begin
                        r_tx_data <= i_tx_byte;
                        r_state   <= START_BIT;
                    end
                end

                START_BIT: begin
                    o_tx_serial <= 1'b0;   // pull line low
                    o_tx_active <= 1'b1;

                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 0;
                        r_state     <= DATA_BITS;
                    end
                end

                DATA_BITS: begin
                    o_tx_serial <= r_tx_data[r_bit_index]; // LSB first

                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 0;
                        if (r_bit_index < 7) begin
                            r_bit_index <= r_bit_index + 1;
                        end else begin
                            r_bit_index <= 0;
                            r_state     <= STOP_BIT;
                        end
                    end
                end

                STOP_BIT: begin
                    o_tx_serial <= 1'b1;   // stop bit: line high

                    if (r_clk_count < CLKS_PER_BIT - 1) begin
                        r_clk_count <= r_clk_count + 1;
                    end else begin
                        r_clk_count <= 0;
                        o_tx_done   <= 1'b1;
                        r_state     <= CLEANUP;
                    end
                end

                CLEANUP: begin
                    o_tx_active <= 1'b0;
                    r_state     <= IDLE;
                end

                default: r_state <= IDLE;

            endcase
        end
    end

endmodule
