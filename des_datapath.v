// des_datapath.v — Iterative DES engine (1 round/cycle, 18 cycles total)
// FSM: IDLE -> ROUND (x16) -> DONE
module des_datapath (
    input         clk,
    input         rst_n,
    input         start,
    input         decrypt,  // 0 = encrypt, 1 = decrypt
    input  [63:0] plaintext,
    input  [63:0] key,
    output [63:0] ciphertext,
    output reg    done
);

    // FSM states
    localparam IDLE  = 2'd0,
               ROUND = 2'd1,
               DONE_ST = 2'd2;

    reg [1:0]  state;
    reg [3:0]  round_num;  // 0..15
    reg [31:0] L, R;

    // Key schedule — all 16 subkeys generated combinationally
    wire [47:0] sk [0:15];
    key_schedule u_ks (
        .key(key),
        .subkey1(sk[0]),   .subkey2(sk[1]),   .subkey3(sk[2]),   .subkey4(sk[3]),
        .subkey5(sk[4]),   .subkey6(sk[5]),   .subkey7(sk[6]),   .subkey8(sk[7]),
        .subkey9(sk[8]),   .subkey10(sk[9]),  .subkey11(sk[10]), .subkey12(sk[11]),
        .subkey13(sk[12]), .subkey14(sk[13]), .subkey15(sk[14]), .subkey16(sk[15])
    );

    // Initial permutation
    wire [63:0] ip_out;
    ip_block u_ip (.data_in(plaintext), .data_out(ip_out));

    // Feistel round (reused 16 times)
    // Decrypt uses subkeys in reverse order
    wire [3:0] sk_index = decrypt ? (4'd15 - round_num) : round_num;
    wire [31:0] L_next, R_next;
    des_round u_round (
        .L_in(L), .R_in(R),
        .subkey(sk[sk_index]),
        .L_out(L_next), .R_out(R_next)
    );

    // Final permutation — input is {R16, L16} (swap before FP)
    wire [63:0] fp_in = {R, L};
    wire [63:0] fp_out;
    fp_block u_fp (.data_in(fp_in), .data_out(fp_out));

    assign ciphertext = fp_out;

    // FSM
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= IDLE;
            round_num <= 4'd0;
            L         <= 32'd0;
            R         <= 32'd0;
            done      <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        L         <= ip_out[63:32];
                        R         <= ip_out[31:0];
                        round_num <= 4'd0;
                        state     <= ROUND;
                    end
                end

                ROUND: begin
                    L <= L_next;
                    R <= R_next;
                    if (round_num == 4'd15) begin
                        state <= DONE_ST;
                    end else begin
                        round_num <= round_num + 4'd1;
                    end
                end

                DONE_ST: begin
                    done  <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
