
// defender_top.v

// Top-level module for the defender system.
//
// This module coordinates encryption, communication, and
// verification. It connects all submodules and controls
// the order of operations using a finite state machine (FSM).

// System operation:
// 1. Encrypt plaintext using a key
// 2. Send ciphertext to external side (attacker)
// 3. Receive candidate key from UART
// 4. Verify if received key is correct


module defender_top (
    input  wire        clk,        // system clock
    input  wire        rst_n,      // active-low reset
    input  wire        start,      // starts encryption process
    input  wire        uart_rx,    // serial input (attacker side)

    output wire        uart_tx,    // serial output (to attacker)
    output wire [63:0] ciphertext, // encrypted data output
    output wire        cracked     // high when correct key is found
);

    
    // FSM STATES
    
    // These states define the sequence of operation of the system.
    

    localparam IDLE=0, ENC=1, LOCKED=2, VERIFY=3, CRACKED=4;
    reg [2:0] state;

    
    // REGISTERS
    
    // Registers store values across clock cycles.
    // Data is updated only on clock edges to ensure stable behavior.
    

    reg [63:0] ciphertext_reg;   // stores encrypted result
    reg [55:0] key56_reg;        // stores received 56-bit key

    
    // UART RECEIVER
    
    // Converts serial data (uart_rx) into parallel bytes.
    // 'data_valid' is asserted for one clock cycle when a byte arrives.
    

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );


    // KEY ASSEMBLY (56-bit)

    // UART provides 8-bit data, but DES requires a 56-bit key.
    // Bytes are shifted into a register to build the full key.
    
    // The always block uses:
    //   posedge clk → ensures synchronous operation
    //   negedge rst_n → allows asynchronous reset
    
    // This guarantees predictable hardware timing.
    

    reg [2:0] byte_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key56_reg <= 0;
            byte_cnt  <= 0;
        end else if (rx_valid) begin
            key56_reg <= {key56_reg[47:0], rx_data}; // shift left and insert new byte
            byte_cnt  <= byte_cnt + 1;
        end
    end

    // Indicates that full 56-bit key has been received
    wire key_ready = (byte_cnt == 3'd7);

    // DES ENCRYPTION BLOCK
 
    // Encrypts a fixed plaintext using the provided key.
    
    // The 'start' signal triggers encryption.
    // The 'done' signal indicates completion.
    
    // Key is expanded from 56 bits to 64 bits by padding.
    

    reg enc_start;
    wire enc_done;
    wire [63:0] enc_out;

    des_datapath u_enc (
        .clk(clk),
        .rst_n(rst_n),
        .start(enc_start),
        .decrypt(1'b0),
        .plaintext(64'h4772616465204121),
        .key({key56_reg, 8'h00}),
        .ciphertext(enc_out),
        .done(enc_done)
    );

  
    // DES VERIFICATION BLOCK
    
    // Uses received key to perform encryption again.
    // Output is compared with stored ciphertext.


    reg verify_start;
    wire verify_done;
    wire [63:0] verify_out;

    des_datapath u_verify (
        .clk(clk),
        .rst_n(rst_n),
        .start(verify_start),
        .decrypt(1'b0),
        .plaintext(64'h4772616465204121),
        .key({key56_reg, 8'h00}),
        .ciphertext(verify_out),
        .done(verify_done)
    );

    // COMPARATOR
  
    // Compares stored ciphertext with verification result.
    // If equal, the key is correct.
    

    wire match;

    comparator u_cmp (
        .a(ciphertext_reg),
        .b(verify_out),
        .match(match)
    );

    assign ciphertext = ciphertext_reg;
    assign cracked    = (state == CRACKED);


    // UART TRANSMITTER
    
    // Sends 64-bit ciphertext as 8 sequential bytes.
    
    // Transmission occurs only when UART is not busy.
   

    reg [2:0] tx_idx;
    reg       tx_start;
    reg [7:0] tx_data;
    reg       sending;
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
        end else begin
            tx_start <= 0;

            if (sending && !tx_busy) begin
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

                if (tx_idx == 3'd7) begin
                    sending <= 0;
                    tx_idx  <= 0;
                end else begin
                    tx_idx <= tx_idx + 1;
                end
            end
        end
    end

    // FSM CONTROL LOGIC
    // This always block controls the sequence of operations.
    
    // posedge clk:
    //   ensures all state transitions occur synchronously
    
    // negedge rst_n:
    //   allows immediate reset of system regardless of clock


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            enc_start <= 0;
            verify_start <= 0;
        end else begin
            enc_start    <= 0;
            verify_start <= 0;

            case (state)

                // wait for start signal
                IDLE:
                    if (start) begin
                        enc_start <= 1;
                        state <= ENC;
                    end

                // encryption in progress
                ENC:
                    if (enc_done) begin
                        ciphertext_reg <= enc_out;
                        sending <= 1;      // begin UART transmission
                        state <= LOCKED;
                    end

                // waiting for external key input
                LOCKED:
                    if (key_ready) begin
                        verify_start <= 1;
                        state <= VERIFY;
                    end

                // verification process
                VERIFY:
                    if (verify_done)
                        state <= match ? CRACKED : LOCKED;

                // correct key detected
                CRACKED:
                    state <= CRACKED;

            endcase
        end
    end

endmodule
