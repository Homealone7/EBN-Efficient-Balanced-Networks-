
module BF16_Add_Sub (
    input  logic [15:0]       A,  // First FP-8 input
    input  logic [15:0]       B,  // Second FP-8 input
    input  logic             add,
    output logic [15:0]       Sum    // FP-8 result
);

    // A
    logic [15:0]  a;
    logic [14:0]  a_mant;
    logic [7:0]   a_exp;
    // B
    logic [15:0]  b;
    logic [7:0]   b_exp;
    logic [14:0]  b_mant; 
    logic [14:0]  b_mant_tmp;
    // Sum
    logic        sum_sign; 
    logic [7:0]  sum_exp;
    logic [6:0]  sum_mant;
    // Arithmetics
    logic         add_sub;
    logic [15:0]  sum_norm;
    logic [13:0]  round_mant;
    logic [7:0]   exp_norm;
    logic [15:0]  add_mant; 
    logic [14:0]  sub_mant;
    logic [14:0]  sub_mant_norm;
    logic [7:0]   exp_shift;
    logic [3:0]   sub_shift;


    assign {a, b} = (A[14:0] >= B[14:0]) ? {A, B} : {B, A}; // Assign bigger number to a

    assign add_sub   = add ? (A[15] == B[15]) : (A[15] != B[15]);  // 1 Add, 0 Sub
    assign exp_shift = (a[14:7] == b[14:7]) ? 7'b0 : (a[14:7] - b[14:7]);  // Exponent Shift
    
    assign a_exp  = a[14:7];
    assign a_mant = {1'b1, a[6:0], 7'b0};  // Hidden bit and extend mantissa for rounding

    assign b_exp      = b[14:7]; 
    assign b_mant_tmp = {1'b1, b[6:0], 7'b0};
    assign b_mant     = b_mant_tmp >> exp_shift;  // Align b mantissa with a exponent

    assign add_mant = a_mant + b_mant;
    assign sub_mant = a_mant - b_mant;
    assign sub_mant_norm = (exp_shift == 8'b0)? sub_mant : sub_mant << sub_shift;

    assign sum_sign = a[15];
    assign sum_exp  = (round_mant[13:1] == 13'b1111_1111_1111_1)? exp_norm + 8'b1 : exp_norm; // Check for rounding overflow

    always_comb begin
        // Rounding based on mantissa bits
        if (exp_shift == 8'b0 && ~add_sub) begin
            sum_mant = round_mant[13:7];
        end
        else begin
            casez (round_mant[7:0])
                8'b?0??????  : sum_mant = round_mant[13:7];  // No rounding needed
                8'b01000000  : sum_mant = round_mant[13:7];  // Even, no round
                default     : sum_mant = round_mant[13:7] + 1;  // Round up
            endcase
        end
    end

    always_comb begin
        // Handle addition and normalization
        if (add_sub) begin
            round_mant = add_mant[15] ? add_mant[14:1] : add_mant[13:0];
            exp_norm   = add_mant[15] ? a_exp + 8'b1 : a_exp;  // Adjust exponent for overflow
        end
        // Handle subtraction and normalization
        else begin
            round_mant = sub_mant_norm[13:0];
            exp_norm   = (exp_shift == 8'b0)? a_exp : a_exp - {4'b0000, sub_shift};
        end
    end

    always_comb begin
        casez (sub_mant)  // Find leading zeros in the difference
            15'b1?????????????? : sub_shift = 15'd0;
            15'b01????????????? : sub_shift = 15'd1;
            15'b001???????????? : sub_shift = 15'd2;
            15'b0001??????????? : sub_shift = 15'd3;
            15'b00001?????????? : sub_shift = 15'd4;
            15'b000001????????? : sub_shift = 15'd5;
            15'b0000001???????? : sub_shift = 15'd6;
            15'b00000001??????? : sub_shift = 15'd7;
            15'b000000001?????? : sub_shift = 15'd8;
            15'b0000000001????? : sub_shift = 15'd9;
            15'b00000000001???? : sub_shift = 15'd10;
            15'b000000000001??? : sub_shift = 15'd11;
            15'b0000000000001?? : sub_shift = 15'd12;
            15'b00000000000001? : sub_shift = 15'd13;
            15'b000000000000001 : sub_shift = 15'd14;
            15'b000000000000000 : sub_shift = 15'd15;
            default  : sub_shift = 15'd0;
        endcase
    end

    always_comb begin
        // Normal result
        if (b[14:0] == 15'b0)
            sum_norm = a;
        else if (a[14:0] == b[14:0] && ~add_sub)
            sum_norm = 16'b0;
        else
            sum_norm = {sum_sign, sum_exp, sum_mant};
    end
    always_comb begin
        if (sum_norm == 16'h8000)
            Sum = 16'h0000;
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
        else if (A[6:0] == 15'b1111100 && B[6:0] == 15'b1111100)  begin // Infinity +/- Infinity
            casez ({A[15], add_sub, B[15]})
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
        else if (A[15:0] == 8'b01111100 || B[15:0] == 8'b01111100)  // Positive Infinity +/- Finite Number
            Sum = 8'b01111100;
        else if (A[15:0] == 8'b11111100 || B[15:0] == 8'b11111100)  // Negative Infinity +/- Finite Number
            Sum = 8'b11111100;
        else
            Sum = sum_norm;
    end
*/