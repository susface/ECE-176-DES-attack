// ============================================================
// defender_top.v
// ------------------------------------------------------------
// This is the main module for the defender side.
// Think of this as the "brain + wiring" of the system.
//
// It connects:
//   - DES encryption block
//   - verification block
//   - UART (to receive attacker key)
//   - comparator (to check correctness)
//
// The FSM inside controls what happens step-by-step.
//
// Some parts were originally written by me,
// and some parts were cleaned up and optimized
// to follow proper RTL design style (less wires, more registers).
// ============================================================

module defender_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        uart_rx,

    output wire        uart_tx,
    output wire [63:0] ciphertext,
    output wire        cracked
);

    // ============================================================
    // STATES
    // ------------------------------------------------------------
    // These states basically describe what the system is doing:
    //
    // IDLE   -> waiting for start
    // ENC    -> encrypting plaintext
    // LOCKED -> ciphertext ready, waiting for attacker key
    // VERIFY -> checking if key is correct
    // CRACKED-> correct key found
    //
    // Keeping this simple makes debugging and explanation easier.
    // ============================================================

    localparam IDLE=0, ENC=1, LOCKED=2, VERIFY=3, CRACKED=4;
    reg [2:0] state;

    // ============================================================
    // REGISTERS (ACTUAL HARDWARE STORAGE)
    // ------------------------------------------------------------
    // Instead of using too many wires, we store values here.
    // This helps reduce long combinational paths and makes
    // the design more realistic for FPGA implementation.
    // ============================================================

    reg [63:0] ciphertext_reg;   // holds encrypted result
    reg [55:0] key56_reg;        // holds attacker key (56-bit)

    // ============================================================
    // UART RECEIVER
    // ------------------------------------------------------------
    // This block receives data from attacker side.
    // Each time a byte comes in, rx_valid goes HIGH.
    // ============================================================

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx u_rx (
        .clk(clk),
        .rst_n(rst_n),
        .rx(uart_rx),
        .data_out(rx_data),
        .data_valid(rx_valid)
    );

    // ============================================================
    // BUILDING THE 56-BIT KEY (BYTE BY BYTE)
    // ------------------------------------------------------------
    // UART sends data in 8-bit chunks, but DES uses 56-bit key.
    //
    // So we:
    //   - shift old data
    //   - add new byte at the end
    //
    // This is basically acting like a shift register.
    // ============================================================

    reg [2:0] byte_cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            key56_reg <= 0;
            byte_cnt  <= 0;
        end 
        else if (rx_valid) begin
            key56_reg <= {key56_reg[47:0], rx_data}; // shift + insert
            byte_cnt  <= byte_cnt + 1;
        end
    end

    // once 7 bytes are received → key is ready
    wire key_ready = (byte_cnt == 3'd7);

    // ============================================================
    // DES ENCRYPTION BLOCK
    // ------------------------------------------------------------
    // This encrypts a fixed plaintext using the defender key.
    //
    // Note:
    // Instead of complex key expansion, we simply pad 8 bits.
    // Keeps things simple and avoids extra logic in top module.
    // ============================================================

    reg enc_start;
    wire enc_done;
    wire [63:0] enc_out;

    des_datapath u_enc (
        .clk(clk),
        .rst_n(rst_n),
        .start(enc_start),
        .decrypt(1'b0),
        .plaintext(64'h4772616465204121),
        .key({key56_reg, 8'h00}), // simplified expansion
        .ciphertext(enc_out),
        .done(enc_done)
    );

    // ============================================================
    // DES VERIFICATION BLOCK
    // ------------------------------------------------------------
    // This takes the attacker key and re-encrypts the same plaintext.
    //
    // If both ciphertexts match → correct key found.
    // ============================================================

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

    // ============================================================
    // COMPARATOR
    // ------------------------------------------------------------
    // Just checks if both ciphertexts are equal.
    // ============================================================

    wire match;

    comparator u_cmp (
        .a(ciphertext_reg),
        .b(verify_out),
        .match(match)
    );

    // outputs
    assign ciphertext = ciphertext_reg;
    assign cracked    = (state == CRACKED);

    // ============================================================
    // FSM (MAIN CONTROL LOGIC)
    // ------------------------------------------------------------
    // This is where the "brain" is.
    //
    // It decides:
    //   when to start encryption
    //   when to wait
    //   when to verify
    //   when system is done
    //
    // Everything else just follows this sequence.
    // ============================================================

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            enc_start <= 0;
            verify_start <= 0;
        end else begin
            enc_start    <= 0;
            verify_start <= 0;

            case (state)

                // waiting for user to press start
                IDLE:
                    if (start) begin
                        enc_start <= 1;
                        state <= ENC;
                    end

                // encryption happening here
                ENC:
                    if (enc_done) begin
                        ciphertext_reg <= enc_out; // store result
                        state <= LOCKED;
                    end

                // waiting for attacker key input
                LOCKED:
                    if (key_ready) begin
                        verify_start <= 1;
                        state <= VERIFY;
                    end

                // checking if key is correct
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
