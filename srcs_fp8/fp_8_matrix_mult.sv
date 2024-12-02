module fp_8_matrix_mult #(
    parameter A_ROWS = 2,        // Number of rows in matrix A
    parameter B_COLS = 2,        // Number of columns in matrix B
    parameter A_COLS_B_ROWS = 2  // Columns in A and Rows in B must be the same
)(
    input  logic clk,           // Clock signal
    input  logic reset,         // Synchronous reset
    input  logic reset_iteration, // Reset for each iteration
    input  logic start,         // Start signal to control the start of computation
    input  logic [7:0] A[A_ROWS * A_COLS_B_ROWS], // Matrix A (8-bit custom floating point)
    input  logic [7:0] B[A_COLS_B_ROWS * B_COLS], // Matrix B (8-bit custom floating point)
    output logic [7:0] C[A_ROWS * B_COLS],        // Matrix C (result, 8-bit output)
    output logic next,                            // Next signal
    output logic done                             // Done signal, indicates when the multiplication is complete
);

    // Internal signals
    integer i = 0, j = 0, k = 0;    // Indices for rows and columns
    logic [7:0] sum;                // Accumulation for each element of matrix C (8-bit)
    logic [7:0] fma_result;         // Result from FMA IP (8-bit result)
    logic m_axis_result_tvalid;
    logic in_progress;              // Tracks if the computation is in progress

    // Instantiate the FMA IP with 8-bit inputs
    FP_8_FMA FMA_0 (
        .a(A[i * A_COLS_B_ROWS + k]),
        .b(B[k * B_COLS + j]),
        .c(sum),
        .result(fma_result)
    );

    // Always block for control logic
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            in_progress <= 0;
            done        <= 0;
        end
        else begin
            if (start && !in_progress) begin
                in_progress <= 1;
                done        <= 0;
            end
            else if (i == A_ROWS - 1 && j == B_COLS - 1 && k == A_COLS_B_ROWS - 1) begin
                in_progress <= 0;
                done        <= 1;
            end
            else done <= 0;
        end
    end

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            next <= 0;
        end
        else begin
            if (i == A_ROWS - 1 && j == B_COLS - 1 && k == A_COLS_B_ROWS - 2) begin
                next <= 1;
            end
            else next <= 0;
        end
    end
    // Always block for handling the k (inner loop) and accumulation logic
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            C   <= '{default: '0};
            sum <= 8'b0;
            k   <= 0;
        end
        else begin
            if (in_progress && k < A_COLS_B_ROWS) begin
                if (k == A_COLS_B_ROWS - 1) begin
                    C[i * B_COLS + j] <= fma_result; // Store result in C
                    sum               <= 8'b0;       // Reset sum for the next row
                    k                 <= 0;          // Reset k
                end
                else begin
                    sum <= fma_result;  // Accumulate result
                    k <= k + 1;         // Increment k
                end
            end 
        end
    end

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            j <= 0;
            i <= 0;
        end
        else begin
            if (in_progress && k == A_COLS_B_ROWS - 1) begin
                if (j == B_COLS - 1) begin
                    j <= 0;  // Reset j when last column is done
                    if (i == A_ROWS - 1) begin
                        i <= 0;  // Reset i when the last row is done
                    end
                    else begin
                        i <= i + 1;  // Increment i (row)
                    end
                end
                else begin
                    j <= j + 1; // Increment j (column)
                end
            end
        end
    end

endmodule
