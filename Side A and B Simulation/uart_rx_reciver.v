// uart_rx.v
// UART Receiver (8N1 format)
// Receives 1 byte at a time from serial RX line

module uart_rx #(
    parameter CLK_FREQ = 50000000,   // FPGA clock (50 MHz)
    parameter BAUD     = 115200      // Baud rate
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,            // Serial input line

    output reg  [7:0] data_out,      // Received byte
    output reg        data_valid     // High for 1 cycle when byte is ready
);

    // Number of clock cycles per UART bit
    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    // FSM states
    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0]  state;
    reg [15:0] clk_count;
    reg [2:0]  bit_index;
    reg [7:0]  rx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            clk_count  <= 0;
            bit_index  <= 0;
            rx_shift   <= 0;
            data_out   <= 0;
            data_valid <= 0;
        end else begin
            // Default: no new data
            data_valid <= 0;

            case (state)

                // Wait for start bit (line goes LOW)
                IDLE: begin
                    if (rx == 0) begin
                        state     <= START;
                        clk_count <= 0;
                    end
                end

                // Align to middle of start bit
                START: begin
                    if (clk_count == (CLKS_PER_BIT/2)) begin
                        // Confirm valid start bit
                        if (rx == 0) begin
                            clk_count <= 0;
                            bit_index <= 0;
                            state     <= DATA;
                        end else begin
                            // False start, go back to idle
                            state <= IDLE;
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                // Read 8 data bits (LSB first)
                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;

                        // Store received bit
                        rx_shift[bit_index] <= rx;
                        bit_index <= bit_index + 1;

                        // After 8 bits, go to stop bit
                        if (bit_index == 7) begin
                            state <= STOP;
                        end
                    end
                end

                // Read stop bit and finish reception
                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        // Output received byte
                        data_out   <= rx_shift;
                        data_valid <= 1;

                        // Return to idle for next byte
                        state      <= IDLE;
                        clk_count  <= 0;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
