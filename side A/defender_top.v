// defender_top.v — Side A (Defender) Top-Level Integration
// Target board : DE2-115 (Cyclone IV E)
// Clock        : CLOCK_50 (50 MHz)
// Reset        : rst_n active-low asynchronous
//
// Inter-board UART bus (115200 8N1):
//   TX (uart_tx)  : Side A → Side B, sends ciphertext[63:0] as 8 bytes MSB-first
//   RX (uart_rx)  : Side B → Side A, receives found_key[55:0] as 7 bytes MSB-first
//
// uart_rx_in passes through a 2-FF synchronizer before reaching the UART RX
// module, providing metastability protection for the cross-board signal.
//
// Found-key deserializer:
//   Receives 7 consecutive UART bytes and assembles them into found_key_int.
//   Pulses key_found_int for exactly one clock cycle when all 7 bytes arrive.
//   The FSM then moves to S_VFY_PLS on the following cycle.
//
// Key verification:
//   Side B may send false positives (≈256 per 2^56 search).
//   u_verify re-encrypts PLAINTEXT_FIXED with the candidate key and compares
//   against ciphertext_reg.  On mismatch the FSM returns to S_LOCKED and
//   waits for the next candidate.

module defender_top #(
    parameter [63:0] PLAINTEXT_FIXED = 64'h4772616465204121, // "Grade A!"
    parameter [55:0] DEFENDER_KEY56  = 56'hFFFFFFFFFFFFFF,
    parameter integer CLK_FREQ       = 50000000,
    parameter integer BAUD           = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    // ── UART RX from Side B (found_key, 7 bytes, MSB-first) ──────────────────
    input  wire        uart_rx_in,

    // ── UART TX to Side B (ciphertext, 8 bytes, MSB-first) ───────────────────
    output wire        tx,
    output wire        uart_busy,

    // ── Raw outputs (useful for debug / future GPIO layer) ────────────────────
    output wire [63:0] ciphertext,
    output wire        ciphertext_valid,
    output wire        cracked,

    // ── Display outputs ───────────────────────────────────────────────────────
    output reg  [1:0]  disp_state,   // → display_ctrl_a.v (7-seg)

    // ── LCD outputs → lcd_ctrl_a.v ────────────────────────────────────────────
    output wire [7:0]  LCD_DATA,
    output wire        LCD_EN,
    output wire        LCD_RS,
    output wire        LCD_RW,
    output wire        LCD_ON
);

    // ── FSM state encoding ────────────────────────────────────────────────────
    localparam [2:0]
        S_IDLE    = 3'd0,
        S_ENC_PLS = 3'd1,   // one-cycle enc_start pulse
        S_ENCRYPT = 3'd2,
        S_LOCKED  = 3'd3,
        S_VFY_PLS = 3'd4,   // one-cycle verify_start pulse
        S_VERIFY  = 3'd5,
        S_CRACKED = 3'd6;

    localparam [1:0]
        DISP_BLANK   = 2'b00,
        DISP_LOCKED  = 2'b01,
        DISP_CRACKED = 2'b10;

    // ── State and control registers ───────────────────────────────────────────
    reg [2:0] state;
    reg       enc_start;
    reg       verify_start;
    reg [1:0] lcd_state;

    // ── Found-key registers (assembled by UART RX deserializer) ───────────────
    reg [55:0] found_key_int;    // assembled 56-bit candidate from Side B
    reg        key_found_int;    // 1-cycle pulse when 7 bytes complete

    // ── Key expansion ─────────────────────────────────────────────────────────
    wire [63:0] defender_key64 = expand_key56_to_64(DEFENDER_KEY56);
    wire [63:0] found_key64    = expand_key56_to_64(found_key_int);

    // ── DES datapaths ─────────────────────────────────────────────────────────
    wire [63:0] enc_ciphertext;
    wire        enc_done;

    wire [63:0] verify_ciphertext;
    wire        verify_done;

    reg  [63:0] ciphertext_reg;
    wire        verify_match;

    des_datapath u_encrypt (
        .clk(clk),       .rst_n(rst_n),
        .start(enc_start),    .decrypt(1'b0),
        .plaintext(PLAINTEXT_FIXED), .key(defender_key64),
        .ciphertext(enc_ciphertext), .done(enc_done)
    );

    des_datapath u_verify (
        .clk(clk),       .rst_n(rst_n),
        .start(verify_start), .decrypt(1'b0),
        .plaintext(PLAINTEXT_FIXED), .key(found_key64),
        .ciphertext(verify_ciphertext), .done(verify_done)
    );

    comparator u_cmp (
        .a(ciphertext_reg),
        .b(verify_ciphertext),
        .match(verify_match)
    );

    // ── LCD controller ────────────────────────────────────────────────────────
    lcd_ctrl_a u_lcd (
        .clk(clk),       .rst_n(rst_n),
        .lcd_state(lcd_state),
        .LCD_DATA(LCD_DATA), .LCD_EN(LCD_EN),
        .LCD_RS(LCD_RS),  .LCD_RW(LCD_RW), .LCD_ON(LCD_ON)
    );

    // ── Continuous output assignments ─────────────────────────────────────────
    assign ciphertext       = ciphertext_reg;
    assign ciphertext_valid = (state == S_LOCKED)  || (state == S_VFY_PLS) ||
                              (state == S_VERIFY)  || (state == S_CRACKED);
    assign cracked          = (state == S_CRACKED);

    // ── UART TX: send ciphertext (8 bytes, MSB-first) once after encryption ───
    reg       send_active;
    reg [2:0] send_idx;
    reg       uart_start;
    reg [7:0] uart_data;

    uart_tx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_uart_tx (
        .clk(clk),   .rst_n(rst_n),
        .start(uart_start), .data_in(uart_data),
        .tx(tx),     .busy(uart_busy)
    );

    // ── UART RX: receive found_key (7 bytes, MSB-first) from Side B ──────────
    // 2-FF synchronizer — metastability protection for cross-board signal.
    reg uart_rx_meta, uart_rx_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_rx_meta <= 1'b1;   // UART idle is high
            uart_rx_sync <= 1'b1;
        end else begin
            uart_rx_meta <= uart_rx_in;
            uart_rx_sync <= uart_rx_meta;
        end
    end

    wire [7:0] rx_data;
    wire       rx_valid;

    uart_rx #(.CLK_FREQ(CLK_FREQ), .BAUD(BAUD)) u_uart_rx (
        .clk(clk),   .rst_n(rst_n),
        .rx(uart_rx_sync),
        .data_out(rx_data), .data_valid(rx_valid)
    );

    // 7-byte found-key deserializer.
    // Byte order: byte 0 = found_key[55:48] (MSB), byte 6 = found_key[7:0].
    reg [2:0] rx_byte_cnt;   // counts 0..6

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            found_key_int <= 56'd0;
            key_found_int <= 1'b0;
            rx_byte_cnt   <= 3'd0;
        end else begin
            key_found_int <= 1'b0;   // default: de-asserted
            if (rx_valid) begin
                // Shift new byte into the MSB end and advance counter.
                found_key_int <= {found_key_int[47:0], rx_data};
                if (rx_byte_cnt == 3'd6) begin
                    key_found_int <= 1'b1;   // 1-cycle pulse — all 7 bytes in
                    rx_byte_cnt   <= 3'd0;
                end else begin
                    rx_byte_cnt <= rx_byte_cnt + 3'd1;
                end
            end
        end
    end

    // ── Main FSM + UART TX scheduler ─────────────────────────────────────────
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            enc_start      <= 1'b0;
            verify_start   <= 1'b0;
            ciphertext_reg <= 64'd0;
            disp_state     <= DISP_BLANK;
            lcd_state      <= DISP_BLANK;
            send_active    <= 1'b0;
            send_idx       <= 3'd0;
            uart_start     <= 1'b0;
            uart_data      <= 8'd0;
        end else begin
            enc_start    <= 1'b0;
            verify_start <= 1'b0;
            uart_start   <= 1'b0;

            // UART TX byte scheduler — fires once after encryption completes.
            if (send_active && !uart_busy) begin
                case (send_idx)
                    3'd0: uart_data <= ciphertext_reg[63:56];
                    3'd1: uart_data <= ciphertext_reg[55:48];
                    3'd2: uart_data <= ciphertext_reg[47:40];
                    3'd3: uart_data <= ciphertext_reg[39:32];
                    3'd4: uart_data <= ciphertext_reg[31:24];
                    3'd5: uart_data <= ciphertext_reg[23:16];
                    3'd6: uart_data <= ciphertext_reg[15: 8];
                    default: uart_data <= ciphertext_reg[ 7: 0];
                endcase
                uart_start <= 1'b1;
                if (send_idx == 3'd7)
                    send_active <= 1'b0;
                else
                    send_idx <= send_idx + 3'd1;
            end

            // Main FSM
            case (state)
                S_IDLE: begin
                    disp_state <= DISP_BLANK;
                    lcd_state  <= DISP_BLANK;
                    if (start)
                        state <= S_ENC_PLS;
                end

                S_ENC_PLS: begin
                    enc_start <= 1'b1;
                    state     <= S_ENCRYPT;
                end

                S_ENCRYPT: begin
                    if (enc_done) begin
                        ciphertext_reg <= enc_ciphertext;
                        disp_state     <= DISP_LOCKED;
                        lcd_state      <= DISP_LOCKED;
                        send_active    <= 1'b1;   // kick off ciphertext TX
                        send_idx       <= 3'd0;
                        state          <= S_LOCKED;
                    end
                end

                S_LOCKED: begin
                    disp_state <= DISP_LOCKED;
                    lcd_state  <= DISP_LOCKED;
                    if (key_found_int)
                        state <= S_VFY_PLS;
                end

                S_VFY_PLS: begin
                    verify_start <= 1'b1;
                    state        <= S_VERIFY;
                end

                S_VERIFY: begin
                    if (verify_done) begin
                        if (verify_match) begin
                            disp_state <= DISP_CRACKED;
                            lcd_state  <= DISP_CRACKED;
                            state      <= S_CRACKED;
                        end else begin
                            // False positive — return to LOCKED and wait again.
                            state <= S_LOCKED;
                        end
                    end
                end

                S_CRACKED: begin
                    disp_state <= DISP_CRACKED;
                    lcd_state  <= DISP_CRACKED;
                    // Latches here until reset.
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // ── Key expansion: 56-bit → 64-bit with odd parity bytes ─────────────────
    // Each group of 7 key bits gets an odd-parity LSB appended, per DES spec.
    function [63:0] expand_key56_to_64;
        input [55:0] key56;
        integer i;
        reg [6:0] seven;
        reg       parity;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                seven  = key56[55 - i*7 -: 7];
                parity = ~(^seven);   // odd parity
                expand_key56_to_64[63 - i*8 -: 8] = {seven, parity};
            end
        end
    endfunction

endmodule
