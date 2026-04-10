// key_schedule.v — DES key schedule (FIPS 46-3)
// Generates all 16 48-bit subkeys combinationally from 64-bit key.
module key_schedule (
    input  [63:0] key,
    output [47:0] subkey1,  subkey2,  subkey3,  subkey4,
    output [47:0] subkey5,  subkey6,  subkey7,  subkey8,
    output [47:0] subkey9,  subkey10, subkey11, subkey12,
    output [47:0] subkey13, subkey14, subkey15, subkey16
);

    // PC-1: key[63] = bit 1, key[0] = bit 64

    wire [27:0] C0, D0;

    assign C0[27] = key[64-57];  assign C0[26] = key[64-49];  assign C0[25] = key[64-41];
    assign C0[24] = key[64-33];  assign C0[23] = key[64-25];  assign C0[22] = key[64-17];
    assign C0[21] = key[64- 9];  assign C0[20] = key[64- 1];  assign C0[19] = key[64-58];
    assign C0[18] = key[64-50];  assign C0[17] = key[64-42];  assign C0[16] = key[64-34];
    assign C0[15] = key[64-26];  assign C0[14] = key[64-18];  assign C0[13] = key[64-10];
    assign C0[12] = key[64- 2];  assign C0[11] = key[64-59];  assign C0[10] = key[64-51];
    assign C0[ 9] = key[64-43];  assign C0[ 8] = key[64-35];  assign C0[ 7] = key[64-27];
    assign C0[ 6] = key[64-19];  assign C0[ 5] = key[64-11];  assign C0[ 4] = key[64- 3];
    assign C0[ 3] = key[64-60];  assign C0[ 2] = key[64-52];  assign C0[ 1] = key[64-44];
    assign C0[ 0] = key[64-36];

    assign D0[27] = key[64-63];  assign D0[26] = key[64-55];  assign D0[25] = key[64-47];
    assign D0[24] = key[64-39];  assign D0[23] = key[64-31];  assign D0[22] = key[64-23];
    assign D0[21] = key[64-15];  assign D0[20] = key[64- 7];  assign D0[19] = key[64-62];
    assign D0[18] = key[64-54];  assign D0[17] = key[64-46];  assign D0[16] = key[64-38];
    assign D0[15] = key[64-30];  assign D0[14] = key[64-22];  assign D0[13] = key[64-14];
    assign D0[12] = key[64- 6];  assign D0[11] = key[64-61];  assign D0[10] = key[64-53];
    assign D0[ 9] = key[64-45];  assign D0[ 8] = key[64-37];  assign D0[ 7] = key[64-29];
    assign D0[ 6] = key[64-21];  assign D0[ 5] = key[64-13];  assign D0[ 4] = key[64- 5];
    assign D0[ 3] = key[64-28];  assign D0[ 2] = key[64-20];  assign D0[ 1] = key[64-12];
    assign D0[ 0] = key[64- 4];

    // Cumulative left-rotates of C0 and D0
    wire [27:0] C [1:16];
    wire [27:0] D [1:16];
    assign C[ 1] = {C0[26:0], C0[27]};                                              // <<< 1
    assign C[ 2] = {C0[25:0], C0[27:26]};                                           // <<< 2
    assign C[ 3] = {C0[23:0], C0[27:24]};                                           // <<< 4
    assign C[ 4] = {C0[21:0], C0[27:22]};                                           // <<< 6
    assign C[ 5] = {C0[19:0], C0[27:20]};                                           // <<< 8
    assign C[ 6] = {C0[17:0], C0[27:18]};                                           // <<< 10
    assign C[ 7] = {C0[15:0], C0[27:16]};                                           // <<< 12
    assign C[ 8] = {C0[13:0], C0[27:14]};                                           // <<< 14
    assign C[ 9] = {C0[12:0], C0[27:13]};                                           // <<< 15
    assign C[10] = {C0[10:0], C0[27:11]};                                           // <<< 17
    assign C[11] = {C0[ 8:0], C0[27: 9]};                                           // <<< 19
    assign C[12] = {C0[ 6:0], C0[27: 7]};                                           // <<< 21
    assign C[13] = {C0[ 4:0], C0[27: 5]};                                           // <<< 23
    assign C[14] = {C0[ 2:0], C0[27: 3]};                                           // <<< 25
    assign C[15] = {C0[ 0],   C0[27: 1]};                                           // <<< 27
    assign C[16] = C0;                                                               // <<< 28 = identity

    assign D[ 1] = {D0[26:0], D0[27]};
    assign D[ 2] = {D0[25:0], D0[27:26]};
    assign D[ 3] = {D0[23:0], D0[27:24]};
    assign D[ 4] = {D0[21:0], D0[27:22]};
    assign D[ 5] = {D0[19:0], D0[27:20]};
    assign D[ 6] = {D0[17:0], D0[27:18]};
    assign D[ 7] = {D0[15:0], D0[27:16]};
    assign D[ 8] = {D0[13:0], D0[27:14]};
    assign D[ 9] = {D0[12:0], D0[27:13]};
    assign D[10] = {D0[10:0], D0[27:11]};
    assign D[11] = {D0[ 8:0], D0[27: 9]};
    assign D[12] = {D0[ 6:0], D0[27: 7]};
    assign D[13] = {D0[ 4:0], D0[27: 5]};
    assign D[14] = {D0[ 2:0], D0[27: 3]};
    assign D[15] = {D0[ 0],   D0[27: 1]};
    assign D[16] = D0;

    // PC-2: select 48 bits from {C_n, D_n}
    wire [55:0] cd1  = {C[ 1], D[ 1]};
    wire [55:0] cd2  = {C[ 2], D[ 2]};
    wire [55:0] cd3  = {C[ 3], D[ 3]};
    wire [55:0] cd4  = {C[ 4], D[ 4]};
    wire [55:0] cd5  = {C[ 5], D[ 5]};
    wire [55:0] cd6  = {C[ 6], D[ 6]};
    wire [55:0] cd7  = {C[ 7], D[ 7]};
    wire [55:0] cd8  = {C[ 8], D[ 8]};
    wire [55:0] cd9  = {C[ 9], D[ 9]};
    wire [55:0] cd10 = {C[10], D[10]};
    wire [55:0] cd11 = {C[11], D[11]};
    wire [55:0] cd12 = {C[12], D[12]};
    wire [55:0] cd13 = {C[13], D[13]};
    wire [55:0] cd14 = {C[14], D[14]};
    wire [55:0] cd15 = {C[15], D[15]};
    wire [55:0] cd16 = {C[16], D[16]};


    assign subkey1  = pc2(cd1);
    assign subkey2  = pc2(cd2);
    assign subkey3  = pc2(cd3);
    assign subkey4  = pc2(cd4);
    assign subkey5  = pc2(cd5);
    assign subkey6  = pc2(cd6);
    assign subkey7  = pc2(cd7);
    assign subkey8  = pc2(cd8);
    assign subkey9  = pc2(cd9);
    assign subkey10 = pc2(cd10);
    assign subkey11 = pc2(cd11);
    assign subkey12 = pc2(cd12);
    assign subkey13 = pc2(cd13);
    assign subkey14 = pc2(cd14);
    assign subkey15 = pc2(cd15);
    assign subkey16 = pc2(cd16);

    // PC-2 function
    function [47:0] pc2;
        input [55:0] cd;
        begin
            pc2[47] = cd[56-14];
            pc2[46] = cd[56-17];
            pc2[45] = cd[56-11];
            pc2[44] = cd[56-24];
            pc2[43] = cd[56- 1];
            pc2[42] = cd[56- 5];

            pc2[41] = cd[56- 3];
            pc2[40] = cd[56-28];
            pc2[39] = cd[56-15];
            pc2[38] = cd[56- 6];
            pc2[37] = cd[56-21];
            pc2[36] = cd[56-10];

            pc2[35] = cd[56-23];
            pc2[34] = cd[56-19];
            pc2[33] = cd[56-12];
            pc2[32] = cd[56- 4];
            pc2[31] = cd[56-26];
            pc2[30] = cd[56- 8];

            pc2[29] = cd[56-16];
            pc2[28] = cd[56- 7];
            pc2[27] = cd[56-27];
            pc2[26] = cd[56-20];
            pc2[25] = cd[56-13];
            pc2[24] = cd[56- 2];

            pc2[23] = cd[56-41];
            pc2[22] = cd[56-52];
            pc2[21] = cd[56-31];
            pc2[20] = cd[56-37];
            pc2[19] = cd[56-47];
            pc2[18] = cd[56-55];

            pc2[17] = cd[56-30];
            pc2[16] = cd[56-40];
            pc2[15] = cd[56-51];
            pc2[14] = cd[56-45];
            pc2[13] = cd[56-33];
            pc2[12] = cd[56-48];

            pc2[11] = cd[56-44];
            pc2[10] = cd[56-49];
            pc2[ 9] = cd[56-39];
            pc2[ 8] = cd[56-56];
            pc2[ 7] = cd[56-34];
            pc2[ 6] = cd[56-53];

            pc2[ 5] = cd[56-46];
            pc2[ 4] = cd[56-42];
            pc2[ 3] = cd[56-50];
            pc2[ 2] = cd[56-36];
            pc2[ 1] = cd[56-29];
            pc2[ 0] = cd[56-32];
        end
    endfunction

endmodule
