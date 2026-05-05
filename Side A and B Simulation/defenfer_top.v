// Thats the  top module for the defender side.
//
// it works in a sequence:
// 1. Wait for start signal
// 2. Encrypt a fixed plaintext using defender key
// 3. Send encrypted result to attacker through UART
// 4. Receive attacker key through UART
// 5. Verify if attacker key is correct
// 6. If correct → system goes to CRACKED state

module defender_top (
    input  wire        clk,        // clock: drives all operations step by step
    input  wire        rst_n,      // reset (active low): used to initialize everything
    input  wire        start,      // tells system to begin encryption
    input  wire        uart_rx,    // serial input from attacker

    output wire        uart_tx,    // serial output to attacker
    output wire [63:0] ciphertext, // encrypted output
    output wire        cracked     // becomes 1 when correct key is found
);

    // This is the defender’s original secret key.
  
    // It is fixed and does not change during operation.
    
    parameter [55:0] DEFENDER_KEY = 56'h00000000000333;

    
    // These are the different states of the system.
    // The FSM moves between these states based on conditions.
  
    localparam IDLE=0, ENC=1, LOCKED=2, VERIFY=3, CRACKED=4;
    reg [2:0] state;

    
    // These registers store values across clock cycles.
    // In hardware, this means actual flip-flops are used.\
    
    reg [63:0] ciphertext_reg;   // stores encrypted result
    reg [55:0] key56_reg;        // stores attacker key

    
    // UART receiver outputs data as parallel bytes.
    // rx_valid becomes 1 for one clock cycle when a byte is received.
    

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    // Since UART gives 8 bits at a time but key is 56 bits,
    // we collect 7 bytes and combine them into one key.
    
    reg [2:0] byte_cnt;

    
    // This always block runs on the rising edge of the clock.
    // "posedge clk" ensures all updates happen in sync with clock,
    // which is important for stable hardware behavior.
    // "negedge rst_n" allows immediate reset without waiting for clock.

    
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // When reset is active, clear everything
            key56_reg <= 0;
            byte_cnt  <= 0;
        end 
        else if (state == VERIFY) begin
            byte_cnt <= 0;
        end
        else if (rx_valid) begin
            // When a new byte arrives:
            // shift previous data and insert new byte at the end
            key56_reg <= {key56_reg[47:0], rx_data};
            byte_cnt  <= byte_cnt + 1;
        end
    end

    // Once 7 bytes are received, full 56-bit key is ready

    
    wire key_ready = (byte_cnt == 3'd7);


    
    // Encryption control signal
    reg enc_start;
    wire enc_done;
    wire [63:0] enc_out;


    
    // This block performs encryption using defender key.
    // It runs when enc_start is set to 1.
    des_datapath u_enc (
        .clk(clk),
        .rst_n(rst_n),
        .start(enc_start),
        .decrypt(1'b0),
        .plaintext(64'h4772616465204121),
        .key({DEFENDER_KEY[55:49], 1'b0, DEFENDER_KEY[48:42], 1'b0, DEFENDER_KEY[41:35], 1'b0, DEFENDER_KEY[34:28], 1'b0, DEFENDER_KEY[27:21], 1'b0, DEFENDER_KEY[20:14], 1'b0, DEFENDER_KEY[13:7], 1'b0, DEFENDER_KEY[6:0], 1'b0}),  // key expanded to 64 bits
        .ciphertext(enc_out),
        .done(enc_done)
    );


    
    // Verification control signal
    reg verify_start;
    wire verify_done;
    wire [63:0] verify_out;

    
    // This block uses the attacker key to re-encrypt the same plaintext.
    // If attacker guessed correct key, output will match.

    
    des_datapath u_verify (
        .clk(clk),
        .rst_n(rst_n),
        .start(verify_start),
        .decrypt(1'b0),
        .plaintext(64'h4772616465204121),
        .key({key56_reg[55:49], 1'b0, key56_reg[48:42], 1'b0, key56_reg[41:35], 1'b0, key56_reg[34:28], 1'b0, key56_reg[27:21], 1'b0, key56_reg[20:14], 1'b0, key56_reg[13:7], 1'b0, key56_reg[6:0], 1'b0}),
        .ciphertext(verify_out),
        .done(verify_done)
    );

    // Comparator checks if both ciphertexts are same
 
    
    wire match;

    comparator u_cmp (
        .a(ciphertext_reg),
        .b(verify_out),
        .match(match)
    );

    // Output connections
 
    assign ciphertext = ciphertext_reg;
    assign cracked    = (state == CRACKED);

    // --- UART TX Logic (Sending Ciphertext to Attacker) ---
    // FIX 2: Added tx_wait to handle uart busy latency
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
        end 
        else begin
            tx_start <= 0;

            if (sending) begin
                // Step 1: Fire the start pulse and lock the state
                if (!tx_busy && !tx_wait) begin
                    case (tx_idx)
                        0: tx_data <= ciphertext_reg[63:56];
                        1: tx_data <= ciphertext_reg[55:48];
                        2: tx_data <= ciphertext_reg[47:40];
                        3: tx_data <= ciphertext_reg[39:32];
                        4: tx_data <= ciphertext_reg[31:24];
                        5: tx_data <= ciphertext_reg[23:16];
                        6: tx_data <= ciphertext_reg[15:8];
                        7: tx_data <= ciphertext_reg[7:0];
                    endcase

                    tx_start <= 1;
                    tx_wait  <= 1; // Block further sends until UART goes busy
                end
                // Step 2: Wait for UART to assert busy, then unlock and prep next byte
                else if (tx_busy && tx_wait) begin
                    tx_wait <= 0; // Unlock for the next cycle
                    
                    if (tx_idx == 3'd7) begin // 8 bytes total
                        sending <= 0;
                        tx_idx  <= 0;
                    end else begin
                        tx_idx <= tx_idx + 1;
                    end
                end
            end
        end
    end

    // This is the main control logic (FSM)
    // It decides what the system should do at each stage
    
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            enc_start <= 0;
            verify_start <= 0;
        end 
        else begin
            enc_start    <= 0;
            verify_start <= 0;

            case (state)

                // waiting for user to start system
                IDLE:
                    if (start) begin
                        enc_start <= 1;
                        state <= ENC;
                    end

                // encryption is happening
                ENC:
                    if (enc_done) begin
                        ciphertext_reg <= enc_out;
                        sending <= 1; // send ciphertext
                        state <= LOCKED;
                    end

                // waiting for attacker key
                LOCKED:
                    if (key_ready) begin
                        verify_start <= 1;
                        state <= VERIFY;
                    end

                // verifying attacker key
                VERIFY:
                    if (verify_done)
                        state <= match ? CRACKED : LOCKED;

                // correct key found
                CRACKED:
                    state <= CRACKED;

            endcase
        end
    end

endmodule
