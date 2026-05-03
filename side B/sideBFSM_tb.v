// This module is authored by Jordan David Reynolds

`timescale 1ns / 1ps
module sideB_tb;

    reg clk, reset_n, start;
    reg [63:0] targetPlaintext;
    reg [63:0] receivedCiphertext;
    wire [63:0] cipherText;
    wire match;
    wire [63:0] key;

    sideBFSM #(.startingKey(64'h0000000000000000), .endingKey(64'hFFFFFFFFFFFFFFFF)) uut (
        .clk(clk), .reset_n(reset_n), .start(start),
        .receivedPlaintext(targetPlaintext), .receivedCiphertext(receivedCiphertext),
        .match(match), .key(key)
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
        // Initial values, reset DES Core and SideBFSM
        clk = 0;
        reset_n = 0;
        des_reset = 0;
        start = 0;
        des_start = 0;
        targetPlaintext = 64'h4772616465204121; // "Grade A!"
        
        #20;
        
        // Release DES Core reset and pulse start
        des_reset = 1; 
        des_start = 1;
        #20; 
        des_start = 0; 
        
        // Wait for DES to finish encrypting the target
        @(des_done);
        receivedCiphertext = cipherText;
        
        // Release FSM reset and pulse start to begin brute force
        reset_n = 1;
        #20;
        start = 1;
        #20;
        start = 0;
        
        // Wait for the FSM to find the key
        @(match);
        
        // Result should be 0x0000000000003222
        $display("Found key: 0x%h", key);
        $finish;
    end

    

endmodule