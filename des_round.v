// des_round.v — Single DES Feistel round
module des_round (
    input  [31:0] L_in,
    input  [31:0] R_in,
    input  [47:0] subkey,
    output [31:0] L_out,
    output [31:0] R_out
);

    wire [47:0] r_expanded;
    wire [47:0] xor_out;
    wire [31:0] sbox_out;
    wire [31:0] f_out;

    expansion u_exp  (.data_in(R_in),    .data_out(r_expanded));
    assign xor_out = r_expanded ^ subkey;
    sbox      u_sbox (.data_in(xor_out), .data_out(sbox_out));
    pbox      u_pbox (.data_in(sbox_out),.data_out(f_out));

    assign L_out = R_in;
    assign R_out = L_in ^ f_out;

endmodule
