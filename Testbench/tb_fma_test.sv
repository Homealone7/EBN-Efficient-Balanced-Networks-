module tb_fma_test;
    logic clk;
    logic [7:0] a, b, c;      // FP8 inputs
    logic [7:0] result;       // FP8 result
    logic [1:0] result_tuser; // Overflow/underflow flags
    logic result_tvalid;

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz clock
    end

    // Instantiate the FMA IP core
    floating_point_0 fma_inst (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(a),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(b),
        .s_axis_c_tvalid(1'b1),
        .s_axis_c_tdata(c),
        .m_axis_result_tvalid(result_tvalid),
        .m_axis_result_tdata(result),
        .m_axis_result_tuser(result_tuser)
    );

    initial begin
        // Test values (A = 2, B = 3.5, C = 0)
        a = 8'h4b; // 2 in FP8
        b = 8'h04; // 3.5 in FP8
        c = 8'h0; // 0 in FP8
        #10;
        a = 8'h45; // 2 in FP8
        b = 8'h01; // 3.5 in FP8
        c = 8'h0; // 0 in FP8
        #10;
        wait(result_tvalid);  // Wait for valid result
        $display("Result: %b (Overflow/Underflow: %b)", result, result_tuser);

        // Finish simulation
        #20;
        $finish;
    end
endmodule
