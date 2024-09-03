module fixed_point_add_sub #(
    parameter integer INTEGER_BITS = 8,
    parameter integer FRACTIONAL_BITS = 8
)(
    input   logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] a,
    input   logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] b,
    input   logic add_sub, // 0 for addition, 1 for subtraction
    output  logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] result,
    output  logic overflow
);

    logic signed [INTEGER_BITS + FRACTIONAL_BITS : 0] extended_a, extended_b, extended_result;

    assign extended_a = {a[INTEGER_BITS + FRACTIONAL_BITS - 1], a}; // Extend inputs to include a guard bit for overflow detection
    assign extended_b = {b[INTEGER_BITS + FRACTIONAL_BITS - 1], b};

    always_comb begin  

        if (add_sub == 0) begin // Addition
            extended_result = extended_a + extended_b;
        end else begin // Subtraction
            extended_result = extended_a - extended_b;
        end  
        // Assign the result, trimming the extended bit
        result = extended_result[INTEGER_BITS + FRACTIONAL_BITS - 1:0];  
        // Check for overflow: overflow occurs if extended_result's sign bit differs from the next bit
        overflow = extended_result[INTEGER_BITS + FRACTIONAL_BITS] != extended_result[INTEGER_BITS + FRACTIONAL_BITS - 1];
    end

endmodule