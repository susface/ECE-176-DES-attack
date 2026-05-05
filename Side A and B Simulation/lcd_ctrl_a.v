// lcd_ctrl_a.v — Side A HD44780 16x2 LCD Controller
// Target board : DE2-115 (Cyclone IV E)
// Clock        : CLOCK_50 (50 MHz, 20 ns/cycle)
// Reset        : rst_n active-low synchronous
//
// Per DE2-115 manual 4.6:
//   LCD_BLON must NOT be used.  LCD_ON = 1'b1 to power the display.
//
// Display content per lcd_state (from defender_top.v):
//   2'b00 BLANK   → "                " / "                "
//   2'b01 LOCKED  → "  DES DEFENDER  " / "   ** LOCKED ** "
//   2'b10 CRACKED → "  DES DEFENDER  " / "  ** CRACKED ** "
//
// Timing at 50 MHz (1 cycle = 20 ns):
//   PWR_CYCLES : 40 ms  = 2 000 000 cycles (power-on wait)
//   CMD_CYCLES :  2 ms  =   100 000 cycles (command/data settle)
//   EN_SETUP   : 100 ns =         5 cycles (RS/RW stable before EN↑)
//   EN_WIDTH   : 500 ns =        25 cycles (EN high pulse)
//   EN_HOLD    : 100 ns =         5 cycles (data hold after EN↓)
//
// Architecture:
//   Power-on wait → 6-command init sequence →
//   idle watching lcd_state → re-write both lines on any change.
//
// References / implementations used:
//   [1] HD44780U Datasheet, Hitachi Semiconductor — primary source for all
//       command bytes, initialization sequence, and timing requirements.
//       https://www.sparkfun.com/datasheets/LCD/HD44780.pdf
//
//   [2] Jon Carrier, "FPGA_2_LCD.v" (2011) — Verilog LCD controller gist
//       using a nested STATE/SUBSTATE FSM structure, the same
//       command byte values (8'h38, 8'h0C, 8'h01, 8'h06), and a
//       write-only LCD_RW=0 convention.
//       https://gist.github.com/jjcarrier/1529101
//
//   [3] Edwin NC Mui, "Interfacing FPGA to HD44780 LCD" — paper describing
//       the FSM-with-delay-elements approach for HD44780 timing control.
//       https://www.scribd.com/doc/259857897/LCD-HD44780
//
//   [4] Terasic DE2-115 User Manual §4.6 — pin names, LCD_BLON restriction,
//       and 8-bit parallel bus configuration.
module lcd_ctrl_a (// This was done by me
    input  wire        clk,
    input  wire        rst_n,
    input  wire [1:0]  lcd_state,     // from defender_top.v
    output reg  [7:0]  LCD_DATA,
    output reg         LCD_EN,
    output reg         LCD_RS,
    output reg         LCD_RW,
    output reg         LCD_ON
);

    // ── Timing constants ─────────────────────────────────────────────────────
    // Values derived from HD44780 datasheet [1] AC characteristics table.
    // Approach of representing all delays as cycle counts at a fixed clock
    // frequency is a common FPGA pattern; see also [2] and [3].
    localparam [22:0]
        PWR_CYCLES = 23'd2_000_000,   // ≥40 ms power-on wait (datasheet §4)
        CMD_CYCLES = 23'd100_000,     // ≥2 ms command execution time
        EN_SETUP   = 23'd5,           // ≥40 ns RS/RW setup before EN↑
        EN_WIDTH   = 23'd25,          // ≥230 ns EN high pulse width
        EN_HOLD    = 23'd5;           // ≥10 ns data hold after EN↓

    // ── HD44780 command bytes ─────────────────────────────────────────────────
    // All values from HD44780 datasheet [1] instruction set table (p.24).
    // Same byte values appear in [2] (SETUP=8'h38, DISP_ON=8'h0C,
    // CLEAR=8'h01, ENTRY_N=8'h06) — these are universal for this chip.
    localparam [7:0]
        CMD_FUNC_SET = 8'h38,   // 8-bit bus, 2-line, 5×8 font
        CMD_DISP_ON  = 8'h0C,   // display on, cursor off, blink off
        CMD_CLR      = 8'h01,   // clear display + cursor home
        CMD_ENTRY    = 8'h06,   // increment cursor, no display shift
        CMD_LINE1    = 8'h80,   // DDRAM address 0x00 (line 1 home)
        CMD_LINE2    = 8'hC0;   // DDRAM address 0x40 (line 2 home)

    // ── Display state codes (must match defender_top.v) done by me
    localparam [1:0]
        DISP_BLANK   = 2'b00,
        DISP_LOCKED  = 2'b01,
        DISP_CRACKED = 2'b10;

    // ── 128-bit character ROMs (MSB = leftmost character) section below is done by me
    // "  DES DEFENDER  "
    localparam [127:0] LINE1_MSG =
        { 8'h20, 8'h20, 8'h44, 8'h45, 8'h53, 8'h20,
          8'h44, 8'h45, 8'h46, 8'h45, 8'h4E, 8'h44,
          8'h45, 8'h52, 8'h20, 8'h20 };

    // "                " (16 spaces)
    localparam [127:0] LINE1_BLANK = 128'h20202020_20202020_20202020_20202020;

    // "   ** LOCKED ** "
    localparam [127:0] LINE2_LOCKED =
        { 8'h20, 8'h20, 8'h20, 8'h2A, 8'h2A, 8'h20,
          8'h4C, 8'h4F, 8'h43, 8'h4B, 8'h45, 8'h44,
          8'h20, 8'h2A, 8'h2A, 8'h20 };

    // "  ** CRACKED ** "
    localparam [127:0] LINE2_CRACKED =
        { 8'h20, 8'h20, 8'h2A, 8'h2A, 8'h20, 8'h43,
          8'h52, 8'h41, 8'h43, 8'h4B, 8'h45, 8'h44,
          8'h20, 8'h2A, 8'h2A, 8'h20 };

    // "                " (16 spaces)
    localparam [127:0] LINE2_BLANK = 128'h20202020_20202020_20202020_20202020;

    // ── Sequence lengths ──────────────────────────────────────────────────────
    localparam [5:0]
        INIT_LEN  = 6'd6,    // indices 0–5
        WRITE_LEN = 6'd34;   // CMD_LINE1 + 16 chars + CMD_LINE2 + 16 chars

    // ── Top-level FSM (4 states — S_START_WR removed as dead code) ───────────
    // Nested outer inner FSM structure is a common pattern for HD44780 control;
    // see [2] which uses the same STATE/SUBSTATE split, and [3] which describes
    // the general FSM-with-delay-elements approach for this chip.
    localparam [1:0]
        S_PWR_WAIT = 2'd0,
        S_INIT     = 2'd1,
        S_IDLE     = 2'd2,
        S_WRITE    = 2'd3;

    // ── Byte-send sub-FSM ─────────────────────────────────────────────────────
    // 4-phase sequence (SETUP → EN_HI → EN_LO → WAIT) implements the
    // EN-pulse write cycle from HD44780 datasheet [1] Figure 9 (p.22).
    // LCD_RW held permanently low (write-only) — same convention as [2].
    localparam [1:0]
        W_SETUP = 2'd0,
        W_EN_HI = 2'd1,
        W_EN_LO = 2'd2,
        W_WAIT  = 2'd3;

    // ── Registers ────────────────────────────────────────────────────── done by me
    reg [1:0]  state, w_state;
    reg [22:0] timer;
    reg [5:0]  seq_idx;
    reg [1:0]  lcd_state_r;
    reg [1:0]  active_state;
    reg        doing_init;
    reg [22:0] wait_cycles;
    reg [7:0]  cur_byte;
    reg        cur_rs;

    // Module-level temporaries for init_entry task outputs. done by me
    reg        t_rs;
    reg [7:0]  t_byt;
    reg [22:0] t_wt;

    // ── Helper: extract one byte from a 128-bit ROM at column pos (0 = left) ──
    // Explicit case for 100% synthesiser compatibility (no dynamic bit-select). done by me
    function [7:0] line_char;
        input [127:0] line;
        input [3:0]   pos;
        begin
            case (pos)
                4'd0:  line_char = line[127:120];
                4'd1:  line_char = line[119:112];
                4'd2:  line_char = line[111:104];
                4'd3:  line_char = line[103: 96];
                4'd4:  line_char = line[ 95: 88];
                4'd5:  line_char = line[ 87: 80];
                4'd6:  line_char = line[ 79: 72];
                4'd7:  line_char = line[ 71: 64];
                4'd8:  line_char = line[ 63: 56];
                4'd9:  line_char = line[ 55: 48];
                4'd10: line_char = line[ 47: 40];
                4'd11: line_char = line[ 39: 32];
                4'd12: line_char = line[ 31: 24];
                4'd13: line_char = line[ 23: 16];
                4'd14: line_char = line[ 15:  8];
                4'd15: line_char = line[  7:  0];
                default: line_char = 8'h20;
            endcase
        end
    endfunction

    // ── Init ROM task ─────────────────────────────────────────────────────────
    // Sequence mandated by HD44780 datasheet [1] Figure 23 (p.45):
    // "Initializing by Instruction" for 8-bit interface.
    // Three repeated Function Set commands followed by Display On,
    // Clear Display, and Entry Mode Set.  This exact sequence appears
    // in virtually every HD44780 FPGA driver including [2] and [3].
    task init_entry;
        input  [5:0]  idx;
        output        rs;
        output [7:0]  byt;
        output [22:0] wt;
        begin
            case (idx)
                6'd0: begin rs = 1'b0; byt = CMD_FUNC_SET; wt = CMD_CYCLES; end
                6'd1: begin rs = 1'b0; byt = CMD_FUNC_SET; wt = CMD_CYCLES; end
                6'd2: begin rs = 1'b0; byt = CMD_FUNC_SET; wt = CMD_CYCLES; end
                6'd3: begin rs = 1'b0; byt = CMD_DISP_ON;  wt = CMD_CYCLES; end
                6'd4: begin rs = 1'b0; byt = CMD_CLR;      wt = CMD_CYCLES; end
                6'd5: begin rs = 1'b0; byt = CMD_ENTRY;    wt = CMD_CYCLES; end
                default: begin rs = 1'b0; byt = 8'h00; wt = CMD_CYCLES; end
            endcase
        end
    endtask

    // ── Main always block ──────────────────────────────────────────── everything below is done by me
    always @(posedge clk) begin
        if (!rst_n) begin
            state        <= S_PWR_WAIT;
            w_state      <= W_SETUP;
            timer        <= PWR_CYCLES;
            seq_idx      <= 6'd0;
            lcd_state_r  <= 2'b00;
            active_state <= 2'b00;
            doing_init   <= 1'b1;
            LCD_DATA     <= 8'h00;
            LCD_EN       <= 1'b0;
            LCD_RS       <= 1'b0;
            LCD_RW       <= 1'b0;
            LCD_ON       <= 1'b1;
            cur_byte     <= 8'h00;
            cur_rs       <= 1'b0;
            wait_cycles  <= CMD_CYCLES;
            t_rs         <= 1'b0;
            t_byt        <= 8'h00;
            t_wt         <= CMD_CYCLES;
        end else begin
            LCD_RW <= 1'b0;   // always write
            LCD_ON <= 1'b1;   // always powered

            case (state)

                // ── Power-on delay ────────────────────────────────────────────
                S_PWR_WAIT: begin
                    LCD_EN <= 1'b0;
                    if (timer == 23'd0) begin
                        doing_init <= 1'b1;
                        seq_idx    <= 6'd0;
                        state      <= S_INIT;
                    end else
                        timer <= timer - 23'd1;
                end

                // ── Load next byte into cur_byte/cur_rs/wait_cycles ───────────
                // Shared by init and write sequences; transitions to S_WRITE.
                S_INIT: begin
                    if (doing_init) begin
                        // Init ROM lookup — use module-level temporaries.
                        init_entry(seq_idx, t_rs, t_byt, t_wt);
                        cur_rs      <= t_rs;
                        cur_byte    <= t_byt;
                        wait_cycles <= t_wt;
                    end else begin
                        if (seq_idx == 6'd0) begin
                            // CMD: move cursor to line 1
                            cur_rs      <= 1'b0;
                            cur_byte    <= CMD_LINE1;
                            wait_cycles <= CMD_CYCLES;
                        end else if (seq_idx <= 6'd16) begin
                            // Line 1 chars — seq_idx 1..16 → pos 0..15
                            // seq_idx[3:0] - 4'd1: at seq_idx=16, [3:0]=0, 0-1=15 (wrap) ✓
                            cur_rs <= 1'b1;
                            case (active_state)
                                DISP_LOCKED,
                                DISP_CRACKED: cur_byte <= line_char(LINE1_MSG,
                                                             seq_idx[3:0] - 4'd1);
                                default:      cur_byte <= line_char(LINE1_BLANK,
                                                             seq_idx[3:0] - 4'd1);
                            endcase
                            wait_cycles <= CMD_CYCLES;
                        end else if (seq_idx == 6'd17) begin
                            // CMD: move cursor to line 2
                            cur_rs      <= 1'b0;
                            cur_byte    <= CMD_LINE2;
                            wait_cycles <= CMD_CYCLES;
                        end else begin
                            // Line 2 chars — seq_idx 18..33 → pos 0..15
                            // seq_idx[3:0] for 18..33 = 2..1 (mod 16)
                            // Subtracting 4'd2 wraps correctly: 0→14, 1→15
                            cur_rs <= 1'b1;
                            case (active_state)
                                DISP_LOCKED:  cur_byte <= line_char(LINE2_LOCKED,
                                                             seq_idx[3:0] - 4'd2);
                                DISP_CRACKED: cur_byte <= line_char(LINE2_CRACKED,
                                                             seq_idx[3:0] - 4'd2);
                                default:      cur_byte <= line_char(LINE2_BLANK,
                                                             seq_idx[3:0] - 4'd2);
                            endcase
                            wait_cycles <= CMD_CYCLES;
                        end
                    end
                    // Kick off the 4-phase byte send.
                    w_state <= W_SETUP;
                    timer   <= EN_SETUP;
                    state   <= S_WRITE;
                end

                // ── 4-phase byte write sub-FSM ────────────────────────────────
                S_WRITE: begin
                    case (w_state)

                        W_SETUP: begin
                            // Drive RS and DATA; hold EN low for setup time.
                            LCD_RS   <= cur_rs;
                            LCD_DATA <= cur_byte;
                            LCD_EN   <= 1'b0;
                            if (timer == 23'd0) begin
                                w_state <= W_EN_HI;
                                timer   <= EN_WIDTH;
                            end else
                                timer <= timer - 23'd1;
                        end

                        W_EN_HI: begin
                            // EN high for pulse width — LCD latches on falling edge.
                            LCD_EN <= 1'b1;
                            if (timer == 23'd0) begin
                                w_state <= W_EN_LO;
                                timer   <= EN_HOLD;
                            end else
                                timer <= timer - 23'd1;
                        end

                        W_EN_LO: begin
                            // EN low, hold data for hold time.
                            LCD_EN <= 1'b0;
                            if (timer == 23'd0) begin
                                w_state <= W_WAIT;
                                timer   <= wait_cycles;
                            end else
                                timer <= timer - 23'd1;
                        end

                        W_WAIT: begin
                            // Wait for LCD to process command/data.
                            if (timer == 23'd0) begin
                                if (doing_init) begin
                                    if (seq_idx == INIT_LEN - 6'd1) begin
                                        // Init done — write the current display state immediately.
                                        doing_init   <= 1'b0;
                                        seq_idx      <= 6'd0;
                                        active_state <= lcd_state;
                                        lcd_state_r  <= lcd_state;
                                        state        <= S_INIT;
                                    end else begin
                                        seq_idx <= seq_idx + 6'd1;
                                        state   <= S_INIT;
                                    end
                                end else begin
                                    if (seq_idx == WRITE_LEN - 6'd1) begin
                                        // Write done — go idle.
                                        seq_idx <= 6'd0;
                                        state   <= S_IDLE;
                                    end else begin
                                        seq_idx <= seq_idx + 6'd1;
                                        state   <= S_INIT;
                                    end
                                end
                            end else
                                timer <= timer - 23'd1;
                        end

                        default: w_state <= W_SETUP;
                    endcase
                end

                // ── Idle: watch for lcd_state change ──────────────────────────
                S_IDLE: begin
                    lcd_state_r <= lcd_state;
                    if (lcd_state != lcd_state_r) begin
                        active_state <= lcd_state;
                        seq_idx      <= 6'd0;
                        doing_init   <= 1'b0;
                        state        <= S_INIT;
                    end
                end

                default: state <= S_PWR_WAIT;
            endcase
        end
    end

endmodule
