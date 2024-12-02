module FP_8_FMA(
    input  [7:0] a,
    input  [7:0] b,
    input  [7:0] c,
    output [7:0] result
);

    logic [7:0] mult_result;

    FP_8_Mult Mult_0(
        .A(a),
        .B(b),
        .product(mult_result)
    );
    FP_8_Add_Sub  Add_0(
        .A(mult_result),
        .B(c),
        .add(1'b1),
        .Sum(result)
    );

endmodule