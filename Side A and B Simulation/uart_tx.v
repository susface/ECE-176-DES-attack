module uart_tx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,
    input  wire [7:0] data_in,
    output reg        tx,
    output reg        busy
);

    localparam CLKS_PER_BIT = CLK_FREQ / BAUD;

    reg [15:0] clk_count;
    reg [3:0]  bit_index;
    reg [9:0]  tx_shift;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx        <= 1'b1;
            busy      <= 1'b0;
            clk_count <= 0;
            bit_index <= 0;
            tx_shift  <= 10'b1111111111;
        end else begin

            if (start && !busy) begin
                tx_shift  <= {1'b1, data_in, 1'b0};
                busy      <= 1'b1;
                clk_count <= 0;
                bit_index <= 0;
                tx        <= 1'b0;
            end

            else if (busy) begin
                if (clk_count < CLKS_PER_BIT - 1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;

                    bit_index <= bit_index + 1;
                    tx <= tx_shift[bit_index + 1];

                    if (bit_index == 9) begin
                        busy <= 1'b0;
                        tx   <= 1'b1;
                    end
                end
            end

            else begin
                tx <= 1'b1;
            end
        end
    end

endmodule
