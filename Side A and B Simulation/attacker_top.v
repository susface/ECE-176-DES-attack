// Top module for the attacker side.
// Authored by Jordan David Reynolds
// 
// Sequence:
// 1. Wait to receive 8 bytes of ciphertext from the defender via UART
// 2. Start the sideBFSM brute-force engine
// 3. Wait for the 'match' signal from sideBFSM
// 4. Send the 7-byte (56-bit) cracked key back to the defender via UART

module attacker_top (
    input  wire        clk,        // 50MHz clock typical for DE2-115
    input  wire        rst_n,      // Active low reset
    input  wire        uart_rx,    // Serial input from defender

    output wire        uart_tx,    // Serial output to defender
    output wire        match_led   
);

    // Hardcoded plaintext to match defender ("Grade A!")
    localparam [63:0] KNOWN_PLAINTEXT = 64'h4772616465204121;

    // FSM States
    localparam RCV_CIPHER = 3'd0, 
               CRACKING   = 3'd1, 
               SEND_KEY   = 3'd2, 
               DONE       = 3'd3;

    reg [2:0] state;

    // --- UART RX Logic (Receiving Ciphertext) ---
    wire [7:0] rx_data;
    wire       rx_valid;
    reg [63:0] rcvd_ciphertext;
    reg [3:0]  rx_byte_cnt;

    uart_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    // Shift in the 8 bytes of ciphertext sent by the defender
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rcvd_ciphertext <= 64'd0;
            rx_byte_cnt     <= 4'd0;
        end else if (state == RCV_CIPHER && rx_valid) begin
            rcvd_ciphertext <= {rcvd_ciphertext[55:0], rx_data};
            rx_byte_cnt     <= rx_byte_cnt + 1;
        end
    end

    wire cipher_ready = (rx_byte_cnt == 4'd8);

    // --- Brute Force FSM Instantiation ---
    reg         bfsm_start;
    wire        bfsm_match;
    wire [63:0] bfsm_key_out;

    sideBFSM u_bfsm (
        .clk(clk),
        .reset_n(rst_n),
        .start(bfsm_start),
        .receivedPlaintext(KNOWN_PLAINTEXT),
        .receivedCiphertext(rcvd_ciphertext),
        .match(bfsm_match),
        .key(bfsm_key_out)
    );

    assign match_led = bfsm_match;

    wire [55:0] cracked_key_56 = {
        bfsm_key_out[63:57], bfsm_key_out[55:49], 
        bfsm_key_out[47:41], bfsm_key_out[39:33], 
        bfsm_key_out[31:25], bfsm_key_out[23:17], 
        bfsm_key_out[15:9], bfsm_key_out[7:1]
    };

    // UART TX Logic (Sending Cracked Key)
    reg [2:0] tx_idx;
    reg       tx_start;
    reg [7:0] tx_data;
    reg       sending;
    reg       tx_wait;
    wire      tx_busy;

    uart_tx u_tx (
        .clk(clk),
        .rst_n(rst_n),
        .start(tx_start),
        .data_in(tx_data),
        .tx(uart_tx),
        .busy(tx_busy)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sending  <= 0;
            tx_idx   <= 0;
            tx_start <= 0;
            tx_wait  <= 0;
        end else begin
            tx_start <= 0; // default state
            if (state == CRACKING && bfsm_match) begin
					sending <= 1;
				end
            if (sending) begin
                // Step 1: Fire the start pulse and lock the state
                if (!tx_busy && !tx_wait) begin
                    case (tx_idx)
                        0: tx_data <= cracked_key_56[55:48];
                        1: tx_data <= cracked_key_56[47:40];
                        2: tx_data <= cracked_key_56[39:32];
                        3: tx_data <= cracked_key_56[31:24];
                        4: tx_data <= cracked_key_56[23:16];
                        5: tx_data <= cracked_key_56[15:8];
                        6: tx_data <= cracked_key_56[7:0];
                        default: tx_data <= 8'h00;
                    endcase

                    tx_start <= 1;
                    tx_wait  <= 1; // Block further sends until UART goes busy
                end
                else if (tx_busy && tx_wait) begin
                    tx_wait <= 0; // Unlock for the next cycle
                    
                    if (tx_idx == 3'd6) begin // 7 bytes total
                        sending <= 0;
                        tx_idx  <= 0;
                    end else begin
                        tx_idx <= tx_idx + 1;
                    end
                end
            end
        end
    end

    // --- Main Control FSM ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= RCV_CIPHER;
            bfsm_start <= 0;
        end else begin
            bfsm_start <= 0; // default

            case (state)
                RCV_CIPHER: begin
                    if (cipher_ready) begin
                        $display("Starting crack");
                        bfsm_start <= 1; // Pulse start for sideBFSM
                        state      <= CRACKING;
                    end
                end

                CRACKING: begin
                    if (bfsm_match) begin
                        state   <= SEND_KEY;
                    end
                end

                SEND_KEY: begin
                    if (!sending && !tx_busy) begin
                        state <= DONE; // Finished sending all 7 bytes
                    end
                end

                DONE: begin
                    state <= DONE; // Park here
                end
                
                default: state <= RCV_CIPHER;
            endcase
        end
    end

endmodule
