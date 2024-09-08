module Desired_Dynamic #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter dyn               = 40'h 800000000,
    parameter Lambda            = 40'h A00000000,
    parameter dt                = 40'h 68DB8,
    parameter One               = 40'h 100000000,
    parameter Three             = 40'h 300000000,
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32
)(
    input   logic                                                clk,
    input   logic                                                reset,
    input   logic                                                start,
    input   logic         [5:0]                                  spike_pos,
    input   logic                                                spike_flg,
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd       [Dims],        // Commands
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec       [Dims * N],    // Decoder
    output  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_err       [Dims],        // Calculation error
    output  logic                                                done
);

    logic                                               done_est;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] i_x     [Dims];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] i_x_est [Dims];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] o_x     [Dims];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] o_x_est [Dims];

    assign o_err[0] = (reset)? 0 : o_x[0] - o_x_est[0];
    assign o_err[1] = (reset)? 0 : o_x[1] - o_x_est[1];

    always_ff @(posedge clk or posedge reset ) begin
        if (reset) begin
            i_x     <= '{default: '0};
            i_x_est <= '{default: '0};
        end
        else begin
            if (done_est) begin
                i_x[0]     <= o_x[0];
                i_x[1]     <= o_x[1];
                i_x_est[0] <= o_x_est[0];
                i_x_est[1] <= o_x_est[1];
            end
            
        end
    end

    dynamic #(
        .N(N),            
        .Dims(Dims),         
        .dyn(dyn),
        .dt(dt),
        .Three(Three),        
        .INTEGER_BITS(INTEGER_BITS),   
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    )Desired(
        .clk(clk),
        .reset(reset),
        .start(start),
        .i_cmd(i_cmd),
        .i_x(i_x),
        .o_x(o_x),
        .done(done)
    );

    x_est #(
        .N(N),            
        .Dims(Dims),         
        .Lambda(Lambda),
        .dt(dt),
        .One(One),         
        .INTEGER_BITS(INTEGER_BITS),   
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    )Estimate(
        .clk(clk),
        .reset(reset),
        .start(start),
        .spike_flg(spike_flg),
        .spike_pos(spike_pos),
        .i_dec(i_dec),   
        .i_x_est(i_x_est),    
        .o_x_est(o_x_est), 
        .done(done_est)
    );

endmodule
