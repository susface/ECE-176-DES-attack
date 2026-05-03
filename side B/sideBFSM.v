// This module is authored by Jordan David Reynolds

module sideBFSM (
    input clk, reset_n, start,
    input [63:0] receivedPlaintext,
    input [63:0] receivedCiphertext,
    output reg match,
    output [63:0] key
);

    localparam IDLE = 3'b000;
    localparam RESET_PULSE = 3'b001;
    localparam ENCRYPTION_PULSE = 3'b010;
    localparam ENCRYPTING = 3'b011;
    localparam ENCRYPTION_DONE = 3'b100;
    localparam MATCH_FOUND = 3'b101;


    parameter startingKey = 64'h0000000000000000,
    endingKey = 64'hFFFFFFFFFFFFFFFF;

    reg [2:0] currentState;
    reg [2:0] nextState;
    reg         rst_n, start_internal;
    wire [63:0] ciphertext;
    wire        done;
    reg [55:0] key_int;
    // Skip redundant parity bits
    assign key = {key_int[55:49], 1'b0, key_int[48:42], 1'b0, key_int[41:35], 1'b0, key_int[34:28], 1'b0, key_int[27:21], 1'b0, key_int[20:14], 1'b0, key_int[13:7], 1'b0, key_int[6:0], 1'b0};


    des_datapath desEngine (
        .clk(clk), .rst_n(rst_n), .start(start_internal),
        .decrypt(1'b0),
        .plaintext(receivedPlaintext), .key(key),
        .ciphertext(ciphertext), .done(done)
    );

    always @(posedge clk or negedge reset_n) begin
        //$display(currentState);
        if (!reset_n) begin 
            currentState <= IDLE;
            key_int <= {startingKey[63:57], startingKey[55:49], startingKey[47:41], startingKey[39:33], startingKey[31:25], startingKey[23:17], startingKey[15:9], startingKey[7:1]};
        end
        else begin
        currentState <= nextState;
        if (currentState == ENCRYPTION_DONE && ciphertext != receivedCiphertext) begin
                if (key_int < {endingKey[63:57], endingKey[55:49], endingKey[47:41], 
                               endingKey[39:33], endingKey[31:25], endingKey[23:17], 
                               endingKey[15:9], endingKey[7:1]}) begin
                    key_int <= key_int + 1;
                end
            end
        end
    end

    always @(*) begin
        nextState = currentState;
        start_internal = 0;
        rst_n = 1;
        match = 0;

        case (currentState)
        IDLE : begin
            if (start) nextState = RESET_PULSE;
            else nextState = IDLE;
        end

        RESET_PULSE : begin
            rst_n = 0;
            nextState = ENCRYPTION_PULSE;
        end

        ENCRYPTION_PULSE : begin
            rst_n = 1;
            start_internal = 1;
            nextState = ENCRYPTING;
        end

        ENCRYPTING : begin
            start_internal = 0;
            if (done) begin
                nextState = ENCRYPTION_DONE;
            end
            else begin
                nextState = ENCRYPTING;
            end
        end

        ENCRYPTION_DONE : begin
            //$displayh(key);
            if (ciphertext == receivedCiphertext) begin
                nextState = MATCH_FOUND;
            end
            else begin
                nextState = RESET_PULSE;
            end
            end

        MATCH_FOUND : begin
            match = 1;
            nextState = MATCH_FOUND;
        end

        default : begin
            nextState = IDLE;
        end

        endcase
    end
endmodule
