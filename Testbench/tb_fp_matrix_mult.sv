module tb_fp_matrix_mult;

    // Testbench parameters for a 2x2 matrix multiplication
    parameter A_ROWS = 1;
    parameter B_COLS = 1;
    parameter A_COLS_B_ROWS = 64;
    integer i, counter = 0;

    // Clock and reset signals
    logic clk = 0;
    logic reset;
    logic reset_iteration;
    logic start;
    logic next;
    logic done;

    // Matrices A, B, and output C (8-bit wide FP8 format)
    logic [7:0] A [A_ROWS * A_COLS_B_ROWS];
    logic [7:0] B [A_COLS_B_ROWS * B_COLS];
    logic [7:0] C [A_ROWS * B_COLS];
    logic [1:0] m_axis_result_tuser;

    // Expected results
    logic [7:0] expected_C [A_ROWS * B_COLS];

    // Clock generation (25 MHz)
    always begin
        #10 clk = ~clk; // 20ns period = 25 MHz clock
    end
    
    always_ff @(posedge clk) begin
        if(start) counter <= counter + 1;
    end

    // Instantiate the matrix multiplication module
    fp_8_matrix_mult #(
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS),
        .A_COLS_B_ROWS(A_COLS_B_ROWS)
    ) uut (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start),
        .A(A),
        .B(B),
        .C(C),
        .next(next),
        .done(done)
    );

    // Test procedure
    initial begin
        // Initial setup
        reset = 1;
        reset_iteration = 0;
        start = 0;
       for(i = 0; i < A_ROWS * A_COLS_B_ROWS; i++) begin
            A[i] = $random;
            B[i] = $random;
       end
        #100;

        // Expected output values for matrix C
        // Expected result C = [[8, 6], [6, 12]]
        expected_C[0] = 8'h28;  // C[0][0] = 8 in FP8
        expected_C[1] = 8'h14;  // C[0][1] = 6 in FP8
        expected_C[2] = 8'h12;  // C[1][0] = 6 in FP8
        expected_C[3] = 8'h04;  // C[1][1] = 12 in FP8

        // Release reset and start computation
        reset = 0;
        start = 1;

        // Wait for done signal (indicating that the matrix multiplication is complete)
        wait(done);
        start = 0;

        // Display the result matrix C and compare with expected results
        $display("Matrix C Result (FP8) and Comparison:");
        for (int i = 0; i < A_ROWS; i++) begin
            for (int j = 0; j < B_COLS; j++) begin
                $display("C[%0d][%0d] = %b (Expected = %b)", i, j, C[i * B_COLS + j], expected_C[i * B_COLS + j]);
                if (C[i * B_COLS + j] === expected_C[i * B_COLS + j]) begin
                    $display("PASS");
                end else begin
                    $display("FAIL");
                end
            end
        end

        // Finish simulation
        #100;
        $finish;
    end

endmodule
