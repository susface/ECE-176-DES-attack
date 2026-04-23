`timescale 1ns / 1ps
module sideB_tb;

    reg clk, reset, start;
    reg [63:0] targetPlaintext;
    reg [63:0] receivedCiphertext;
    wire [63:0] cipherText;
    wire match;
    wire [63:0] key;

    sideBFSM uut(
        .clk(clk), .reset(reset), .start(start),
        .receivedPlaintext(targetPlaintext), .receivedCiphertext(receivedCiphertext),
        .match(match), .key(key),
        .startingKey(64'h0000000000000000), .endingKey(64'hFFFFFFFFFFFFFFF)
    );

    reg des_reset, des_start;
    wire des_done;
    des_datapath desCore(
        .clk(clk), .rst_n(des_reset), .start(des_start),
        .decrypt(1'b0),
        .plaintext(targetPlaintext), .key(64'h0000000000003222),
        .ciphertext(cipherText), .done(des_done)
    );

    always #10 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        des_reset = 0;
        #20;
        start = 0;
        targetPlaintext = 64'h4772616465204121; // "Grade A!"
        #10;
        des_start = 1;
        des_reset = 1;
        wait(des_done);
        receivedCiphertext = cipherText;
        reset = 0;
        #20;
        start = 1;
        wait(match);
        // Result should be 0x0000000000003222
        $display("Found key: 0x%h", key);
        $finish;
    end

    

endmodule