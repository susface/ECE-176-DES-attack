// To-do: state machine that has a reset and start and gets an input ciphertext plaintext pair somehow. After being reset and started, begins going through
// All possible keys and the received ciphertext to the generated ciphertext.
// Current things on my mind: This state machine needs to go through its states slower than the DES Core it has inside it. How do we slow down only its own clock?
// Maybe a counter?
// Also, the input and output on here is not currently final / still figuring out the hardware side of things.
// At the very least want to make it work for a testbench simulation.

// Again, just to reiterate, the current inputs and outputs are not final.
module sideBtop (
    input clk, reset, start,
    input [63:0] receivedPlaintext,
    input [63:0] receivedCiphertext,
    output match
);

    reg         rst_n, start, decrypt;
    reg  [63:0] plaintext, key;
    wire [63:0] ciphertext;
    wire        done;




endmodule