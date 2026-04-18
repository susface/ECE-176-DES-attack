`timescale 1ns / 1ps
// defender_tb.v — Side A (Defender) Integration Testbench
//
// Tests:
//   1. Encryption: checks ciphertext against known-good value.
//   2. False-positive verification: sends a wrong key via UART;
//      confirms the system stays LOCKED.
//   3. Correct-key verification: sends the real key via UART;
//      confirms the system reaches CRACKED.
//
// UART timing:
//   CLK_FREQ = 1_000_000 (sim parameter), BAUD = 115_200
//   CLKS_PER_BIT = 1_000_000 / 115_200 = 8 cycles per bit.
//   Testbench clock: always #5 → 10 ns period (100 MHz sim clock).
//   Each UART bit occupies 8 simulation clock cycles.
//
// Note: uart_rx_in is the serial line from Side B to Side A.
//   Idle state is 1'b1 (UART line idles high).
//   Byte framing: 1 start bit (0), 8 data bits LSB-first, 1 stop bit (1).
//   7 bytes are sent MSB-first: found_key[55:48] first, found_key[7:0] last.

module defender_tb;

    // ── DUT ports ─────────────────────────────────────────────────────────────
    reg  clk;
    reg  rst_n;
    reg  start;
    reg  uart_rx_in;   // serial line from Side B (replaces parallel key_found/found_key)

    wire       tx;
    wire       uart_busy;
    wire [63:0] ciphertext;
    wire        ciphertext_valid;
    wire        cracked;
    wire [1:0]  disp_state;
    wire [7:0]  LCD_DATA;
    wire        LCD_EN, LCD_RS, LCD_RW, LCD_ON;

    // ── Known-good constants ──────────────────────────────────────────────────
    // DEFENDER_KEY56 = 56'hFFFFFFFFFFFFFF → expand_key56_to_64 → 64'hFEFEFEFEFEFEFEFE
    // DES-encrypt("Grade A!" = 0x4772616465204121) with that key.
    localparam [63:0] EXPECTED_CT  = 64'hAD99C1C7E295C86E;
    localparam [55:0] CORRECT_K56  = 56'hFFFFFFFFFFFFFF;
    localparam [55:0] WRONG_K56    = 56'h0123456789ABCD;

    // CLKS_PER_BIT must match CLK_FREQ/BAUD inside the DUT.
    localparam integer CLKS_PER_BIT_TB = 1000000 / 115200;  // = 8

    // ── DUT instantiation ─────────────────────────────────────────────────────
    defender_top #(
        .CLK_FREQ(1000000),   // small value for fast UART sim timing
        .BAUD(115200)
    ) dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .start            (start),
        .uart_rx_in       (uart_rx_in),
        .tx               (tx),
        .uart_busy        (uart_busy),
        .ciphertext       (ciphertext),
        .ciphertext_valid (ciphertext_valid),
        .cracked          (cracked),
        .disp_state       (disp_state),
        .LCD_DATA         (LCD_DATA),
        .LCD_EN           (LCD_EN),
        .LCD_RS           (LCD_RS),
        .LCD_RW           (LCD_RW),
        .LCD_ON           (LCD_ON)
    );

    // ── Clock ─────────────────────────────────────────────────────────────────
    always #5 clk = ~clk;

    // ── UART helper tasks ─────────────────────────────────────────────────────
    // Send one byte (8N1, LSB-first) over uart_rx_in.
    task uart_send_byte;
        input [7:0] data;
        integer i;
        begin
            // Start bit
            uart_rx_in = 1'b0;
            repeat(CLKS_PER_BIT_TB) @(posedge clk);
            // 8 data bits, LSB first
            for (i = 0; i < 8; i = i + 1) begin
                uart_rx_in = data[i];
                repeat(CLKS_PER_BIT_TB) @(posedge clk);
            end
            // Stop bit
            uart_rx_in = 1'b1;
            repeat(CLKS_PER_BIT_TB) @(posedge clk);
        end
    endtask

    // Send a 56-bit key as 7 bytes, MSB-first.
    task uart_send_key56;
        input [55:0] key56;
        begin
            uart_send_byte(key56[55:48]);
            uart_send_byte(key56[47:40]);
            uart_send_byte(key56[39:32]);
            uart_send_byte(key56[31:24]);
            uart_send_byte(key56[23:16]);
            uart_send_byte(key56[15: 8]);
            uart_send_byte(key56[ 7: 0]);
        end
    endtask

    // ── Stimulus ──────────────────────────────────────────────────────────────
    initial begin
        clk        = 1'b0;
        rst_n      = 1'b0;
        start      = 1'b0;
        uart_rx_in = 1'b1;   // UART line idles high

        #40;
        rst_n = 1'b1;

        // ── Test 1: Encryption ────────────────────────────────────────────────
        #20;
        start = 1'b1;
        #10;
        start = 1'b0;

        wait (ciphertext_valid == 1'b1);
        @(posedge clk); #1;

        $display("----------------------------------------------");
        $display("Ciphertext = %h", ciphertext);
        $display("Expected   = %h", EXPECTED_CT);
        if (ciphertext == EXPECTED_CT)
            $display("ENCRYPTION TEST PASSED");
        else
            $display("ENCRYPTION TEST FAILED");
        $display("----------------------------------------------");

        // Small gap to ensure DUT is stable in S_LOCKED before we send.
        repeat(10) @(posedge clk);

        // ── Test 2: Wrong key — system must stay LOCKED ───────────────────────
        $display("Sending WRONG key via UART...");
        uart_send_key56(WRONG_K56);

        // Wait long enough for DUT to complete verification (~20 DES cycles +
        // a few FSM cycles) then confirm cracked is still deasserted.
        repeat(50) @(posedge clk);

        if (cracked)
            $display("VERIFY TEST FAILED: wrong key should not crack");
        else
            $display("VERIFY WRONG-KEY TEST PASSED");

        // ── Test 3: Correct key — system must reach CRACKED ───────────────────
        $display("Sending CORRECT key via UART...");
        uart_send_key56(CORRECT_K56);

        // Block until cracked asserts (or give up after a long timeout).
        wait (cracked == 1'b1);
        @(posedge clk); #1;

        $display("VERIFY CORRECT-KEY TEST PASSED");
        $display("disp_state = %b (expect 10 for CRACKED)", disp_state);

        #100;
        $finish;
    end

endmodule
