// fp_block.v — DES Final Permutation / IP-inverse (FIPS 46-3)
module fp_block (
    input  [63:0] data_in,
    output [63:0] data_out
);

    assign data_out[63] = data_in[64-40];
    assign data_out[62] = data_in[64- 8];
    assign data_out[61] = data_in[64-48];
    assign data_out[60] = data_in[64-16];
    assign data_out[59] = data_in[64-56];
    assign data_out[58] = data_in[64-24];
    assign data_out[57] = data_in[64-64];
    assign data_out[56] = data_in[64-32];

    assign data_out[55] = data_in[64-39];
    assign data_out[54] = data_in[64- 7];
    assign data_out[53] = data_in[64-47];
    assign data_out[52] = data_in[64-15];
    assign data_out[51] = data_in[64-55];
    assign data_out[50] = data_in[64-23];
    assign data_out[49] = data_in[64-63];
    assign data_out[48] = data_in[64-31];

    assign data_out[47] = data_in[64-38];
    assign data_out[46] = data_in[64- 6];
    assign data_out[45] = data_in[64-46];
    assign data_out[44] = data_in[64-14];
    assign data_out[43] = data_in[64-54];
    assign data_out[42] = data_in[64-22];
    assign data_out[41] = data_in[64-62];
    assign data_out[40] = data_in[64-30];

    assign data_out[39] = data_in[64-37];
    assign data_out[38] = data_in[64- 5];
    assign data_out[37] = data_in[64-45];
    assign data_out[36] = data_in[64-13];
    assign data_out[35] = data_in[64-53];
    assign data_out[34] = data_in[64-21];
    assign data_out[33] = data_in[64-61];
    assign data_out[32] = data_in[64-29];

    assign data_out[31] = data_in[64-36];
    assign data_out[30] = data_in[64- 4];
    assign data_out[29] = data_in[64-44];
    assign data_out[28] = data_in[64-12];
    assign data_out[27] = data_in[64-52];
    assign data_out[26] = data_in[64-20];
    assign data_out[25] = data_in[64-60];
    assign data_out[24] = data_in[64-28];

    assign data_out[23] = data_in[64-35];
    assign data_out[22] = data_in[64- 3];
    assign data_out[21] = data_in[64-43];
    assign data_out[20] = data_in[64-11];
    assign data_out[19] = data_in[64-51];
    assign data_out[18] = data_in[64-19];
    assign data_out[17] = data_in[64-59];
    assign data_out[16] = data_in[64-27];

    assign data_out[15] = data_in[64-34];
    assign data_out[14] = data_in[64- 2];
    assign data_out[13] = data_in[64-42];
    assign data_out[12] = data_in[64-10];
    assign data_out[11] = data_in[64-50];
    assign data_out[10] = data_in[64-18];
    assign data_out[ 9] = data_in[64-58];
    assign data_out[ 8] = data_in[64-26];

    assign data_out[ 7] = data_in[64-33];
    assign data_out[ 6] = data_in[64- 1];
    assign data_out[ 5] = data_in[64-41];
    assign data_out[ 4] = data_in[64- 9];
    assign data_out[ 3] = data_in[64-49];
    assign data_out[ 2] = data_in[64-17];
    assign data_out[ 1] = data_in[64-57];
    assign data_out[ 0] = data_in[64-25];

endmodule
