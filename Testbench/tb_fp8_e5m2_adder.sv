`timescale 1ns/1ps

module tb_fp8_e5m2_adder;

    // Inputs
    reg [7:0] a, b;
    
    // Output
    wire [7:0] Sum;

    // Clock for testing purposes
    reg clk;

    // Memory to store 50 test values for a and b
    reg [7:0] a_mem [0:49];  // Array to hold 50 values for a
    reg [7:0] b_mem [0:49];  // Array to hold 50 values for b

    // Instantiate the FP8 adder module
    FP_8_Add uut (
        .A(a),
        .B(b),
        .Sum(Sum)
    );

    // Clock generation (100 MHz -> 10ns period)
    always #5 clk = ~clk;
    integer output_file;
    integer i;
    initial begin
        // Initialize the clock
        clk = 0;

        // Read input values for a and b from text files
        $readmemb("a_rnd.txt", a_mem);  // Load 50 numbers from a_rnd.txt into a_mem
        $readmemb("b_rnd.txt", b_mem);  // Load 50 numbers from b_rnd.txt into b_mem

        // Open output file to write the results
        output_file = $fopen("verilog_fp8_results.txt", "w");
        if (output_file == 0) begin
            $display("Error: Unable to open output file.");
            $finish;
        end

        // Apply test cases from memory using a for loop
        for (i = 0; i < 50; i = i + 1) begin
            @(posedge clk);  // Wait for clock edge
            a = a_mem[i];    // Assign the i-th value of a
            b = b_mem[i];    // Assign the i-th value of b
            @(posedge clk);  // Wait for next clock edge to allow for result calculation
            $fwrite(output_file, "%b\n", Sum);  // Write a, b, and result C to file
        end

        // Close the output file
        $fclose(output_file);

        // Finish the simulation
        $finish;
    end

    initial begin
        // Monitor the changes
        $monitor("Time: %0t | a: %b, b: %b, sum: %b", $time, a, b, Sum);
    end

endmodule
