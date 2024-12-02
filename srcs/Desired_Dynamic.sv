module Desired_Dynamic #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter dyn               = 16'h 8000,
    parameter Lambda            = 16'h A000,
    parameter dt                = 16'h 68DB,
    parameter One               = 16'h 1000,
    parameter Three             = 16'h 3000,
    parameter INTEGER_BITS      = 5,
    parameter FRACTIONAL_BITS   = 11
)(
    input  logic                                                clk,
    input  logic                                                reset,
    input  logic                                                reset_iteration,
    input  logic                                                start,
    input  logic                                                spike_flg,
    input  logic         [5:0]                                  spike_pos,
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd       [Dims],        // Commands
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec       [Dims * N],    // Decoder
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_err       [Dims],        // Calculation error
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_x         [Dims],
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_x_est     [Dims],
    output logic                                                done
);

    logic                                               done_est;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] i_x     [Dims];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] i_x_est [Dims];
    //logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] o_x     [Dims];
    //logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] o_x_est [Dims];

    assign o_err[0] = o_x[0] - o_x_est[0];
    assign o_err[1] = o_x[1] - o_x_est[1];

    always_ff @(posedge clk ) begin
        if (reset || reset_iteration) begin
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
        .reset_iteration(reset_iteration),
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
        .reset_iteration(reset_iteration),
        .start(start),
        .spike_flg(spike_flg),
        .spike_pos(spike_pos),
        .i_dec(i_dec),   
        .i_x_est(i_x_est),    
        .o_x_est(o_x_est), 
        .done(done_est)
    );

endmodule
