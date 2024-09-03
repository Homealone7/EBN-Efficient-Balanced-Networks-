module fixed_point_mult #(
    parameter integer INTEGER_BITS = 4,
    parameter integer FRACTIONAL_BITS = 16
)(
    input   logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] a,
    input   logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] b,
    output  logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] result,
    output  logic overflow
);

    // Intermediate full product with double the fractional bits to hold multiplication result
    logic signed [(2*INTEGER_BITS + 2*FRACTIONAL_BITS) - 1 : 0] full_product;
    // Temporary variables for overflow detection and result adjustment
    logic is_negative;
    logic high_bits_match;
    logic signed [(2*INTEGER_BITS + 2*FRACTIONAL_BITS) - 1 : 0] rounded_product;

    // Perform the multiplication
    assign full_product = a * b;

    always_comb begin
        // Add half of the least significant bit of the fractional part for rounding
        rounded_product = full_product + (1 << (FRACTIONAL_BITS - 1));

        // Right shift to adjust for the scale of the fixed-point representation
        result = rounded_product >>> FRACTIONAL_BITS;

        // Determine the sign of the full product for overflow detection
        is_negative = full_product[2*INTEGER_BITS + 2*FRACTIONAL_BITS - 1];

        // Check if the high bits beyond the scaled result size are consistent (all zeros or all ones)
        high_bits_match = (is_negative) ? &full_product[2*INTEGER_BITS + 2*FRACTIONAL_BITS - 2 -: (INTEGER_BITS + FRACTIONAL_BITS - 1)]
                                        : ~|full_product[2*INTEGER_BITS + 2*FRACTIONAL_BITS - 2 -: (INTEGER_BITS + FRACTIONAL_BITS - 1)];

        // Overflow occurs if the high bits do not match the expected sign or if the result's sign bit differs from `is_negative`
        overflow = !high_bits_match || (result[INTEGER_BITS + FRACTIONAL_BITS - 1] != is_negative);
    end

endmodule
