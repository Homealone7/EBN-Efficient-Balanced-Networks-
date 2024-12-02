module dynamic_est #(
    parameter N      = 64,
    parameter Dims   = 2,
    parameter Lambda = 8'h 49,
    parameter One    = 8'h 3c,
    parameter dt     = 8'h 07
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       reset_iteration,
    input  logic       start,
    input  logic       spike_flg,
    input  logic [5:0] spike_pos,
    input  logic [7:0] i_dec       [Dims * N],    // Decoder
    input  logic [7:0] i_x_est     [Dims],        // Estimated X from MEM
    output logic [7:0] o_x_est     [Dims],
    output logic       done
);

    logic [7:0] x1_est_leak;
    logic [7:0] x0_est_leak;
    logic [7:0] x0_dec;
    logic [7:0] x1_dec;
    logic [7:0] lambda_dt;
    logic [7:0] leak;

    FP_8_Mult lambdadt(
        .A(Lambda),
        .B(dt),
        .product(lambda_dt)
    );
    FP_8_Mult x0est_leak(
        .A(leak),
        .B(i_x_est[0]),
        .product(x0_est_leak)
    );
    FP_8_Mult x1est_leak(
        .A(leak),
        .B(i_x_est[1]),
        .product(x1_est_leak)
    );

    FP_8_Add_Sub  Sub_0(
        .A(One),
        .B(lambda_dt),
        .add(1'b0),
        .Sum(leak)
    );
    FP_8_Add_Sub  Add_0(
        .A(x0_est_leak),
        .B(i_dec[spike_pos]),
        .add(1'b1),
        .Sum(x0_dec)
    );
    FP_8_Add_Sub  Add_1(
        .A(x1_est_leak),
        .B(i_dec[spike_pos + 64]),
        .add(1'b1),
        .Sum(x1_dec)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset || reset_iteration) begin
            o_x_est <= '{default: '0};
            done    <= 0;
        end 
        else begin
            if (start) begin
                o_x_est[0] <= (spike_flg)? x0_dec : x0_est_leak;
                o_x_est[1] <= (spike_flg)? x1_dec : x1_est_leak;
                done       <= 1;
            end
            else done <= 0;
        end
    end
    
endmodule
