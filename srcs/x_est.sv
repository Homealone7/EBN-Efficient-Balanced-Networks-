module x_est #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter Lambda            = 40'h A00000000,
    parameter One               = 40'h 100000000,
    parameter dt                = 40'h 68DB8,
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32
)(
    input   logic                                                clk,
    input   logic                                                reset,
    input   logic                                                start,
    input   logic                                                spike_flg,
    input   logic         [5:0]                                  spike_pos,
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec       [Dims * N],    // Decoder
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_x_est     [Dims],        // Estimated X from MEM
    output  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_x_est     [Dims],
    output  logic                                                done
);

    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] x1_est_leak, x0_est_leak, lambda_dt, leak;

    assign leak = One - lambda_dt;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            o_x_est[0] <= 0;
            o_x_est[1] <= 0;
            done       <= 0;
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
