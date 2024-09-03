module learn_rule #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter Eta_W             = 40'h 4CCCCCCC, // learning rate
    parameter dt                = 40'h 68DB8,                                                         
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32,
    parameter A_ROWS            = 1,
    parameter B_COLS            = 1
) (
    input   logic                                                clk,
    input   logic                                                reset,
    input   logic                                                start,
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] dec_t  [Dims],
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_err  [Dims],             // Decoder * Error
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f,           // Filtered Spike
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_ws,                // Slow Weight from MEM
    output  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] upd_ws,                // Updated Slow Weight
    output  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_ws   [N],                // Updated Slow Weight
    output  logic                                                done
);

    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0]  mult_result, eta_dt, o_spike_f_dec, dec_err0, dec_err1, dec_err;
    integer i;
    logic [5:0] index;
    logic overflow;
    assign dec_err = dec_err0 + dec_err1;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done   <= 0;
            index  <= 0;
            upd_ws <= 0;
        end
        else if (start) begin
            upd_ws <= mult_result + i_ws;
            index  <= index  + 1;
            done   <= 1;
        end
        else done <= 0;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < N; i++) begin
                o_ws[i] <= 0;
            end
        end
        else begin
            if (start) begin
                o_ws[index] <= mult_result + i_ws;
            end
        end
    end

     fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
     ) dec_err_0 (
        .a(dec_t[0]),
        .b(i_err[0]),
        .result(dec_err0),
        .overflow()
    );
     fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) dec_err_1 (
        .a(dec_t[1]),
        .b(i_err[1]),
        .result(dec_err1),
        .overflow()
    );

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) mult_inst (
        .a(i_spike_f),
        .b(dec_err),
        .result(o_spike_f_dec),
        .overflow()
    );

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) etadt (
        .a(Eta_W),
        .b(dt),
        .result(eta_dt),
        .overflow()
    );

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) result (
        .a(o_spike_f_dec),
        .b(eta_dt),
        .result(mult_result),
        .overflow(overflow)
    );


endmodule