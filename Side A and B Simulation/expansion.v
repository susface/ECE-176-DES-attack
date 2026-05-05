// expansion.v — DES E-box, 32->48 bit expansion (FIPS 46-3)
module expansion (
    input  [31:0] data_in,
    output [47:0] data_out
);
    // data_in[31] = bit 1, data_in[0] = bit 32

    assign data_out[47] = data_in[32-32]; // bit 32
    assign data_out[46] = data_in[32- 1]; // bit  1
    assign data_out[45] = data_in[32- 2];
    assign data_out[44] = data_in[32- 3];
    assign data_out[43] = data_in[32- 4];
    assign data_out[42] = data_in[32- 5];

    assign data_out[41] = data_in[32- 4];
    assign data_out[40] = data_in[32- 5];
    assign data_out[39] = data_in[32- 6];
    assign data_out[38] = data_in[32- 7];
    assign data_out[37] = data_in[32- 8];
    assign data_out[36] = data_in[32- 9];

    assign data_out[35] = data_in[32- 8];
    assign data_out[34] = data_in[32- 9];
    assign data_out[33] = data_in[32-10];
    assign data_out[32] = data_in[32-11];
    assign data_out[31] = data_in[32-12];
    assign data_out[30] = data_in[32-13];

    assign data_out[29] = data_in[32-12];
    assign data_out[28] = data_in[32-13];
    assign data_out[27] = data_in[32-14];
    assign data_out[26] = data_in[32-15];
    assign data_out[25] = data_in[32-16];
    assign data_out[24] = data_in[32-17];

    assign data_out[23] = data_in[32-16];
    assign data_out[22] = data_in[32-17];
    assign data_out[21] = data_in[32-18];
    assign data_out[20] = data_in[32-19];
    assign data_out[19] = data_in[32-20];
    assign data_out[18] = data_in[32-21];

    assign data_out[17] = data_in[32-20];
    assign data_out[16] = data_in[32-21];
    assign data_out[15] = data_in[32-22];
    assign data_out[14] = data_in[32-23];
    assign data_out[13] = data_in[32-24];
    assign data_out[12] = data_in[32-25];

    assign data_out[11] = data_in[32-24];
    assign data_out[10] = data_in[32-25];
    assign data_out[ 9] = data_in[32-26];
    assign data_out[ 8] = data_in[32-27];
    assign data_out[ 7] = data_in[32-28];
    assign data_out[ 6] = data_in[32-29];

    assign data_out[ 5] = data_in[32-28];
    assign data_out[ 4] = data_in[32-29];
    assign data_out[ 3] = data_in[32-30];
    assign data_out[ 2] = data_in[32-31];
    assign data_out[ 1] = data_in[32-32];
    assign data_out[ 0] = data_in[32- 1];

endmodule
