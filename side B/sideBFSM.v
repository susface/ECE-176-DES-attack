
module sideBFSM (
    input clk, reset, start,
    input [63:0] receivedPlaintext,
    input [63:0] receivedCiphertext,
    input [63:0] startingKey,
    input [63:0] endingKey,
    output reg match,
    output [63:0] key
);

    reg         rst, start_internal;
    wire [63:0] ciphertext;
    wire        done;
    reg [55:0] key_int;
    // Skip redundant parity bits
    assign key = {key_int[55:49], 1'b0, key_int[48:42], 1'b0, key_int[41:35], 1'b0, key_int[34:28], 1'b0, key_int[27:21], 1'b0, key_int[20:14], 1'b0, key_int[13:7], 1'b0, key_int[6:0], 1'b0};

    reg encryptionInProgress;

    des_datapath desEngine (
        .clk(clk), .rst_n(rst), .start(start_internal),
        .decrypt(1'b0),
        .plaintext(receivedPlaintext), .key(key),
        .ciphertext(ciphertext), .done(done)
    );

    always@(posedge clk) begin
        if(reset) begin
            key_int <= {startingKey[63:57], startingKey[55:49], startingKey[47:41], startingKey[39:33], startingKey[31:25], startingKey[23:17], startingKey[15:9], startingKey[7:1]};
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
                        if (key_int <= {endingKey[63:57], endingKey[55:49], endingKey[47:41], endingKey[39:33], endingKey[31:25], endingKey[23:17], endingKey[15:9], endingKey[7:1]}) begin
                            key_int <= key_int + 1;
                            rst <= 0;
                            encryptionInProgress <= 0;
                        end
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