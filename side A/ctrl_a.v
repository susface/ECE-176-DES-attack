// ctrl_a.v — Side A (Defender) Moore FSM Controller
// Target board : DE2-115 (Cyclone IV E)
// Clock        : CLOCK_50 (50 MHz)
// Reset        : KEY[0], active-low, synchronous
//
// UART removed — will be added as a separate module later.(maybe)
// For now, KEY[1] (active-low) is wired to start at the top level.

module ctrl_a (
    input  wire        clk,
    input  wire        rst_n,       // KEY[0] active-low synchronous reset

    // ── Start trigger (KEY[1] at top level, active-low inverted) ─────────────
    input  wire        start,       // 1 = begin encryption sequence

    // ── DES datapath interface ────────────────────────────────────────────────
    input  wire        des_done,    // 1 = des_datapath finished, ciphertext valid
    output reg         enc_en,      // one-cycle start pulse → des_datapath
    output reg  [63:0] plaintext,   // fixed plaintext "Grade A!" → datapath
    output reg  [55:0] key_reg,     // 56-bit secret key → datapath

    // ── Verifier interface ────────────────────────────────────────────────────
    input  wire        match,       // 1 = found_key re-encryption matched ct
    output reg         verify_en,   // one-cycle start pulse → verifier_a

    // ── GPIO interface (STUB — gpio modules not yet written) ──────────────────
    input  wire        key_found,   // 1 = Side B has found a key candidate
    input  wire [55:0] found_key,   // 56-bit candidate key from Side B
    output reg         gpio_tx_en,  // 1 = hold ciphertext stable on GPIO bus

    // ── Display and LED control ───────────────────────────────────────────────
    output reg  [1:0]  disp_state,  // → display_ctrl_a (7-seg)
    output reg  [1:0]  lcd_state    // → lcd_ctrl_a     (LCD)
);

    // ── State encoding ────────────────────────────────────────────────────────
    localparam [2:0]
        WAIT    = 3'd0,
        ENCRYPT = 3'd1,
        LOCKED  = 3'd2,
        VERIFY  = 3'd3,
        CRACKED = 3'd4;

    // Shared display / LCD state codes
    localparam [1:0]
        DISP_BLANK   = 2'b00,
        DISP_LOCKED  = 2'b01,
        DISP_CRACKED = 2'b10;

    // Fixed plaintext "Grade A!" — ASCII, 8 bytes = 64 bits
    // G=0x47 r=0x72 a=0x61 d=0x64 e=0x65 ' '=0x20 A=0x41 !=0x21
    localparam [63:0] PT = 64'h4772616465204121;

    // Hardcoded test key (all ones for now — replaced when UART is added)(again maybe)
    localparam [55:0] TEST_KEY = 56'hFFFFFFFFFFFFFF;

    reg [2:0] state;

    // ── State register (synchronous reset) ───────────────────────────────────
    always @(posedge clk) begin
        if (!rst_n)
            state <= WAIT;
        else begin
            case (state)
                WAIT:    state <= start     ? ENCRYPT : WAIT;
                ENCRYPT: state <= des_done  ? LOCKED  : ENCRYPT;
                LOCKED:  state <= key_found ? VERIFY  : LOCKED;
                VERIFY:  state <= match     ? CRACKED : LOCKED;
                CRACKED: state <= CRACKED;  // holds until reset
                default: state <= WAIT;
            endcase
        end
    end

    // ── Output register (Moore — based on current state) ─────────────────────
    always @(posedge clk) begin
        if (!rst_n) begin
            enc_en     <= 1'b0;
            verify_en  <= 1'b0;
            gpio_tx_en <= 1'b0;
            disp_state <= DISP_BLANK;
            lcd_state  <= DISP_BLANK;
            plaintext  <= PT;
            key_reg    <= TEST_KEY;
        end else begin
            // De-assert single-cycle pulses every cycle by default
            enc_en    <= 1'b0;
            verify_en <= 1'b0;

            case (state)
                WAIT: begin
                    gpio_tx_en <= 1'b0;
                    disp_state <= DISP_BLANK;
                    lcd_state  <= DISP_BLANK;
                end

                ENCRYPT: begin
                    enc_en     <= 1'b1;   // one-cycle start pulse
                    plaintext  <= PT;
                    key_reg    <= TEST_KEY;
                    disp_state <= DISP_BLANK;
                    lcd_state  <= DISP_BLANK;
                end

                LOCKED: begin
                    gpio_tx_en <= 1'b1;
                    disp_state <= DISP_LOCKED;
                    lcd_state  <= DISP_LOCKED;
                end

                VERIFY: begin
                    verify_en  <= 1'b1;   // one-cycle start pulse
                    gpio_tx_en <= 1'b1;
                    disp_state <= DISP_LOCKED;
                    lcd_state  <= DISP_LOCKED;
                end

                CRACKED: begin
                    gpio_tx_en <= 1'b0;
                    disp_state <= DISP_CRACKED;
                    lcd_state  <= DISP_CRACKED;
                end

                default: begin
                    disp_state <= DISP_BLANK;
                    lcd_state  <= DISP_BLANK;
                end
            endcase
        end
    end

endmodule
