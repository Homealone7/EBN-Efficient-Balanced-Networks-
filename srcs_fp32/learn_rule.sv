module learn_rule #(
    parameter N     = 64,
    parameter Dims  = 2,
    parameter Eta_W = 16'h 3e9a,
    parameter dt    = 16'h 38d2
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic [31:0] dec    [Dims],
    input  logic [31:0] i_err  [Dims],       // Decoder * Error
    input  logic [31:0] i_spike_f,           // Filtered Spike
    input  logic [31:0] i_ws,                // Slow Weight from MEM
    output logic [31:0] upd_ws,              // Updated Slow Weight
    output logic [31:0] test_ws   [N],          // Updated Slow Weight
    output logic        done
);

    logic [5:0]  index;
    logic [31:0] mult_result;
    logic [31:0] eta_dt;
    logic [31:0] o_spike_f_dec;
    logic [31:0] dec_err0;
    logic [31:0] dec_err1;
    logic [31:0] dec_err;
    logic [31:0] add_result;

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done   <= 0;
            index  <= 0;
            upd_ws <= 0;
            test_ws   <= '{default: '0};
        end
        else if (start) begin
            upd_ws      <= add_result;
            test_ws[index] <= add_result;
            index       <= index  + 1;
            done        <= 1;
        end
        else done <= 0;
    end
    BF16_Add Add_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(mult_result),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_ws),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(add_result)
    );
    BF16_Add Add_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec_err0),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dec_err1),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err)
    );
    BF16_Mult dec_err_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec[0]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_err[0]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err0)
    );
    BF16_Mult dec_err_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec[1]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_err[1]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err1)
    );
    BF16_Mult mult_inst (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(i_spike_f),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dec_err),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(o_spike_f_dec)
    );
    BF16_Mult etadt (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(Eta_W),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(eta_dt)
    );
    BF16_Mult result (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_spike_f_dec),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(eta_dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(mult_result)
    );

endmodule