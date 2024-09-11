module dynamic #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter dyn               = 40'h 800000000,
    parameter dt                = 40'h 68DB8,
    parameter Three             = 40'h 300000000,
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32,
    parameter A_ROWS            = 1,
    parameter B_COLS            = 1
)(
    input   logic                                                clk,
    input   logic                                                reset,
    input   logic                                                start,
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd       [Dims],    // Commands
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_x         [Dims],    // Desired X FROM MEM
    output  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_x         [Dims],
    output  logic                                                done
);  
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] neg_dyn; 
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] step; 
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] x0;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] x1;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] x0_dyn;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0] temp1;

    assign neg_dyn  = -dyn;
    assign temp1    = x0_dyn - i_x[0]; // x[1] = position, x[0] = velocity

    always_ff @(posedge clk) begin
        if (reset) begin
            o_x <= '{default: '0};
            done   <= 0;
        end 
        else begin
            if (start) begin
                o_x[0] <= i_x[0] + (x0 + i_cmd[0]);
                o_x[1] <= i_x[1] + (x1 + i_cmd[1]);
                done   <= 1;
            end
            else done <= 0;
            
        end
    end

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) mult_0 (
        .a(dt),
        .b(Three),
        .result(step),
        .overflow()
    );
    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) mult_1 (
        .a(step),
        .b(i_x[0]),
        .result(x1),
        .overflow()
    );
    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) mult_2 (
        .a(neg_dyn),
        .b(i_x[1]),
        .result(x0_dyn),
        .overflow()
    );
    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) mult_3 (
        .a(temp1),
        .b(step),
        .result(x0),
        .overflow()
    );
        
endmodule
