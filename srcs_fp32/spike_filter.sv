module spike_filter #(
    parameter N      = 64,
    parameter Lambda = 16'h 4120,
    parameter dt     = 16'h 38d2,
    parameter One    = 16'h 3f80
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic [31:0] i_spike_f  [N],    // Filtered Spikes from MEM
    output logic [31:0] o_spike_f  [N],    // Updated Filtered Spikes
    output logic        done
); 

    logic        calculating;
    logic [5:0]  index;
    logic [31:0] spike_leak;
    logic [31:0] lambda_dt;
    logic [31:0] leak;
    
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done        <= 0;
            calculating <= 0;
            index       <= 0;
            o_spike_f   <= '{default: '0};
        end
        else begin
            if (start && !calculating) begin
                calculating <= 1;
                index       <= 0;
                done        <= 0;
            end
            else if (calculating) begin
                o_spike_f [index] <= spike_leak;
                index <= index + 1;
                if (index == N - 1) begin
                    calculating <= 0;
                    index       <= 0;
                    done        <= 1;
                end
            end
            else begin
                done <= 0;
            end
        end       
    end

    BF16_Sub Sub_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(One),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(lambda_dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(leak)
    );
    BF16_Mult lambdadt (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(Lambda),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(lambda_dt)
    );
    BF16_Mult spike_f_leak (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(leak),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_spike_f[index]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(spike_leak)
    );

endmodule