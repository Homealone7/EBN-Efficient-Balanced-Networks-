module FP_8_Mult (
    input logic [7:0] A,  // Input A (FP8)
    input logic [7:0] B,  // Input B (FP8)
    output logic [7:0] product // Output Product (FP8)
);

    // A
    logic [4:0] a_exp;
    logic [2:0] a_mant;
    // B
    logic [4:0] b_exp;
    logic [2:0] b_mant;
    // Product
    logic       product_sign;
    logic [4:0] product_exp;
    logic [1:0] product_mant;
    // Arithmetics
    logic [5:0] mult_mant;
    logic [3:0] round_mant;
    logic [5:0] exp_sum;
    logic [4:0] exp_norm;
    logic [4:0] exp_bias;

    logic       underflow;
    logic       overflow;
    
    assign a_exp  = A[6:2];
    assign a_mant = {1'b1, A[1:0]};  // Hidden bit
    
    assign b_exp  = B[6:2];
    assign b_mant = {1'b1, B[1:0]};

    assign mult_mant  = a_mant * b_mant;
    assign round_mant = (mult_mant[5])? mult_mant[4:1] : mult_mant [3:0];

    assign exp_bias   = (mult_mant[5])? 5'd14 : 5'd15;
    assign exp_sum    = a_exp + b_exp;
    assign exp_norm   = (underflow)? 5'b0 : exp_sum - exp_bias;

    assign underflow  = (mult_mant[5])? (exp_sum < 5'd14) : (exp_sum < 5'd15);
    assign overflow   = (exp_norm > 30 || product_exp > 30);
    
    assign product_sign = A[7] ^ B[7];
    assign product_exp  = (round_mant[3:1] == 3'b111)? exp_norm + 5'b1 : exp_norm;
    always_comb begin
        // Rounding based on mantissa bits
        casez (round_mant[2:0])
            3'b?0?   : product_mant = round_mant[3:2];  // No rounding needed
            3'b010   : product_mant = round_mant[3:2];  // Even, no round
            default  : product_mant = round_mant[3:2] + 1;  // Round up
        endcase
    end

    always_comb begin
        if ((A[6:0] == 7'b0000000) || (B[6:0] == 7'b0000000))
            product = 8'b0;
        else if (overflow)
            product = 8'b01111011;
        else if (underflow)
            product = 8'b0;
        else 
            product = {product_sign, product_exp, product_mant};
    end

endmodule

/* If Needed (In This Design overflows are set to largest number and underflows to Zero, No NaN)

    always_comb begin
        // Handle edge cases (NaN, Infinity)
        if ((A[6:2] == 5'b11111 && A[1:0] != 2'b00) || 
            (B[6:2] == 5'b11111 && B[1:0] != 2'b00))   // NaN * Anything
            product = 8'b01111101;  // NaN
        else if (A[6:0] == 7'b1111100 && B[6:0] == 7'b1111100)  begin // Infinity * Infinity
            casez ({A[7], B[7]})
                2'b00 : product = 8'b01111100; // +inf
                2'b01 : product = 8'b11111100; // -inf
                2'b10 : product = 8'b11111100; // -inf
                2'b11 : product = 8'b01111100; // +inf
            endcase
        end
        else if (A[6:0] == 7'b1111100 && B[6:0] == 7'b0000000 ||
                 A[6:0] == 7'b0000000 && B[6:0] == 7'b1111100)  // Infinity * Zero
            product = 8'b01111101; // NaN
        else if (A[6:0] == 7'b1111100 || B[6:0] == 7'b1111100)  // Infinity * Finite Number
            product = 8'b01111100;
        else
            product = {product_sign, product_exp, product_mant};
    end
*/