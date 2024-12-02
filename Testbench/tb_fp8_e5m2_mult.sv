`timescale 1ns/1ps

module tb_fp8_e5m2_mult;

    // Inputs
    logic [7:0] a, b, c;
    
    // Output
    logic [7:0] product;

    // Clock for testing purposes
    logic clk;

    // Instantiate the FP8 multiplier module
    FP_8_FMA uut (
        .a(a),
        .b(b),
        .c(c),
        .result(product)
    );

    // Clock generation (100 MHz -> 10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize inputs
        clk = 0;
        a = 8'h3c;
        b = 8'h01;
        c = 8'h0;
        #10
        a = 8'h3c;
        b = 8'h03;
        c = 8'h0;
        #10
        a = 8'h3c;
        b = 8'hc2;
        c = 8'h0;
        // Apply test cases
        #10;
        a = 8'h3c;
        b = 8'h74;
        c = 8'h0;
        #10;
        
        a = 8'b11000010;  // Example FP8 value (sign=1, exp=4, mantissa=11)
        b = 8'b11000010;  // Example FP8 value (sign=0, exp=4, mantissa=01)
        c = 8'b01000000;
        #10;
        
        a = 8'b01000010;  // Example FP8 value (sign=0, exp=3, mantissa=11)
        b = 8'b11000010;  // Example FP8 value (sign=0, exp=3, mantissa=11)
        c = 8'b01000000;
        #10;

        a = 8'b01111001;  // Example FP8 value (sign=0, exp=7, mantissa=01)
        b = 8'b00110110;  // Example FP8 value (sign=0, exp=3, mantissa=10)
        c = 8'b01000000;
        #10;
        
        // Finish the simulation
        $finish;
    end

    initial begin
        // Monitor the changes
        $monitor("Time: %0t | a: %b, b: %b, product: %b", $time, a, b, product);
    end

endmodule
