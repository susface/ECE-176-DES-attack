// To-do: state machine that has a reset and start and gets an input ciphertext plaintext pair somehow. After being reset and started, begins going through
// All possible keys and the received ciphertext to the generated ciphertext.
// Current things on my mind: This state machine needs to go through its states slower than the DES Core it has inside it. How do we slow down only its own clock?
// Maybe a counter?
// Also, the input and output on here is not currently final / still figuring out the hardware side of things.
// At the very least want to make it work for a testbench simulation.

// Again, just to reiterate, the current inputs and outputs are not final.
module sideBFSM (
    input clk, reset, start,
    input [63:0] receivedPlaintext,
    input [63:0] receivedCiphertext,
    output reg match,
    output reg [63:0] key
);

    reg         rst, start_internal;
    wire [63:0] ciphertext;
    wire        done;

    reg encryptionInProgress;

    des_datapath desEngine (
        .clk(clk), .rst_n(rst), .start(start_internal),
        .decrypt(1'b0),
        .plaintext(receivedPlaintext), .key(key),
        .ciphertext(ciphertext), .done(done)
    );

    always@(negedge clk) begin
        if(reset) begin
            key <= 0;
            rst <= 0;
            encryptionInProgress <= 0;
            start_internal <= 0;
            match <= 0;
        end

        else begin
            if(start && !encryptionInProgress && rst) begin
                start_internal <= 1;
                encryptionInProgress <= 1;
            end
            else if(encryptionInProgress) begin
                start_internal <= 0;
                if (done) begin
                    if(ciphertext == receivedCiphertext) begin
                        match <= 1;
                        encryptionInProgress <= 0;
                    end
                    else begin
                        key <= key + 1;
                        rst <= 0;
                        encryptionInProgress <= 0;
                    end
                end else begin
                    rst <= 1;
                end
            end else begin
                rst <= 1;
            end

        end
    end

endmodule