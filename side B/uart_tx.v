module uart_tx # (
    parameter CLK_FREQ = 50000000,   // System clock frequency (Hz)
    parameter BAUD     = 115200      // UART communication speed (bits per second)
)(
    input  wire       clk,           // Global clock driving all synchronous logic
    input  wire       rst_n,         // Active-low reset to initialize the module
    input  wire       start,         // Trigger signal to begin transmission
    input  wire [7:0] data_in,       // 8-bit parallel data to be transmitted

    output reg        tx,            // Serial output line (UART TX)
    output reg        busy           // Indicates transmission is in progress
);

    
    // UART TIMING CONFIGURATION

    // UART communication is time-based, but FPGA operates in clock cycles.
    // Therefore, the duration of one UART bit must be expressed in terms
    // of clock cycles
    localparam integer CLKS_PER_BIT = CLK_FREQ / BAUD;

    // INTERNAL REGISTERS
   
    reg [15:0] clk_count;   // Counts cycles for each bit
    reg [3:0]  bit_index;   // Tracks which bit is being sent (0–9)
    reg [9:0]  tx_shift;    // Holds full UART frame

    // Edge detection for start signal (prevents retriggering)
    reg start_d;
    always @(posedge clk) start_d <= start;
    

    wire start_pulse = start & ~start_d;

    // MAIN UART TRANSMISSION LOGIC
    
    // This block is synchronous to the rising edge of the clock.
    // All state updates occur on posedge clk.
    //
    // rst_n is asynchronous (active low), allowing immediate reset.
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset state: initialize all registers
            tx        <= 1'b1;  // UART idle state is HIGH
            busy      <= 1'b0;  // Not transmitting
            clk_count <= 0;
            bit_index <= 0;
            tx_shift  <= 10'b1111111111;
        end else begin

          
            // START TRANSMISSION
            // Transmission begins only if:
            // - A valid start pulse is detected
            // - The transmitter is not currently busy
    
            if (start_pulse && !busy) begin

                // UART frame construction:
                // Start bit  = 0
                // Data bits  = data_in[7:0] (LSB transmitted first)
                // Stop bit   = 1
                
                tx_shift  <= {1'b1, data_in, 1'b0};

                busy      <= 1'b1;  // mark transmitter as active
                clk_count <= 0;     // reset timing counter
                bit_index <= 0;     // start from first bit

                tx        <= 1'b0;  // transmit start bit immediately
            end
            
            // TRANSMISSION IN PROGRESS
            
            else if (busy) begin

                // Maintain current bit for CLKS_PER_BIT cycles
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;

                    // Move to next bit in frame
                    bit_index <= bit_index + 1;

                    // Output next bit from shift register
                    tx <= tx_shift[bit_index + 1];

                    // end of transmission 
                    if (bit_index == 9) begin
                        busy <= 1'b0;   // transmission finished
                        tx   <= 1'b1;   // return to idle state
                    end
                end
            end

            // IDLE STATE
            
            // When not transmitting, the UART line remains HIGH.
            // This is required by UART protocol.
        
            else begin
                tx <= 1'b1;
            end
        end
    end

endmodule

    
