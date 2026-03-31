// comparator.v — 64-bit equality comparator
module comparator (
    input  [63:0] a,
    input  [63:0] b,
    output        match
);

    assign match = (a == b);

endmodule
