// uart_rx.v
// UART Receiver (8N1 format)
// Receives 1 byte (8 bits) serially and converts it to parallel data

module uart_rx #(
    parameter CLK_FREQ = 50000000,   // System clock (50 MHz)
    parameter BAUD     = 115200      // UART communication speed
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx,            // Serial input line

    output reg  [7:0] data_out,      // Received byte (parallel output)
    output reg        data_valid     // High for 1 cycle when byte is ready
);

    // Convert UART timing into clock cycles
    // Each bit must stay stable for this many clock cycles
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;

    // FSM states for receiving a byte
    localparam IDLE  = 0,   // waiting for start bit
               START = 1,   // validating start bit
               DATA  = 2,   // receiving 8 data bits
               STOP  = 3;   // checking stop bit

    reg [1:0]  state;
    reg [15:0] clk_count;   // counts clock cycles for each bit
    reg [2:0]  bit_index;   // tracks which bit is being received (0–7)
    reg [7:0]  rx_shift;    // stores incoming bits

   
    // Synchronize RX input
    // RX is asynchronous, so it must be stabilized before use
    
    reg rx_d1, rx_d2;
    always @(posedge clk) begin
        rx_d1 <= rx;
        rx_d2 <= rx_d1;
    end

    wire rx_clean = rx_d2;  // stable version of RX

    // Main UART receiver logic
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers
            state      <= IDLE;
            clk_count  <= 0;
            bit_index  <= 0;
            rx_shift   <= 0;
            data_out   <= 0;
            data_valid <= 0;
        end else begin

            data_valid <= 0; // default (only high when byte is ready)

            case (state)

                // Wait until RX goes LOW (start bit)
                IDLE: begin
                    if (rx_clean == 0) begin
                        state     <= START;
                        clk_count <= 0;
                    end
                end

                // Check middle of start bit to confirm valid start
                START: begin
                    if (clk_count == (CLKS_PER_BIT >> 1)) begin
                        if (rx_clean == 0) begin
                            state     <= DATA;
                            clk_count <= 0;
                            bit_index <= 0;
                        end else begin
                            state <= IDLE; // false start detected
                        end
                    end else begin
                        clk_count <= clk_count + 1;
                    end
                end

                // Receive 8 data bits (LSB first)
                DATA: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        clk_count <= 0;

                        // store received bit
                        rx_shift[bit_index] <= rx_clean;
                        bit_index <= bit_index + 1;

                        // after 8 bits, move to stop bit
                        if (bit_index == 7)
                            state <= STOP;
                    end
                end

                // Check stop bit and finalize data
                STOP: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1;
                    end else begin
                        data_out   <= rx_shift; // output full byte
                        data_valid <= 1;        // signal data is ready
                        state      <= IDLE;
                        clk_count  <= 0;
                    end
                end

            endcase
        end
    end

endmodule
