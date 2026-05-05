// sbox.v — All 8 DES S-boxes (FIPS 46-3)
// 48-bit input -> 32-bit output. Row = {b5,b0}, Col = {b4:b1}.
module sbox (
    input  [47:0] data_in,
    output [31:0] data_out
);

    // S1: data_in[47:42] → data_out[31:28]
    wire [5:0] s1_in = data_in[47:42];
    wire [1:0] s1_row = {s1_in[5], s1_in[0]};
    wire [3:0] s1_col = s1_in[4:1];
    reg  [3:0] s1_out;

    always @(*) begin
        case ({s1_row, s1_col})
            // Row 0
            6'd0:  s1_out = 4'd14; 6'd1:  s1_out = 4'd4;  6'd2:  s1_out = 4'd13; 6'd3:  s1_out = 4'd1;
            6'd4:  s1_out = 4'd2;  6'd5:  s1_out = 4'd15; 6'd6:  s1_out = 4'd11; 6'd7:  s1_out = 4'd8;
            6'd8:  s1_out = 4'd3;  6'd9:  s1_out = 4'd10; 6'd10: s1_out = 4'd6;  6'd11: s1_out = 4'd12;
            6'd12: s1_out = 4'd5;  6'd13: s1_out = 4'd9;  6'd14: s1_out = 4'd0;  6'd15: s1_out = 4'd7;
            // Row 1
            6'd16: s1_out = 4'd0;  6'd17: s1_out = 4'd15; 6'd18: s1_out = 4'd7;  6'd19: s1_out = 4'd4;
            6'd20: s1_out = 4'd14; 6'd21: s1_out = 4'd2;  6'd22: s1_out = 4'd13; 6'd23: s1_out = 4'd1;
            6'd24: s1_out = 4'd10; 6'd25: s1_out = 4'd6;  6'd26: s1_out = 4'd12; 6'd27: s1_out = 4'd11;
            6'd28: s1_out = 4'd9;  6'd29: s1_out = 4'd5;  6'd30: s1_out = 4'd3;  6'd31: s1_out = 4'd8;
            // Row 2
            6'd32: s1_out = 4'd4;  6'd33: s1_out = 4'd1;  6'd34: s1_out = 4'd14; 6'd35: s1_out = 4'd8;
            6'd36: s1_out = 4'd13; 6'd37: s1_out = 4'd6;  6'd38: s1_out = 4'd2;  6'd39: s1_out = 4'd11;
            6'd40: s1_out = 4'd15; 6'd41: s1_out = 4'd12; 6'd42: s1_out = 4'd9;  6'd43: s1_out = 4'd7;
            6'd44: s1_out = 4'd3;  6'd45: s1_out = 4'd10; 6'd46: s1_out = 4'd5;  6'd47: s1_out = 4'd0;
            // Row 3
            6'd48: s1_out = 4'd15; 6'd49: s1_out = 4'd12; 6'd50: s1_out = 4'd8;  6'd51: s1_out = 4'd2;
            6'd52: s1_out = 4'd4;  6'd53: s1_out = 4'd9;  6'd54: s1_out = 4'd1;  6'd55: s1_out = 4'd7;
            6'd56: s1_out = 4'd5;  6'd57: s1_out = 4'd11; 6'd58: s1_out = 4'd3;  6'd59: s1_out = 4'd14;
            6'd60: s1_out = 4'd10; 6'd61: s1_out = 4'd0;  6'd62: s1_out = 4'd6;  6'd63: s1_out = 4'd13;
            default: s1_out = 4'd0;
        endcase
    end

    // S2: data_in[41:36] → data_out[27:24]
    wire [5:0] s2_in = data_in[41:36];
    wire [1:0] s2_row = {s2_in[5], s2_in[0]};
    wire [3:0] s2_col = s2_in[4:1];
    reg  [3:0] s2_out;

    always @(*) begin
        case ({s2_row, s2_col})
            6'd0:  s2_out = 4'd15; 6'd1:  s2_out = 4'd1;  6'd2:  s2_out = 4'd8;  6'd3:  s2_out = 4'd14;
            6'd4:  s2_out = 4'd6;  6'd5:  s2_out = 4'd11; 6'd6:  s2_out = 4'd3;  6'd7:  s2_out = 4'd4;
            6'd8:  s2_out = 4'd9;  6'd9:  s2_out = 4'd7;  6'd10: s2_out = 4'd2;  6'd11: s2_out = 4'd13;
            6'd12: s2_out = 4'd12; 6'd13: s2_out = 4'd0;  6'd14: s2_out = 4'd5;  6'd15: s2_out = 4'd10;

            6'd16: s2_out = 4'd3;  6'd17: s2_out = 4'd13; 6'd18: s2_out = 4'd4;  6'd19: s2_out = 4'd7;
            6'd20: s2_out = 4'd15; 6'd21: s2_out = 4'd2;  6'd22: s2_out = 4'd8;  6'd23: s2_out = 4'd14;
            6'd24: s2_out = 4'd12; 6'd25: s2_out = 4'd0;  6'd26: s2_out = 4'd1;  6'd27: s2_out = 4'd10;
            6'd28: s2_out = 4'd6;  6'd29: s2_out = 4'd9;  6'd30: s2_out = 4'd11; 6'd31: s2_out = 4'd5;

            6'd32: s2_out = 4'd0;  6'd33: s2_out = 4'd14; 6'd34: s2_out = 4'd7;  6'd35: s2_out = 4'd11;
            6'd36: s2_out = 4'd10; 6'd37: s2_out = 4'd4;  6'd38: s2_out = 4'd13; 6'd39: s2_out = 4'd1;
            6'd40: s2_out = 4'd5;  6'd41: s2_out = 4'd8;  6'd42: s2_out = 4'd12; 6'd43: s2_out = 4'd6;
            6'd44: s2_out = 4'd9;  6'd45: s2_out = 4'd3;  6'd46: s2_out = 4'd2;  6'd47: s2_out = 4'd15;

            6'd48: s2_out = 4'd13; 6'd49: s2_out = 4'd8;  6'd50: s2_out = 4'd10; 6'd51: s2_out = 4'd1;
            6'd52: s2_out = 4'd3;  6'd53: s2_out = 4'd15; 6'd54: s2_out = 4'd4;  6'd55: s2_out = 4'd2;
            6'd56: s2_out = 4'd11; 6'd57: s2_out = 4'd6;  6'd58: s2_out = 4'd7;  6'd59: s2_out = 4'd12;
            6'd60: s2_out = 4'd0;  6'd61: s2_out = 4'd5;  6'd62: s2_out = 4'd14; 6'd63: s2_out = 4'd9;
            default: s2_out = 4'd0;
        endcase
    end

    // S3: data_in[35:30] → data_out[23:20]
    wire [5:0] s3_in = data_in[35:30];
    wire [1:0] s3_row = {s3_in[5], s3_in[0]};
    wire [3:0] s3_col = s3_in[4:1];
    reg  [3:0] s3_out;

    always @(*) begin
        case ({s3_row, s3_col})
            6'd0:  s3_out = 4'd10; 6'd1:  s3_out = 4'd0;  6'd2:  s3_out = 4'd9;  6'd3:  s3_out = 4'd14;
            6'd4:  s3_out = 4'd6;  6'd5:  s3_out = 4'd3;  6'd6:  s3_out = 4'd15; 6'd7:  s3_out = 4'd5;
            6'd8:  s3_out = 4'd1;  6'd9:  s3_out = 4'd13; 6'd10: s3_out = 4'd12; 6'd11: s3_out = 4'd7;
            6'd12: s3_out = 4'd11; 6'd13: s3_out = 4'd4;  6'd14: s3_out = 4'd2;  6'd15: s3_out = 4'd8;

            6'd16: s3_out = 4'd13; 6'd17: s3_out = 4'd7;  6'd18: s3_out = 4'd0;  6'd19: s3_out = 4'd9;
            6'd20: s3_out = 4'd3;  6'd21: s3_out = 4'd4;  6'd22: s3_out = 4'd6;  6'd23: s3_out = 4'd10;
            6'd24: s3_out = 4'd2;  6'd25: s3_out = 4'd8;  6'd26: s3_out = 4'd5;  6'd27: s3_out = 4'd14;
            6'd28: s3_out = 4'd12; 6'd29: s3_out = 4'd11; 6'd30: s3_out = 4'd15; 6'd31: s3_out = 4'd1;

            6'd32: s3_out = 4'd13; 6'd33: s3_out = 4'd6;  6'd34: s3_out = 4'd4;  6'd35: s3_out = 4'd9;
            6'd36: s3_out = 4'd8;  6'd37: s3_out = 4'd15; 6'd38: s3_out = 4'd3;  6'd39: s3_out = 4'd0;
            6'd40: s3_out = 4'd11; 6'd41: s3_out = 4'd1;  6'd42: s3_out = 4'd2;  6'd43: s3_out = 4'd12;
            6'd44: s3_out = 4'd5;  6'd45: s3_out = 4'd10; 6'd46: s3_out = 4'd14; 6'd47: s3_out = 4'd7;

            6'd48: s3_out = 4'd1;  6'd49: s3_out = 4'd10; 6'd50: s3_out = 4'd13; 6'd51: s3_out = 4'd0;
            6'd52: s3_out = 4'd6;  6'd53: s3_out = 4'd9;  6'd54: s3_out = 4'd8;  6'd55: s3_out = 4'd7;
            6'd56: s3_out = 4'd4;  6'd57: s3_out = 4'd15; 6'd58: s3_out = 4'd14; 6'd59: s3_out = 4'd3;
            6'd60: s3_out = 4'd11; 6'd61: s3_out = 4'd5;  6'd62: s3_out = 4'd2;  6'd63: s3_out = 4'd12;
            default: s3_out = 4'd0;
        endcase
    end

    // S4: data_in[29:24] → data_out[19:16]
    wire [5:0] s4_in = data_in[29:24];
    wire [1:0] s4_row = {s4_in[5], s4_in[0]};
    wire [3:0] s4_col = s4_in[4:1];
    reg  [3:0] s4_out;

    always @(*) begin
        case ({s4_row, s4_col})
            6'd0:  s4_out = 4'd7;  6'd1:  s4_out = 4'd13; 6'd2:  s4_out = 4'd14; 6'd3:  s4_out = 4'd3;
            6'd4:  s4_out = 4'd0;  6'd5:  s4_out = 4'd6;  6'd6:  s4_out = 4'd9;  6'd7:  s4_out = 4'd10;
            6'd8:  s4_out = 4'd1;  6'd9:  s4_out = 4'd2;  6'd10: s4_out = 4'd8;  6'd11: s4_out = 4'd5;
            6'd12: s4_out = 4'd11; 6'd13: s4_out = 4'd12; 6'd14: s4_out = 4'd4;  6'd15: s4_out = 4'd15;

            6'd16: s4_out = 4'd13; 6'd17: s4_out = 4'd8;  6'd18: s4_out = 4'd11; 6'd19: s4_out = 4'd5;
            6'd20: s4_out = 4'd6;  6'd21: s4_out = 4'd15; 6'd22: s4_out = 4'd0;  6'd23: s4_out = 4'd3;
            6'd24: s4_out = 4'd4;  6'd25: s4_out = 4'd7;  6'd26: s4_out = 4'd2;  6'd27: s4_out = 4'd12;
            6'd28: s4_out = 4'd1;  6'd29: s4_out = 4'd10; 6'd30: s4_out = 4'd14; 6'd31: s4_out = 4'd9;

            6'd32: s4_out = 4'd10; 6'd33: s4_out = 4'd6;  6'd34: s4_out = 4'd9;  6'd35: s4_out = 4'd0;
            6'd36: s4_out = 4'd12; 6'd37: s4_out = 4'd11; 6'd38: s4_out = 4'd7;  6'd39: s4_out = 4'd13;
            6'd40: s4_out = 4'd15; 6'd41: s4_out = 4'd1;  6'd42: s4_out = 4'd3;  6'd43: s4_out = 4'd14;
            6'd44: s4_out = 4'd5;  6'd45: s4_out = 4'd2;  6'd46: s4_out = 4'd8;  6'd47: s4_out = 4'd4;

            6'd48: s4_out = 4'd3;  6'd49: s4_out = 4'd15; 6'd50: s4_out = 4'd0;  6'd51: s4_out = 4'd6;
            6'd52: s4_out = 4'd10; 6'd53: s4_out = 4'd1;  6'd54: s4_out = 4'd13; 6'd55: s4_out = 4'd8;
            6'd56: s4_out = 4'd9;  6'd57: s4_out = 4'd4;  6'd58: s4_out = 4'd5;  6'd59: s4_out = 4'd11;
            6'd60: s4_out = 4'd12; 6'd61: s4_out = 4'd7;  6'd62: s4_out = 4'd2;  6'd63: s4_out = 4'd14;
            default: s4_out = 4'd0;
        endcase
    end

    // S5: data_in[23:18] → data_out[15:12]
    wire [5:0] s5_in = data_in[23:18];
    wire [1:0] s5_row = {s5_in[5], s5_in[0]};
    wire [3:0] s5_col = s5_in[4:1];
    reg  [3:0] s5_out;

    always @(*) begin
        case ({s5_row, s5_col})
            6'd0:  s5_out = 4'd2;  6'd1:  s5_out = 4'd12; 6'd2:  s5_out = 4'd4;  6'd3:  s5_out = 4'd1;
            6'd4:  s5_out = 4'd7;  6'd5:  s5_out = 4'd10; 6'd6:  s5_out = 4'd11; 6'd7:  s5_out = 4'd6;
            6'd8:  s5_out = 4'd8;  6'd9:  s5_out = 4'd5;  6'd10: s5_out = 4'd3;  6'd11: s5_out = 4'd15;
            6'd12: s5_out = 4'd13; 6'd13: s5_out = 4'd0;  6'd14: s5_out = 4'd14; 6'd15: s5_out = 4'd9;

            6'd16: s5_out = 4'd14; 6'd17: s5_out = 4'd11; 6'd18: s5_out = 4'd2;  6'd19: s5_out = 4'd12;
            6'd20: s5_out = 4'd4;  6'd21: s5_out = 4'd7;  6'd22: s5_out = 4'd13; 6'd23: s5_out = 4'd1;
            6'd24: s5_out = 4'd5;  6'd25: s5_out = 4'd0;  6'd26: s5_out = 4'd15; 6'd27: s5_out = 4'd10;
            6'd28: s5_out = 4'd3;  6'd29: s5_out = 4'd9;  6'd30: s5_out = 4'd8;  6'd31: s5_out = 4'd6;

            6'd32: s5_out = 4'd4;  6'd33: s5_out = 4'd2;  6'd34: s5_out = 4'd1;  6'd35: s5_out = 4'd11;
            6'd36: s5_out = 4'd10; 6'd37: s5_out = 4'd13; 6'd38: s5_out = 4'd7;  6'd39: s5_out = 4'd8;
            6'd40: s5_out = 4'd15; 6'd41: s5_out = 4'd9;  6'd42: s5_out = 4'd12; 6'd43: s5_out = 4'd5;
            6'd44: s5_out = 4'd6;  6'd45: s5_out = 4'd3;  6'd46: s5_out = 4'd0;  6'd47: s5_out = 4'd14;

            6'd48: s5_out = 4'd11; 6'd49: s5_out = 4'd8;  6'd50: s5_out = 4'd12; 6'd51: s5_out = 4'd7;
            6'd52: s5_out = 4'd1;  6'd53: s5_out = 4'd14; 6'd54: s5_out = 4'd2;  6'd55: s5_out = 4'd13;
            6'd56: s5_out = 4'd6;  6'd57: s5_out = 4'd15; 6'd58: s5_out = 4'd0;  6'd59: s5_out = 4'd9;
            6'd60: s5_out = 4'd10; 6'd61: s5_out = 4'd4;  6'd62: s5_out = 4'd5;  6'd63: s5_out = 4'd3;
            default: s5_out = 4'd0;
        endcase
    end

    // S6: data_in[17:12] → data_out[11:8]
    wire [5:0] s6_in = data_in[17:12];
    wire [1:0] s6_row = {s6_in[5], s6_in[0]};
    wire [3:0] s6_col = s6_in[4:1];
    reg  [3:0] s6_out;

    always @(*) begin
        case ({s6_row, s6_col})
            6'd0:  s6_out = 4'd12; 6'd1:  s6_out = 4'd1;  6'd2:  s6_out = 4'd10; 6'd3:  s6_out = 4'd15;
            6'd4:  s6_out = 4'd9;  6'd5:  s6_out = 4'd2;  6'd6:  s6_out = 4'd6;  6'd7:  s6_out = 4'd8;
            6'd8:  s6_out = 4'd0;  6'd9:  s6_out = 4'd13; 6'd10: s6_out = 4'd3;  6'd11: s6_out = 4'd4;
            6'd12: s6_out = 4'd14; 6'd13: s6_out = 4'd7;  6'd14: s6_out = 4'd5;  6'd15: s6_out = 4'd11;

            6'd16: s6_out = 4'd10; 6'd17: s6_out = 4'd15; 6'd18: s6_out = 4'd4;  6'd19: s6_out = 4'd2;
            6'd20: s6_out = 4'd7;  6'd21: s6_out = 4'd12; 6'd22: s6_out = 4'd9;  6'd23: s6_out = 4'd5;
            6'd24: s6_out = 4'd6;  6'd25: s6_out = 4'd1;  6'd26: s6_out = 4'd13; 6'd27: s6_out = 4'd14;
            6'd28: s6_out = 4'd0;  6'd29: s6_out = 4'd11; 6'd30: s6_out = 4'd3;  6'd31: s6_out = 4'd8;

            6'd32: s6_out = 4'd9;  6'd33: s6_out = 4'd14; 6'd34: s6_out = 4'd15; 6'd35: s6_out = 4'd5;
            6'd36: s6_out = 4'd2;  6'd37: s6_out = 4'd8;  6'd38: s6_out = 4'd12; 6'd39: s6_out = 4'd3;
            6'd40: s6_out = 4'd7;  6'd41: s6_out = 4'd0;  6'd42: s6_out = 4'd4;  6'd43: s6_out = 4'd10;
            6'd44: s6_out = 4'd1;  6'd45: s6_out = 4'd13; 6'd46: s6_out = 4'd11; 6'd47: s6_out = 4'd6;

            6'd48: s6_out = 4'd4;  6'd49: s6_out = 4'd3;  6'd50: s6_out = 4'd2;  6'd51: s6_out = 4'd12;
            6'd52: s6_out = 4'd9;  6'd53: s6_out = 4'd5;  6'd54: s6_out = 4'd15; 6'd55: s6_out = 4'd10;
            6'd56: s6_out = 4'd11; 6'd57: s6_out = 4'd14; 6'd58: s6_out = 4'd1;  6'd59: s6_out = 4'd7;
            6'd60: s6_out = 4'd6;  6'd61: s6_out = 4'd0;  6'd62: s6_out = 4'd8;  6'd63: s6_out = 4'd13;
            default: s6_out = 4'd0;
        endcase
    end

    // S7: data_in[11:6] → data_out[7:4]
    wire [5:0] s7_in = data_in[11:6];
    wire [1:0] s7_row = {s7_in[5], s7_in[0]};
    wire [3:0] s7_col = s7_in[4:1];
    reg  [3:0] s7_out;

    always @(*) begin
        case ({s7_row, s7_col})
            6'd0:  s7_out = 4'd4;  6'd1:  s7_out = 4'd11; 6'd2:  s7_out = 4'd2;  6'd3:  s7_out = 4'd14;
            6'd4:  s7_out = 4'd15; 6'd5:  s7_out = 4'd0;  6'd6:  s7_out = 4'd8;  6'd7:  s7_out = 4'd13;
            6'd8:  s7_out = 4'd3;  6'd9:  s7_out = 4'd12; 6'd10: s7_out = 4'd9;  6'd11: s7_out = 4'd7;
            6'd12: s7_out = 4'd5;  6'd13: s7_out = 4'd10; 6'd14: s7_out = 4'd6;  6'd15: s7_out = 4'd1;

            6'd16: s7_out = 4'd13; 6'd17: s7_out = 4'd0;  6'd18: s7_out = 4'd11; 6'd19: s7_out = 4'd7;
            6'd20: s7_out = 4'd4;  6'd21: s7_out = 4'd9;  6'd22: s7_out = 4'd1;  6'd23: s7_out = 4'd10;
            6'd24: s7_out = 4'd14; 6'd25: s7_out = 4'd3;  6'd26: s7_out = 4'd5;  6'd27: s7_out = 4'd12;
            6'd28: s7_out = 4'd2;  6'd29: s7_out = 4'd15; 6'd30: s7_out = 4'd8;  6'd31: s7_out = 4'd6;

            6'd32: s7_out = 4'd1;  6'd33: s7_out = 4'd4;  6'd34: s7_out = 4'd11; 6'd35: s7_out = 4'd13;
            6'd36: s7_out = 4'd12; 6'd37: s7_out = 4'd3;  6'd38: s7_out = 4'd7;  6'd39: s7_out = 4'd14;
            6'd40: s7_out = 4'd10; 6'd41: s7_out = 4'd15; 6'd42: s7_out = 4'd6;  6'd43: s7_out = 4'd8;
            6'd44: s7_out = 4'd0;  6'd45: s7_out = 4'd5;  6'd46: s7_out = 4'd9;  6'd47: s7_out = 4'd2;

            6'd48: s7_out = 4'd6;  6'd49: s7_out = 4'd11; 6'd50: s7_out = 4'd13; 6'd51: s7_out = 4'd8;
            6'd52: s7_out = 4'd1;  6'd53: s7_out = 4'd4;  6'd54: s7_out = 4'd10; 6'd55: s7_out = 4'd7;
            6'd56: s7_out = 4'd9;  6'd57: s7_out = 4'd5;  6'd58: s7_out = 4'd0;  6'd59: s7_out = 4'd15;
            6'd60: s7_out = 4'd14; 6'd61: s7_out = 4'd2;  6'd62: s7_out = 4'd3;  6'd63: s7_out = 4'd12;
            default: s7_out = 4'd0;
        endcase
    end

    // S8: data_in[5:0] → data_out[3:0]
    wire [5:0] s8_in = data_in[5:0];
    wire [1:0] s8_row = {s8_in[5], s8_in[0]};
    wire [3:0] s8_col = s8_in[4:1];
    reg  [3:0] s8_out;

    always @(*) begin
        case ({s8_row, s8_col})
            6'd0:  s8_out = 4'd13; 6'd1:  s8_out = 4'd2;  6'd2:  s8_out = 4'd8;  6'd3:  s8_out = 4'd4;
            6'd4:  s8_out = 4'd6;  6'd5:  s8_out = 4'd15; 6'd6:  s8_out = 4'd11; 6'd7:  s8_out = 4'd1;
            6'd8:  s8_out = 4'd10; 6'd9:  s8_out = 4'd9;  6'd10: s8_out = 4'd3;  6'd11: s8_out = 4'd14;
            6'd12: s8_out = 4'd5;  6'd13: s8_out = 4'd0;  6'd14: s8_out = 4'd12; 6'd15: s8_out = 4'd7;

            6'd16: s8_out = 4'd1;  6'd17: s8_out = 4'd15; 6'd18: s8_out = 4'd13; 6'd19: s8_out = 4'd8;
            6'd20: s8_out = 4'd10; 6'd21: s8_out = 4'd3;  6'd22: s8_out = 4'd7;  6'd23: s8_out = 4'd4;
            6'd24: s8_out = 4'd12; 6'd25: s8_out = 4'd5;  6'd26: s8_out = 4'd6;  6'd27: s8_out = 4'd11;
            6'd28: s8_out = 4'd0;  6'd29: s8_out = 4'd14; 6'd30: s8_out = 4'd9;  6'd31: s8_out = 4'd2;

            6'd32: s8_out = 4'd7;  6'd33: s8_out = 4'd11; 6'd34: s8_out = 4'd4;  6'd35: s8_out = 4'd1;
            6'd36: s8_out = 4'd9;  6'd37: s8_out = 4'd12; 6'd38: s8_out = 4'd14; 6'd39: s8_out = 4'd2;
            6'd40: s8_out = 4'd0;  6'd41: s8_out = 4'd6;  6'd42: s8_out = 4'd10; 6'd43: s8_out = 4'd13;
            6'd44: s8_out = 4'd15; 6'd45: s8_out = 4'd3;  6'd46: s8_out = 4'd5;  6'd47: s8_out = 4'd8;

            6'd48: s8_out = 4'd2;  6'd49: s8_out = 4'd1;  6'd50: s8_out = 4'd14; 6'd51: s8_out = 4'd7;
            6'd52: s8_out = 4'd4;  6'd53: s8_out = 4'd10; 6'd54: s8_out = 4'd8;  6'd55: s8_out = 4'd13;
            6'd56: s8_out = 4'd15; 6'd57: s8_out = 4'd12; 6'd58: s8_out = 4'd9;  6'd59: s8_out = 4'd0;
            6'd60: s8_out = 4'd3;  6'd61: s8_out = 4'd5;  6'd62: s8_out = 4'd6;  6'd63: s8_out = 4'd11;
            default: s8_out = 4'd0;
        endcase
    end

    // Concatenate all S-box outputs
    assign data_out = {s1_out, s2_out, s3_out, s4_out,
                       s5_out, s6_out, s7_out, s8_out};

endmodule
