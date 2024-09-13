module x_est #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter Lambda            = 16'h A000,
    parameter One               = 16'h 1000,
    parameter dt                = 16'h 68DB,
    parameter INTEGER_BITS      = 5,
    parameter FRACTIONAL_BITS   = 11
)(
    input  logic                                                clk,
    input  logic                                                reset,
    input  logic                                                reset_iteration,
    input  logic                                                start,
    input  logic                                                spike_flg,
    input  logic         [5:0]                                  spike_pos,
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec       [Dims * N],    // Decoder
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_x_est     [Dims],        // Estimated X from MEM
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_x_est     [Dims],
    output logic                                                done
);

    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] x1_est_leak;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] x0_est_leak;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] lambda_dt;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] leak;

    assign leak = One - lambda_dt;

    always_ff @(posedge clk or posedge reset) begin
        if (reset || reset_iteration) begin
            o_x_est <= '{default: '0};
            done    <= 0;
        end 
        else begin
            if (start) begin
                o_x_est[0] <= (spike_flg)? x0_est_leak + i_dec[spike_pos] : x0_est_leak;
                o_x_est[1] <= (spike_flg)? x1_est_leak + i_dec[spike_pos + 64] : x1_est_leak;
                done       <= 1;
            end
            else done <= 0;
        end
    end

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) lambdadt (
        .a(Lambda), 
        .b(dt),
        .result(lambda_dt),
        .overflow()
    );

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) x0est_leak (
        .a(leak), 
        .b(i_x_est[0]),
        .result(x0_est_leak),
        .overflow()
    );

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) x1est_leak (
        .a(leak), 
        .b(i_x_est[1]),
        .result(x1_est_leak),
        .overflow()
    );
    
endmodule
