module defender_top #(
    parameter [63:0] PLAINTEXT_FIXED = 64'h4772616465204121, // "Grade A!"
    parameter [55:0] DEFENDER_KEY56  = 56'hFFFFFFFFFFFFFF,
    parameter integer CLK_FREQ       = 50000000,
    parameter integer BAUD           = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,

    // Candidate key returned by attacker side
    input  wire        key_found,
    input  wire [55:0] found_key,

    // Optional serial backup link
    output wire        tx,
    output wire        uart_busy,

    // Useful raw outputs for the planned parallel board link
    output wire [63:0] ciphertext,
    output wire        ciphertext_valid,
    output wire        cracked,

    // State outputs for your own 7-seg display driver
    output reg  [1:0]  disp_state,

    // LCD outputs (for lcd_ctrl_a.v)
    output wire [7:0]  LCD_DATA,
    output wire        LCD_EN,
    output wire        LCD_RS,
    output wire        LCD_RW,
    output wire        LCD_ON
);

    localparam [2:0]
        S_IDLE    = 3'd0,
        S_ENC_PLS = 3'd1,
        S_ENCRYPT = 3'd2,
        S_LOCKED  = 3'd3,
        S_VFY_PLS = 3'd4,
        S_VERIFY  = 3'd5,
        S_CRACKED = 3'd6;

    localparam [1:0]
        DISP_BLANK   = 2'b00,
        DISP_LOCKED  = 2'b01,
        DISP_CRACKED = 2'b10;

    reg [2:0] state;
    reg       enc_start;
    reg       verify_start;
    reg [1:0] lcd_state;

    wire [63:0] defender_key64 = expand_key56_to_64(DEFENDER_KEY56);
    wire [63:0] found_key64    = expand_key56_to_64(found_key);

    wire [63:0] enc_ciphertext;
    wire        enc_done;

    wire [63:0] verify_ciphertext;
    wire        verify_done;

    reg  [63:0] ciphertext_reg;
    wire        verify_match;

    // Main DES engine: creates the ciphertext to defend.
    des_datapath u_encrypt (
        .clk(clk),
        .rst_n(rst_n),
        .start(enc_start),
        .decrypt(1'b0),
        .plaintext(PLAINTEXT_FIXED),
        .key(defender_key64),
        .ciphertext(enc_ciphertext),
        .done(enc_done)
    );

    // Verifier DES engine: re-encrypts using attacker-provided key.
    des_datapath u_verify (
        .clk(clk),
        .rst_n(rst_n),
        .start(verify_start),
        .decrypt(1'b0),
        .plaintext(PLAINTEXT_FIXED),
        .key(found_key64),
        .ciphertext(verify_ciphertext),
        .done(verify_done)
    );

    comparator u_cmp (
        .a(ciphertext_reg),
        .b(verify_ciphertext),
        .match(verify_match)
    );

    lcd_ctrl_a u_lcd (
        .clk(clk),
        .rst_n(rst_n),
        .lcd_state(lcd_state),
        .LCD_DATA(LCD_DATA),
        .LCD_EN(LCD_EN),
        .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW),
        .LCD_ON(LCD_ON)
    );

    assign ciphertext       = ciphertext_reg;
    assign ciphertext_valid = (state == S_LOCKED) || (state == S_VFY_PLS) || (state == S_VERIFY) || (state == S_CRACKED);
    assign cracked          = (state == S_CRACKED);

    // Simple one-shot UART sender for the finished ciphertext.
    reg        send_active;
    reg [2:0]  send_idx;
    reg        uart_start;
    reg [7:0]  uart_data;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) u_uart (
        .clk(clk),
        .rst_n(rst_n),
        .start(uart_start),
        .data_in(uart_data),
        .tx(tx),
        .busy(uart_busy)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_IDLE;
            enc_start      <= 1'b0;
            verify_start   <= 1'b0;
            ciphertext_reg <= 64'd0;
            disp_state     <= DISP_BLANK;
            lcd_state      <= DISP_BLANK;
            send_active    <= 1'b0;
            send_idx       <= 3'd0;
            uart_start     <= 1'b0;
            uart_data      <= 8'd0;
        end else begin
            enc_start    <= 1'b0;
            verify_start <= 1'b0;
            uart_start   <= 1'b0;

            // UART byte scheduler: send ciphertext once after encryption completes.
            if (send_active && !uart_busy) begin
                case (send_idx)
                    3'd0: uart_data <= ciphertext_reg[63:56];
                    3'd1: uart_data <= ciphertext_reg[55:48];
                    3'd2: uart_data <= ciphertext_reg[47:40];
                    3'd3: uart_data <= ciphertext_reg[39:32];
                    3'd4: uart_data <= ciphertext_reg[31:24];
                    3'd5: uart_data <= ciphertext_reg[23:16];
                    3'd6: uart_data <= ciphertext_reg[15:8];
                    default: uart_data <= ciphertext_reg[7:0];
                endcase
                uart_start <= 1'b1;
                if (send_idx == 3'd7) begin
                    send_active <= 1'b0;
                end else begin
                    send_idx <= send_idx + 3'd1;
                end
            end

            case (state)
                S_IDLE: begin
                    disp_state <= DISP_BLANK;
                    lcd_state  <= DISP_BLANK;
                    if (start)
                        state <= S_ENC_PLS;
                end

                S_ENC_PLS: begin
                    enc_start <= 1'b1;
                    state     <= S_ENCRYPT;
                end

                S_ENCRYPT: begin
                    if (enc_done) begin
                        ciphertext_reg <= enc_ciphertext;
                        disp_state     <= DISP_LOCKED;
                        lcd_state      <= DISP_LOCKED;
                        send_active    <= 1'b1;
                        send_idx       <= 3'd0;
                        state          <= S_LOCKED;
                    end
                end

                S_LOCKED: begin
                    disp_state <= DISP_LOCKED;
                    lcd_state  <= DISP_LOCKED;
                    if (key_found)
                        state <= S_VFY_PLS;
                end

                S_VFY_PLS: begin
                    verify_start <= 1'b1;
                    state        <= S_VERIFY;
                end

                S_VERIFY: begin
                    if (verify_done) begin
                        if (verify_match) begin
                            disp_state <= DISP_CRACKED;
                            lcd_state  <= DISP_CRACKED;
                            state      <= S_CRACKED;
                        end else begin
                            state <= S_LOCKED;
                        end
                    end
                end

                S_CRACKED: begin
                    disp_state <= DISP_CRACKED;
                    lcd_state  <= DISP_CRACKED;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // Expand 56-bit key material to 64 bits by inserting odd parity bits.
    function [63:0] expand_key56_to_64;
        input [55:0] key56;
        integer i;
        reg [6:0] seven;
        reg parity;
        begin
            for (i = 0; i < 8; i = i + 1) begin
                seven  = key56[55 - i*7 -: 7];
                parity = ~(^seven); // odd parity bit
                expand_key56_to_64[63 - i*8 -: 8] = {seven, parity};
            end
        end
    endfunction

endmodule
