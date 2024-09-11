module fixed_point_matrix_mult #(
    parameter INTEGER_BITS = 8,
    parameter FRACTIONAL_BITS = 24,
    parameter A_ROWS = 1,
    parameter B_COLS = 1,
    parameter A_COLS_B_ROWS = 2 // A's columns and B's rows must be the same
)(
    input   logic clk,
    input   logic reset,
    input   logic start, // Start signal to control the start of computation
    input   logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] A[A_ROWS * A_COLS_B_ROWS],
    input   logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] B[A_COLS_B_ROWS * B_COLS],
    output  logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] C[A_ROWS * B_COLS],
    output  logic next,
    output  logic done // Indicates when the matrix multiplication is complete
);

    integer i = 0, j = 0, k = 0;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] sum;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1 : 0] mult_result;
    logic mult_overflow;
    logic in_progress; // Internal signal to track computation state

    // Instantiate the fixed-point multiplication module
    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) mult_inst (
        .a(A[i * A_COLS_B_ROWS + k]), // Operands will be dynamically selected based on loop indices
        .b(B[k * B_COLS + j]),
        .result(mult_result),
        .overflow(mult_overflow)
    );

    always_ff @(posedge clk) begin
        if (reset) begin
            // Reset logic
            done <= 0;
            next <= 0;
            in_progress <= 0;
            i <= 0;
            j <= 0;
            k <= 0;
            sum <= 0;
            for (int row = 0; row < A_ROWS; row++) begin
                for (int col = 0; col < B_COLS; col++) begin
                    C[row * B_COLS + col] <= 0;
                end
            end
        end else begin
            if (start && !in_progress) begin
                in_progress <= 1; // Start computation
            end
            if (next) begin
                next <= 0;
            end
            if (in_progress) begin
                if (i < A_ROWS) begin
                    if (j < B_COLS) begin
                        if (k < A_COLS_B_ROWS) begin
                            if (i == A_ROWS - 1 && j == B_COLS - 1 && k == A_COLS_B_ROWS - 1) begin
                                next <= 1; // Signal next one cycle before done
                            end 
                            // Accumulate multiplication result
                            if (k == 0) sum <= mult_result;
                            else sum <= sum + mult_result;
                            k <= k + 1;
                        end 
                        else begin
                            C[i * B_COLS + j] <= sum; // Store accumulated sum
                            sum <= 0; // Reset sum for next element
                            k <= 0; // Reset k
                            j <= j + 1; // Move to next column
                            if (i == A_ROWS - 1 && j == B_COLS - 1) begin
                                done <= 1; // Signal done when the last element is written
                                in_progress <= 0; // Computation complete
                                i <= 0; j <= 0; k <= 0; // Reset indices
                            end
                        end
                    end
                    if (j == B_COLS) begin
                        j <= 0; // Reset j
                        i <= i + 1; // Move to next row
                    end
                end
            end 
            else begin
                done <= 0; // Ensure done is low when start is not asserted
                next <= 0;
            end
        end
    end

endmodule
