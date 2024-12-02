module dynamic_est #(
    parameter N      = 64,
    parameter Dims   = 2,
    parameter Lambda = 16'h 4120,
    parameter One    = 16'h 3f80,
    parameter dt     = 16'h 38d2
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic        spike_flg,
    input  logic [5:0]  spike_pos,
    input  logic [15:0] i_dec       [Dims * N],    // Decoder
    input  logic [15:0] i_x_est     [Dims],        // Estimated X from MEM
    output logic [15:0] o_x_est     [Dims],
    output logic        done
);

    logic [15:0] x1_est_leak;
    logic [15:0] x0_est_leak;
    logic [15:0] x0_dec;
    logic [15:0] x1_dec;
    logic [15:0] lambda_dt;
    logic [15:0] leak;
    logic [15:0] dec_0;
    logic [15:0] dec_1;
    logic [6:0]  pos;
    assign pos = spike_pos << 1;
    assign dec_0 = (spike_flg)? i_dec[pos] : 0;
    assign dec_1 = (spike_flg)? i_dec[pos + 1] : 0;

    BF16_Mult lambdadt (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(Lambda),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(lambda_dt)
    );
    BF16_Mult x0est_leak (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(leak),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_x_est[0]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(x0_est_leak)
    );
    BF16_Mult x1est_leak (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(leak),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_x_est[1]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(x1_est_leak)
    );
    BF16_Sub Sub_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(One),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(lambda_dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(leak)
    );
    BF16_Add Add_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(x0_est_leak),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dec_0),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(x0_dec)
    );
    BF16_Add Add_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(x1_est_leak),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dec_1),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(x1_dec)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset || reset_iteration) begin
            o_x_est <= '{default: '0};
            done    <= 0;
        end 
        else begin
            if (start) begin
                o_x_est[0] <= x0_dec;
                o_x_est[1] <= x1_dec;
                done       <= 1;
            end
            else done <= 0;
        end
    end
    
endmodule
