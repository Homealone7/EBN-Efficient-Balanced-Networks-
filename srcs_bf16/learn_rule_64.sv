module learn_rule_64 (
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic [31:0] dec    [2], 
    input  logic [31:0] i_err  [2],       // Decoder * Error 
    input  logic [31:0] i_spike_f,        // Filtered Spike
    input  logic [31:0] i_ws,             // Slow Weight from MEM
    output logic [31:0] upd_ws,           // Updated Slow Weight
    output logic        done
);

    // Internal 64-bit signals
    logic [10:0] exp_diff;
    logic [31:0] upd_ws_int;
    logic [63:0] mult_result;
    logic [63:0] eta_dt;
    logic [63:0] o_spike_f_dec;
    logic [63:0] dec_err0, dec_err1, dec_err;
    logic [63:0] add_result;
    logic [11:0] exp_dec0; 
    logic [11:0] exp_dec1; 
    logic [11:0] exp_err0; 
    logic [11:0] exp_err1; 
    logic [11:0] exp_spike;
    logic [11:0] exp_ws;
    // Converted FP64 signals for inputs
    logic [63:0] dec_fp64_0, dec_fp64_1;
    logic [63:0] i_err_fp64_0, i_err_fp64_1;
    logic [63:0] i_spike_f_fp64, i_ws_fp64;

    // FP32 to FP64 Conversion for Inputs
    assign exp_dec0 = dec[0][30:23] + 11'd896;
    assign exp_dec1 = dec[1][30:23] + 11'd896;
    assign exp_err0 = i_err[0][30:23] + 11'd896;
    assign exp_err1 = i_err[1][30:23] + 11'd896;
    assign exp_spike = i_spike_f[30:23] + 11'd896;
    assign exp_ws = i_ws[30:23] + 11'd896;
    always_comb begin
        // Convert dec inputs
        dec_fp64_0 = {dec[0][31], exp_dec0, dec[0][22:0], 29'b0};
        dec_fp64_1 = {dec[1][31], exp_dec1, dec[1][22:0], 29'b0};

        // Convert i_err inputs
        i_err_fp64_0 = {i_err[0][31], exp_err0, i_err[0][22:0], 29'b0};
        i_err_fp64_1 = {i_err[1][31], exp_err1, i_err[1][22:0], 29'b0};

        // Convert other inputs
        i_spike_f_fp64 = {i_spike_f[31], exp_spike, i_spike_f[22:0], 29'b0};
        i_ws_fp64      = {i_ws[31], exp_ws, i_ws[22:0], 29'b0};
    end

    // FP64 to FP32 Conversion for Outputs
    assign exp_diff = add_result[62:52] - 11'd896;
    assign upd_ws_int = {add_result[63], exp_diff[7:0], add_result[51:29]};

    // Main logic
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done   <= 0;
        end else if (start) begin
            done   <= 1;
            upd_ws <= upd_ws_int;
        end else begin
            done <= 0;
        end
    end

    // FP64 Arithmetic Units
    FP64_Add Add_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(mult_result),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_ws_fp64),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(add_result)
    );

    FP64_Add Add_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec_err0),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dec_err1),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err)
    );

    FP64_Mult dec_err_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec_fp64_0),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_err_fp64_0),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err0)
    );

    FP64_Mult dec_err_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec_fp64_1),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_err_fp64_1),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err1)
    );

    FP64_Mult mult_inst (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(i_spike_f_fp64),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dec_err),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(o_spike_f_dec)
    );

    FP64_Mult etadt (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(Eta_W),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(eta_dt)
    );

    FP64_Mult result (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_spike_f_dec),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(eta_dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(mult_result)
    );

endmodule
