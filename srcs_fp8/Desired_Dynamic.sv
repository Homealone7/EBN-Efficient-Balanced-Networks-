module Desired_Dynamic #(
    parameter N      = 64,
    parameter Dims   = 2,
    parameter dyn    = 8'h 48,
    parameter Lambda = 8'h 49,
    parameter dt     = 8'h 07,
    parameter One    = 8'h 3c,
    parameter Three  = 8'h 42
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       reset_iteration,
    input  logic       start,
    input  logic       spike_flg,
    input  logic [5:0] spike_pos,
    input  logic [7:0] i_cmd   [Dims],        // Commands
    input  logic [7:0] i_dec   [Dims * N],    // Decoder
    output logic [7:0] o_err   [Dims],        // Calculation error
    output logic [7:0] o_x     [Dims],
    output logic [7:0] o_x_est [Dims],
    output logic       done
);

    logic       done_est;
    logic [7:0] i_x     [Dims];
    logic [7:0] i_x_est [Dims];

    FP_8_Add_Sub  Sub_0(
        .A(o_x[0]),
        .B(o_x_est[0]),
        .add(1'b0),
        .Sum(o_err[0])
    );
    FP_8_Add_Sub  Sub_1(
        .A(o_x[1]),
        .B(o_x_est[1]),
        .add(1'b0),
        .Sum(o_err[1])
    );

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
        .Three(Three)
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
        .One(One)
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