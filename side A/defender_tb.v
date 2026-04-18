`timescale 1ns / 1ps

module defender_tb;

    reg clk;
    reg rst_n;
    reg start;
    reg key_found;
    reg [55:0] found_key;

    wire tx;
    wire uart_busy;
    wire [63:0] ciphertext;
    wire ciphertext_valid;
    wire cracked;
    wire [1:0] disp_state;
    wire [7:0] LCD_DATA;
    wire LCD_EN, LCD_RS, LCD_RW, LCD_ON;

    // Matches defender_top default plaintext/key parameters.
    localparam [63:0] EXPECTED_CT = 64'hAD99C1C7E295C86E;
    localparam [55:0] CORRECT_K56 = 56'hFFFFFFFFFFFFFF;
    localparam [55:0] WRONG_K56   = 56'h0123456789ABCD;

    defender_top #(
        .CLK_FREQ(1000000), // smaller for faster UART sim
        .BAUD(115200)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .key_found(key_found),
        .found_key(found_key),
        .tx(tx),
        .uart_busy(uart_busy),
        .ciphertext(ciphertext),
        .ciphertext_valid(ciphertext_valid),
        .cracked(cracked),
        .disp_state(disp_state),
        .LCD_DATA(LCD_DATA),
        .LCD_EN(LCD_EN),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_ON(LCD_ON)
    );

    always #5 clk = ~clk;

    initial begin
        clk       = 1'b0;
        rst_n     = 1'b0;
        start     = 1'b0;
        key_found = 1'b0;
        found_key = 56'd0;

        #40;
        rst_n = 1'b1;

        // Start defender encryption.
        #20;
        start = 1'b1;
        #10;
        start = 1'b0;

        // Wait until ciphertext becomes valid.
        wait (ciphertext_valid == 1'b1);
        #20;

        $display("----------------------------------------------");
        $display("Ciphertext = %h", ciphertext);
        $display("Expected   = %h", EXPECTED_CT);
        if (ciphertext == EXPECTED_CT)
            $display("ENCRYPTION TEST PASSED");
        else
            $display("ENCRYPTION TEST FAILED");
        $display("----------------------------------------------");

        // First send a wrong key back from attacker. System should stay LOCKED.
        found_key = WRONG_K56;
        key_found = 1'b1;
        #10;
        key_found = 1'b0;

        repeat (40) @(posedge clk);
        if (cracked)
            $display("VERIFY TEST FAILED: wrong key should not crack");
        else
            $display("VERIFY WRONG-KEY TEST PASSED");

        // Now send the correct key back. System should move to CRACKED.
        found_key = CORRECT_K56;
        key_found = 1'b1;
        #10;
        key_found = 1'b0;

        wait (cracked == 1'b1);
        #20;
        $display("VERIFY CORRECT-KEY TEST PASSED");
        $display("disp_state = %b (expect 10 for cracked)", disp_state);

        #100;
        $finish;
    end

endmodule
