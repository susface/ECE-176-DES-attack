// display_ctrl_a.v — Side A 7-segment Display Driver
// Target board : DE2-115 (Cyclone IV E)
// Interface    : purely combinational, no clock
//
// Drives all eight active-low 7-segment displays HEX7..HEX0.
// HEX[6:0] bit layout:
//   bit 0 = a (top)          bit 4 = e (bottom-left)
//   bit 1 = b (top-right)    bit 5 = f (top-left)
//   bit 2 = c (bottom-right) bit 6 = g (middle)
//   bit 3 = d (bottom)
// Active-low: 0 = segment ON, 1 = segment OFF.
//
// disp_state encoding (from defender_top.v):
//   2'b00 BLANK   → "        "  (all segments off, used during WAIT/ENCRYPT)
//   2'b01 LOCKED  → "  LOCKED"
//   2'b10 CRACKED → "CRACKED "
//   default       → "  ERROR "  (fault / undefined state)

module display_ctrl_a (
    input  wire [1:0] disp_state,
    output reg  [6:0] HEX0,
    output reg  [6:0] HEX1,
    output reg  [6:0] HEX2,
    output reg  [6:0] HEX3,
    output reg  [6:0] HEX4,
    output reg  [6:0] HEX5,
    output reg  [6:0] HEX6,
    output reg  [6:0] HEX7
);

    // ── Active-low 7-segment character constants ──────────────────────────────
    // Verification: each value derived from which segments are ON for each glyph.
    //   SEG_BLANK : nothing lit                 → 7'h7F
    //   SEG_A     : a,b,c,e,f,g lit; d off      → 7'h08
    //   SEG_C     : a,d,e,f lit; b,c,g off      → 7'h46
    //   SEG_D     : b,c,d,e,g lit; a,f off      → 7'h21  (lowercase 'd')
    //   SEG_E     : a,d,e,f,g lit; b,c off      → 7'h06
    //   SEG_K     : b,c,e,f,g lit; a,d off      → 7'h09  (H-shape, closest to K)
    //   SEG_L     : d,e,f lit; a,b,c,g off      → 7'h47
    //   SEG_O     : a,b,c,d,e,f lit; g off      → 7'h40
    //   SEG_R     : e,f,g lit; a,b,c,d off      → 7'h0F  (lowercase 'r')
    localparam [6:0]
        SEG_BLANK = 7'h7F,
        SEG_A     = 7'h08,
        SEG_C     = 7'h46,
        SEG_D     = 7'h21,
        SEG_E     = 7'h06,
        SEG_K     = 7'h09,
        SEG_L     = 7'h47,
        SEG_O     = 7'h40,
        SEG_R     = 7'h0F;

    localparam [1:0]
        DISP_BLANK   = 2'b00,
        DISP_LOCKED  = 2'b01,
        DISP_CRACKED = 2'b10;

    always @(*) begin
        case (disp_state)

            // "  LOCKED"  (HEX7 = leftmost)
            DISP_LOCKED: begin
                HEX7 = SEG_BLANK;
                HEX6 = SEG_BLANK;
                HEX5 = SEG_L;
                HEX4 = SEG_O;
                HEX3 = SEG_C;
                HEX2 = SEG_K;
                HEX1 = SEG_E;
                HEX0 = SEG_D;
            end

            // "CRACKED "
            DISP_CRACKED: begin
                HEX7 = SEG_C;
                HEX6 = SEG_R;
                HEX5 = SEG_A;
                HEX4 = SEG_C;
                HEX3 = SEG_K;
                HEX2 = SEG_E;
                HEX1 = SEG_D;
                HEX0 = SEG_BLANK;
            end

            // "        "  (WAIT / ENCRYPT states — display blank)
            DISP_BLANK: begin
                HEX7 = SEG_BLANK;
                HEX6 = SEG_BLANK;
                HEX5 = SEG_BLANK;
                HEX4 = SEG_BLANK;
                HEX3 = SEG_BLANK;
                HEX2 = SEG_BLANK;
                HEX1 = SEG_BLANK;
                HEX0 = SEG_BLANK;
            end

            // "  ERROR "  (undefined / fault state)
            default: begin
                HEX7 = SEG_BLANK;
                HEX6 = SEG_BLANK;
                HEX5 = SEG_E;
                HEX4 = SEG_R;
                HEX3 = SEG_R;
                HEX2 = SEG_O;
                HEX1 = SEG_R;
                HEX0 = SEG_BLANK;
            end
        endcase
    end

endmodule
