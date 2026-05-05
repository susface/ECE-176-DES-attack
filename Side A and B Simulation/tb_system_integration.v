`timescale 1ns / 1ps

module tb_system_integration();

    // Signals
    reg  clk;
    reg  rst_n;
    reg  start_defender;

    // The crossover wires between the two FPGA simulated instances
    wire def_tx_to_att_rx;
    wire att_tx_to_def_rx;

    // Observation outputs
    wire [63:0] def_ciphertext;
    wire        def_cracked;
    wire        att_match_led;

    // Defender Instantiation
    defender_top u_defender (
        .clk(clk),
        .rst_n(rst_n),
        .start(start_defender),
        .uart_rx(att_tx_to_def_rx), // Receives cracked 56-bit key from attacker
        .uart_tx(def_tx_to_att_rx), // Sends 64-bit ciphertext to attacker
        .ciphertext(def_ciphertext),
        .cracked(def_cracked)
    );

    // Attacker Instantiation
    attacker_top u_attacker (
        .clk(clk),
        .rst_n(rst_n),
        .uart_rx(def_tx_to_att_rx), // Receives 64-bit ciphertext from defender
        .uart_tx(att_tx_to_def_rx), // Sends 56-bit cracked key to defender
        .match_led(att_match_led)
    );

    // Clock Generation (50 MHz for DE2-115)
    // 50 MHz = 20ns period (toggles every 10ns)
    always #10 clk = ~clk;

    // Stimulus and Checking
    initial begin
        // 1. Initialize
        rst_n = 0;
        clk = 0;
        start_defender = 0;

        // 2. Hold reset for a bit, then release
        #100;
        rst_n = 1;
        #100;

        // 3. Kick off the defender
        $display("[%0t] Applying start pulse to defender...", $time);
        start_defender = 1;
        #20; 
        start_defender = 0;
        // - Defender encrypts and sends 8 bytes over UART.
        // - Attacker receives 8 bytes, starts brute force FSM.
        // - Attacker finds match, asserts LED, sends 7 bytes over UART.
        // - Defender receives 7 bytes, verifies, asserts 'cracked'.

        $display("[%0t] Waiting for attacker to find the key...", $time);
        @(att_match_led == 1'b1);
        $display("[%0t] Attacker found a match! UART TX should be starting...", $time);

        $display("[%0t] Waiting for defender to verify the key...", $time);
        @(def_cracked == 1'b1);
        $display("[%0t] SUCCESS! Defender verified the key and asserted CRACKED.", $time);

        #5000;
        $display("Simulation complete.");
        $stop;
    end

    initial begin
        #500000000; 
        $display("TIMEOUT: Simulation took too long.");
        $stop;
    end

endmodule