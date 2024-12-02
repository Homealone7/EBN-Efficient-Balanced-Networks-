module FP_8_Add_Sub (
    input  logic [7:0]       A,  // First FP-8 input
    input  logic [7:0]       B,  // Second FP-8 input
    input  logic             add,
    output logic [7:0]       Sum    // FP-8 result
);

    // A
    logic [7:0]  a;
    logic [4:0]  a_mant;
    logic [4:0]  a_exp;
    // B
    logic [7:0]  b;
    logic [4:0]  b_exp;
    logic [4:0]  b_mant; 
    logic [4:0]  b_mant_tmp;
    // Sum
    logic        sum_sign; 
    logic [4:0]  sum_exp;
    logic [1:0]  sum_mant;
    // Arithmetics
    logic        overflow;
    logic        add_sub;
    logic [7:0]  sum_norm;
    logic [4:0]  exp_norm;
    logic [5:0]  add_mant; 
    logic [4:0]  sub_mant;
    logic [4:0]  sub_mant_norm;
    logic [3:0]  round_mant;
    logic [4:0]  exp_shift;
    logic [2:0]  sub_shift;


    assign {a, b} = (A[6:0] >= B[6:0]) ? {A, B} : {B, A}; // Assign bigger number to a

    assign add_sub   = add ? (A[7] == B[7]) : (A[7] != B[7]);  // 1 Add, 0 Sub
    assign exp_shift = (a[6:2] == b[6:2]) ? 5'b0 : (a[6:2] - b[6:2]);  // Exponent Shift
    
    assign a_exp  = a[6:2];
    assign a_mant = {1'b1, a[1:0], 2'b0};  // Hidden bit and extend mantissa for rounding

    assign b_exp      = b[6:2]; 
    assign b_mant_tmp = {1'b1, b[1:0], 2'b0};
    assign b_mant     = b_mant_tmp >> exp_shift;  // Align b mantissa with a exponent

    assign add_mant = a_mant + b_mant;
    assign sub_mant = a_mant[4:0] - b_mant[4:0];
    assign sub_mant_norm = (exp_shift == 5'b0)? sub_mant : sub_mant << sub_shift;

    assign overflow = (exp_norm > 30 || sum_exp > 30);

    assign sum_sign = a[7];
    assign sum_exp  = (round_mant[3:1] == 3'b111)? exp_norm + 5'b1 : exp_norm; // Check for rounding overflow

    always_comb begin
        // Rounding based on mantissa bits
        if (exp_shift == 5'b0 && ~add_sub) begin
            sum_mant = round_mant[3:2];
        end
        else begin
            casez (round_mant[2:0])
                3'b?0?  : sum_mant = round_mant[3:2];  // No rounding needed
                3'b010  : sum_mant = round_mant[3:2];  // Even, no round
                default : sum_mant = round_mant[3:2] + 1;  // Round up
            endcase
        end
    end

    always_comb begin
        // Handle addition and normalization
        if (add_sub) begin
            round_mant = add_mant[5] ? add_mant[4:1] : add_mant[3:0];
            exp_norm   = add_mant[5] ? a_exp + 5'b1 : a_exp;  // Adjust exponent for overflow
        end
        // Handle subtraction and normalization
        else begin
            round_mant = sub_mant_norm[3:0];
            exp_norm   = (exp_shift == 5'b0)? a_exp : a_exp - {2'b00, sub_shift};
        end
    end

    always_comb begin
        casez (sub_mant)  // Find leading zeros in the difference
            5'b1???? : sub_shift = 3'b000; // No shift needed, already normalized
            5'b01??? : sub_shift = 3'b001;
            5'b001?? : sub_shift = 3'b010;
            5'b0001? : sub_shift = 3'b011;
            5'b00001 : sub_shift = 3'b100;
            5'b00000 : sub_shift = 3'b101;
            default  : sub_shift = 3'b000;
        endcase
    end

    always_comb begin
        // Normal result
        if (b[6:0] == 7'b0)
            sum_norm = a;
        else if (a[6:0] == b[6:0] && ~add_sub)
            sum_norm = 8'b0;
        else
            sum_norm = {sum_sign, sum_exp, sum_mant};
    end

    always_comb begin
        if (overflow)
            Sum = 8'b01111011;
        else 
            Sum = sum_norm;
    end


endmodule

/* If Needed (In This Design overflows are set to largest number and underflows to Zero, No NaN)

    always_comb begin
        // Handle edge cases (NaN, Infinity)
        if ((A[6:2] == 5'b11111 && A[1:0] != 2'b00) || 
            (B[6:2] == 5'b11111 && B[1:0] != 2'b00))   // NaN +/- Anything
            Sum = 8'b01111101;  // NaN
        else if (A[6:0] == 7'b1111100 && B[6:0] == 7'b1111100)  begin // Infinity +/- Infinity
            casez ({A[7], add_sub, B[7]})
                3'b000 : Sum = 8'b01111101; // NAN
                3'b001 : Sum = 8'b01111100; // +inf
                3'b010 : Sum = 8'b01111100; // +inf
                3'b011 : Sum = 8'b01111101; // NAN
                3'b100 : Sum = 8'b11111100; // -inf
                3'b101 : Sum = 8'b01111101; // NaN
                3'b110 : Sum = 8'b01111101; // NaN
                3'b111 : Sum = 8'b11111100; // -inf
            endcase
        end
        else if (A[7:0] == 8'b01111100 || B[7:0] == 8'b01111100)  // Positive Infinity +/- Finite Number
            Sum = 8'b01111100;
        else if (A[7:0] == 8'b11111100 || B[7:0] == 8'b11111100)  // Negative Infinity +/- Finite Number
            Sum = 8'b11111100;
        else
            Sum = sum_norm;
    end
*/