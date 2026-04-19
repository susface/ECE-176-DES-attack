`timescale 1ns / 1ps

// So this would work by feeding a clock signal and a plaintext/ciphertext pair to the sideB top module and then just wait until match = 1.

module sideB_tb;

    reg clk, reset, start;
    reg [63:0] receivedPlaintext;
    reg [63:0] receivedCiphertext;
    wire match;
    wire [63:0] key;

    sideBFSM uut(
        .clk(clk), .reset(reset), .start(start),
        .receivedPlaintext(receivedPlaintext), .receivedCiphertext(receivedCiphertext),
        .match(match), .key(key),
        .startingKey(64'h0000000000000000), .endingKey(64'hFFFFFFFFFFFFFFF)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 1;
        start = 0;
        receivedPlaintext = 64'h0123456789ABCDEF;
        receivedCiphertext = 64'h71e65200edec0724;
        #1000;
        start = 1;
        reset = 0;
        wait(match == 1);
        // Result should be 0000000000000022
        $displayh(key);
        $finish;
    end

    

endmodule