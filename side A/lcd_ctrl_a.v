// lcd_ctrl_a.v — Side A HD44780 16x2 LCD Controller
// Target board : DE2-115 (Cyclone IV E)
// Clock        : CLOCK_50 (50 MHz, 20 ns/cycle)
// Reset        : rst_n active-low synchronous
//
// Per DE2-115 manual section 4.6:
//   - LCD is HD44780 compatible, 16x2 characters, 8-bit data bus
//   - LCD_BLON must NOT be used (no backlight on DE2-115)
//   - LCD_ON = 1 to power the display
//
// Pin usage:
//   LCD_DATA[7:0]  — 8-bit parallel data/command bus
//   LCD_EN         — enable pulse (data latched on falling edge)
//   LCD_RS         — 0 = command register, 1 = data register
//   LCD_RW         — 0 = write, 1 = read (always 0 here, write-only)
//   LCD_ON         — 1 = display powered on
//
// Display content per lcd_state (from ctrl_a.v):
//   2'b00 BLANK  → line1: "                "
//                  line2: "                "
//   2'b01 LOCKED → line1: "  DES DEFENDER  "
//                  line2: "   ** LOCKED ** "
//   2'b10 CRACKED→ line1: "  DES DEFENDER  "
//                  line2: "  ** CRACKED ** "
//
// Timing at 50 MHz (1 cycle = 20 ns):
//   Power-on delay  : 40 ms  = 2,000,000 cycles
//   Inter-cmd delay : 2 ms   =   100,000 cycles
//   Clear cmd delay : 2 ms   =   100,000 cycles
//   Normal cmd delay: 50 us  =     2,500 cycles
//   EN pulse width  : 500 ns =        25 cycles (min 230 ns per datasheet)
//   EN setup time   : 100 ns =         5 cycles (min 40 ns)
//
// Architecture:
//   A sequencer steps through a ROM of (type, byte) pairs.
//   For each byte it runs a 4-phase write sub-FSM:
//     SETUP → EN_HI → EN_LO → WAIT
//   After the init sequence the sequencer watches lcd_state
//   and re-runs a write sequence whenever it changes.

module lcd_ctrl_a (
    input  wire        clk,
    input  wire        rst_n,

    input  wire [1:0]  lcd_state,     // from ctrl_a.v

    output reg  [7:0]  LCD_DATA,
    output reg         LCD_EN,
    output reg         LCD_RS,
    output reg         LCD_RW,
    output reg         LCD_ON
);

    //Timing constants (50 MHz)
    localparam PWR_CYCLES  = 23'd2_000_000; // 40 ms power-on wait
    localparam CMD_CYCLES  = 23'd100_000;   // 2 ms after most commands
    localparam CLR_CYCLES  = 23'd100_000;   // 2 ms after clear
    localparam EN_SETUP    = 23'd5;         // 100 ns RS/RW setup before EN↑
    localparam EN_WIDTH    = 23'd25;        // 500 ns EN high pulse
    localparam EN_HOLD     = 23'd5;         // 100 ns hold after EN↓

    //HD44780 command bytes
    localparam CMD_FUNC_SET  = 8'h38; // 8-bit, 2-line, 5x8 font
    localparam CMD_DISP_ON   = 8'h0C; // display on, cursor off, blink off
    localparam CMD_CLR       = 8'h01; // clear display, cursor home
    localparam CMD_ENTRY     = 8'h06; // increment cursor, no display shift
    localparam CMD_LINE1     = 8'h80; // DDRAM address 0x00 (line 1 start)
    localparam CMD_LINE2     = 8'hC0; // DDRAM address 0x40 (line 2 start)

    //lcd_state codes (must match ctrl_a.v)
    localparam [1:0]
        DISP_BLANK   = 2'b00,
        DISP_LOCKED  = 2'b01,
        DISP_CRACKED = 2'b10;

    //Sequencer ROM
    // Each entry: {is_data[0], byte[7:0]}
    // is_data=0 → command (RS=0), is_data=1 → character data (RS=1)
    // Index 0..6  : init sequence (always runs once at startup)
    // Index 7..44 : line 1 write (16 chars) + line 2 write (16 chars)
    //   Layout: [7]=CMD_LINE1, [8..23]=line1 chars,
    //           [24]=CMD_LINE2, [25..40]=line2 chars
    // We build the write sequence dynamically from the char ROMs below.

    // Character ROMs — 16 bytes each
    // Line 1 is always "  DES DEFENDER  " for LOCKED/CRACKED
    // Line 1 for BLANK is all spaces
    // Line 2 varies by state

    // "  DES DEFENDER  "
    localparam [127:0] LINE1_MSG =
        {8'h20,8'h20,8'h44,8'h45,8'h53,8'h20,
         8'h44,8'h45,8'h46,8'h45,8'h4E,8'h44,
         8'h45,8'h52,8'h20,8'h20};

    // "                " (16 spaces)
    localparam [127:0] LINE1_BLANK =
        {8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,
         8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,
         8'h20,8'h20,8'h20,8'h20};

    // "   ** LOCKED ** "
    localparam [127:0] LINE2_LOCKED =
        {8'h20,8'h20,8'h20,8'h2A,8'h2A,8'h20,
         8'h4C,8'h4F,8'h43,8'h4B,8'h45,8'h44,
         8'h20,8'h2A,8'h2A,8'h20};

    // "  ** CRACKED ** "
    localparam [127:0] LINE2_CRACKED =
        {8'h20,8'h20,8'h2A,8'h2A,8'h20,8'h43,
         8'h52,8'h41,8'h43,8'h4B,8'h45,8'h44,
         8'h20,8'h2A,8'h2A,8'h20};

    // "                " (16 spaces)
    localparam [127:0] LINE2_BLANK =
        {8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,
         8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,
         8'h20,8'h20,8'h20,8'h20};

    //Top-level FSM
    localparam [2:0]
        S_PWR_WAIT  = 3'd0,   // power-on delay
        S_INIT      = 3'd1,   // send init command sequence
        S_IDLE      = 3'd2,   // wait for lcd_state change
        S_START_WR  = 3'd3,   // begin display write
        S_WRITE     = 3'd4;   // write chars to LCD

    //Sub-FSM for sending one byte
    localparam [1:0]
        W_SETUP  = 2'd0,
        W_EN_HI  = 2'd1,
        W_EN_LO  = 2'd2,
        W_WAIT   = 2'd3;

    reg [2:0]  state;
    reg [1:0]  w_state;       // write sub-FSM state
    reg [22:0] timer;         // general purpose countdown timer
    reg [5:0]  seq_idx;       // index into current sequence (0..6 init, 0..33 write)
    reg [1:0]  lcd_state_r;   // registered lcd_state for change detection
    reg        doing_init;    // 1 = running init sequence, 0 = running write sequence
    reg [22:0] wait_cycles;   // how long to wait after current byte

    //Current byte being sent and its RS value
    reg [7:0]  cur_byte;
    reg        cur_rs;

    //Line/char selection helpers
    //Returns the byte for character position pos (0..15) of a 128-bit line
    function [7:0] line_char;
        input [127:0] line;
        input [3:0]   pos;   // 0 = leftmost
        begin
            // MSB of line = leftmost char
            line_char = line[127 - (pos*8) -: 8];
        end
    endfunction

    //Init sequence ROM
    //Returns {rs, byte, wait_cycles} for each init step
    task init_entry;
        input  [4:0]  idx;
        output        rs;
        output [7:0]  byt;
        output [22:0] wt;
        begin
            case (idx)
                6'd0: begin rs=0; byt=CMD_FUNC_SET; wt=CMD_CYCLES; end
                6'd1: begin rs=0; byt=CMD_FUNC_SET; wt=CMD_CYCLES; end
                5'd2: begin rs=0; byt=CMD_FUNC_SET; wt=CMD_CYCLES; end
                5'd3: begin rs=0; byt=CMD_DISP_ON;  wt=CMD_CYCLES; end
                5'd4: begin rs=0; byt=CMD_CLR;       wt=CLR_CYCLES; end
                5'd5: begin rs=0; byt=CMD_ENTRY;     wt=CMD_CYCLES; end
                default: begin rs=0; byt=8'h00; wt=CMD_CYCLES; end
            endcase
        end
    endtask

    localparam INIT_LEN  = 6'd6;   // 6 init commands
    localparam WRITE_LEN = 6'd34;  // CMD_LINE1 + 16 chars + CMD_LINE2 + 16 chars

    //Registered lcd_state for write sequencer
    reg [1:0] active_state; // which state we are currently displaying

    //Main FSM
    always @(posedge clk) begin
        if (!rst_n) begin
            state       <= S_PWR_WAIT;
            w_state     <= W_SETUP;
            timer       <= PWR_CYCLES;
            seq_idx     <= 6'd0;
            lcd_state_r <= 2'b00;
            active_state<= 2'b00;
            doing_init  <= 1'b1;
            LCD_DATA    <= 8'h00;
            LCD_EN      <= 1'b0;
            LCD_RS      <= 1'b0;
            LCD_RW      <= 1'b0;
            LCD_ON      <= 1'b1;
            cur_byte    <= 8'h00;
            cur_rs      <= 1'b0;
            wait_cycles <= CMD_CYCLES;
        end else begin
            LCD_RW <= 1'b0;   // always write
            LCD_ON <= 1'b1;   // always keep display powered

            case (state)

                //Power-on delay
                S_PWR_WAIT: begin
                    LCD_EN <= 1'b0;
                    if (timer == 23'd0) begin
                        state   <= S_INIT;
                        seq_idx <= 6'd0;
                        doing_init <= 1'b1;
                    end else
                        timer <= timer - 23'd1;
                end

                //nit and write sequencer
                //Shared entry point: load current byte from init or write ROM
                S_INIT: begin
                    if (doing_init) begin
                        // Load next init command
                        begin : init_load
                            reg        rs;
                            reg [7:0]  byt;
                            reg [22:0] wt;
                            init_entry(seq_idx, rs, byt, wt);
                            cur_rs      <= rs;
                            cur_byte    <= byt;
                            wait_cycles <= wt;
                        end
                    end else begin
                        //Load next write sequence entry
                        if (seq_idx == 6'd0) begin
                            // CMD: set DDRAM to line 1
                            cur_rs      <= 1'b0;
                            cur_byte    <= CMD_LINE1;
                            wait_cycles <= CMD_CYCLES;
                        end else if (seq_idx <= 6'd16) begin
                            //Line 1 characters
                            cur_rs <= 1'b1;
                            case (active_state)
                                DISP_LOCKED:  cur_byte <= line_char(LINE1_MSG,   seq_idx - 6'd1);
                                DISP_CRACKED: cur_byte <= line_char(LINE1_MSG,   seq_idx - 6'd1);
                                default:      cur_byte <= line_char(LINE1_BLANK, seq_idx - 6'd1);
                            endcase
                            wait_cycles <= CMD_CYCLES;
                        end else if (seq_idx == 6'd17) begin
                            //CMD: set DDRAM to line 2
                            cur_rs      <= 1'b0;
                            cur_byte    <= CMD_LINE2;
                            wait_cycles <= CMD_CYCLES;
                        end else begin
                            //Line 2 characters (seq_idx 18..33)
                            cur_rs <= 1'b1;
                            case (active_state)
                                DISP_LOCKED:  cur_byte <= line_char(LINE2_LOCKED,  seq_idx - 6'd18);
                                DISP_CRACKED: cur_byte <= line_char(LINE2_CRACKED, seq_idx - 6'd18);
                                default:      cur_byte <= line_char(LINE2_BLANK,   seq_idx - 6'd18);
                            endcase
                            wait_cycles <= CMD_CYCLES;
                        end
                    end
                    w_state <= W_SETUP;
                    timer   <= EN_SETUP;
                    state   <= S_WRITE;
                end

                //4-phase byte write sub-FSM
                S_WRITE: begin
                    case (w_state)

                        //Phase 1: drive RS and data, wait setup time
                        W_SETUP: begin
                            LCD_RS   <= cur_rs;
                            LCD_DATA <= cur_byte;
                            LCD_EN   <= 1'b0;
                            if (timer == 23'd0) begin
                                w_state <= W_EN_HI;
                                timer   <= EN_WIDTH;
                            end else
                                timer <= timer - 23'd1;
                        end

                        //Phase 2: EN high for pulse width
                        W_EN_HI: begin
                            LCD_EN <= 1'b1;
                            if (timer == 23'd0) begin
                                w_state <= W_EN_LO;
                                timer   <= EN_HOLD;
                            end else
                                timer <= timer - 23'd1;
                        end

                        //Phase 3: EN low, hold
                        W_EN_LO: begin
                            LCD_EN <= 1'b0;
                            if (timer == 23'd0) begin
                                w_state <= W_WAIT;
                                timer   <= wait_cycles;
                            end else
                                timer <= timer - 23'd1;
                        end

                        //Phase 4: wait for LCD to process the command/data
                        W_WAIT: begin
                            if (timer == 23'd0) begin
                                // Byte done — advance sequencer
                                if (doing_init) begin
                                    if (seq_idx == INIT_LEN - 6'd1) begin
                                        // Init complete
                                        doing_init  <= 1'b0;
                                        seq_idx     <= 6'd0;
                                        active_state<= lcd_state;
                                        lcd_state_r <= lcd_state;
                                        state       <= S_INIT; // immediately write initial state
                                    end else begin
                                        seq_idx <= seq_idx + 6'd1;
                                        state   <= S_INIT;
                                    end
                                end else begin
                                    if (seq_idx == WRITE_LEN - 6'd1) begin
                                        // Write sequence complete
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
                    endcase
                end

                //Idle — watch for lcd_state change
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
//All in all this was horrible and im not even sure if it works but we'll see