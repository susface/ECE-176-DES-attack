// des_tb.v — NIST FIPS 46-3 Known Answer Test testbench
/*
`timescale 1ns / 1ps

module des_tb;

    reg         clk, rst_n, start, decrypt;
    reg  [63:0] plaintext, key;
    wire [63:0] ciphertext;
    wire        done;

    des_datapath uut (
        .clk(clk), .rst_n(rst_n), .start(start),
        .decrypt(decrypt),
        .plaintext(plaintext), .key(key),
        .ciphertext(ciphertext), .done(done)
    );

    // 50 MHz clock (20ns period)
    always #10 clk = ~clk;

    integer errors;
    integer test_num;

    // Run one encrypt or decrypt and check result
    task run_test;
        input [63:0] t_key;
        input [63:0] t_pt;
        input [63:0] t_expected_ct;
        input        t_decrypt;
        begin
            @(posedge clk);
            key       = t_key;
            plaintext = t_pt;
            decrypt   = t_decrypt;
            start     = 1'b1;
            @(posedge clk);
            start     = 1'b0;

            wait (done == 1'b1);
            @(posedge clk);

            if (ciphertext !== t_expected_ct) begin
                $display("FAIL test %0d: key=%h in=%h expected=%h got=%h",
                         test_num, t_key, t_pt, t_expected_ct, ciphertext);
                errors = errors + 1;
            end else begin
                $display("PASS test %0d", test_num);
            end
            test_num = test_num + 1;
        end
    endtask

    initial begin
        clk      = 0;
        rst_n    = 0;
        start    = 0;
        decrypt  = 0;
        errors   = 0;
        test_num = 1;

        // Reset
        #50;
        rst_n = 1;
        #20;

        // Encryption: Variable-Key tests (plaintext = 0000000000000000)

        run_test(64'h8001010101010101, 64'h0000000000000000, 64'h95A8D72813DAA94D, 0);

        run_test(64'h4001010101010101, 64'h0000000000000000, 64'h0EEC1487DD8C26D5, 0);
        run_test(64'h2001010101010101, 64'h0000000000000000, 64'h7AD16FFB79C45926, 0);
        run_test(64'h1001010101010101, 64'h0000000000000000, 64'hD3746294CA6A6CF3, 0);
        run_test(64'h0801010101010101, 64'h0000000000000000, 64'h809F5F873C1FD761, 0);
        run_test(64'h0401010101010101, 64'h0000000000000000, 64'hC02FAFFEC989D1FC, 0);
        run_test(64'h0201010101010101, 64'h0000000000000000, 64'h4615AA1D33E72F10, 0);
        run_test(64'h0180010101010101, 64'h0000000000000000, 64'h2055123350C00858, 0);
        run_test(64'h0140010101010101, 64'h0000000000000000, 64'hDF3B99D6577397C8, 0);
        run_test(64'h0120010101010101, 64'h0000000000000000, 64'h31FE17369B5288C9, 0);

        // Encryption: Variable-Plaintext tests (key = 0101010101010101)
        run_test(64'h0101010101010101, 64'h8000000000000000, 64'h95F8A5E5DD31D900, 0);
        run_test(64'h0101010101010101, 64'h4000000000000000, 64'hDD7F121CA5015619, 0);
        run_test(64'h0101010101010101, 64'h2000000000000000, 64'h2E8653104F3834EA, 0);
        run_test(64'h0101010101010101, 64'h1000000000000000, 64'h4BD388FF6CD81D4F, 0);
        run_test(64'h0101010101010101, 64'h0800000000000000, 64'h20B9E767B2FB1456, 0);
        run_test(64'h0101010101010101, 64'h0400000000000000, 64'h55579380D77138EF, 0);
        run_test(64'h0101010101010101, 64'h0200000000000000, 64'h6CC5DEFAAF04512F, 0);
        run_test(64'h0101010101010101, 64'h0100000000000000, 64'h0D9F279BA5D87260, 0);

        // Encryption: Permutation operation
        run_test(64'h1046913489980131, 64'h0000000000000000, 64'h88D55E54F54C97B4, 0);

        // Decryption tests (feed ciphertext in, expect plaintext out)
        run_test(64'h8001010101010101, 64'h95A8D72813DAA94D, 64'h0000000000000000, 1);
        run_test(64'h4001010101010101, 64'h0EEC1487DD8C26D5, 64'h0000000000000000, 1);
        run_test(64'h1046913489980131, 64'h88D55E54F54C97B4, 64'h0000000000000000, 1);

        // Summary
        #100;
        if (errors == 0)
            $display("ALL %0d TESTS PASSED", test_num - 1);
        else
            $display("FAILED: %0d errors out of %0d tests", errors, test_num - 1);

        $finish;
    end

endmodule

*/

