module learn_rule #(
    parameter N     = 64,
    parameter Dims  = 2,
    parameter Eta_W = 8'h 35, // learning rate
    parameter dt    = 8'h 07
) (
    input  logic       clk,
    input  logic       reset,
    input  logic       reset_iteration,
    input  logic       start,
    input  logic [7:0] dec_t  [Dims],
    input  logic [7:0] i_err  [Dims],       // Decoder * Error
    input  logic [7:0] i_spike_f,           // Filtered Spike
    input  logic [7:0] i_ws,                // Slow Weight from MEM
    output logic [7:0] upd_ws,              // Updated Slow Weight
    output logic [7:0] o_ws   [N],          // Updated Slow Weight
    output logic       done
);

    logic [5:0] index;
    logic [7:0] mult_result;
    logic [7:0] eta_dt;
    logic [7:0] o_spike_f_dec;
    logic [7:0] dec_err0;
    logic [7:0] dec_err1;
    logic [7:0] dec_err;
    logic [7:0] add_result;

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done   <= 0;
            index  <= 0;
            upd_ws <= 0;
            o_ws   <= '{default: '0};
        end
        else if (start) begin
            upd_ws      <= add_result;
            o_ws[index] <= add_result;
            index       <= index  + 1;
            done        <= 1;
        end
        else done <= 0;
    end

    FP_8_Add_Sub  Add_0(
        .A(mult_result),
        .B(i_ws),
        .add(1'b1),
        .Sum(add_result)
    );
    FP_8_Add_Sub  Add_1(
        .A(dec_err0),
        .B(dec_err1),
        .add(1'b1),
        .Sum(dec_err)
    );
    FP_8_Mult dec_err_0(
        .A(dec_t[0]),
        .B(i_err[0]),
        .product(dec_err0)
    );
    FP_8_Mult dec_err_1(
        .A(dec_t[1]),
        .B(i_err[1]),
        .product(dec_err1)
    );
    FP_8_Mult mult_inst(
        .A(i_spike_f),
        .B(dec_err),
        .product(o_spike_f_dec)
    );
    FP_8_Mult etadt(
        .A(Eta_W),
        .B(dt),
        .product(eta_dt)
    );
    FP_8_Mult result(
        .A(o_spike_f_dec),
        .B(eta_dt),
        .product(mult_result)
    );

endmodule