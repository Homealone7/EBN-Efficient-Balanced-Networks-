module dynamic #(
    parameter N      = 64,
    parameter Dims   = 2,
    parameter dyn    = 8'h 48,
    parameter dt     = 8'h 07,
    parameter Three  = 8'h 42
)(
    input  logic       clk,
    input  logic       reset,
    input  logic       reset_iteration,
    input  logic       start,
    input  logic [7:0] i_cmd [Dims],    // Commands
    input  logic [7:0] i_x   [Dims],    // Desired X FROM MEM
    output logic [7:0] o_x   [Dims],
    output logic       done
);  
    logic [7:0] neg_dyn; 
    logic [7:0] step; 
    logic [7:0] x0;
    logic [7:0] x1;
    logic [7:0] x0_cmd;
    logic [7:0] x1_cmd;
    logic [7:0] o_x0;
    logic [7:0] o_x1;
    logic [7:0] x0_dyn;
    logic [7:0] temp1;

    assign neg_dyn  = dyn ^ 8'h80;
    FP_8_Mult Mult_0(
        .A(dt),
        .B(Three),
        .product(step) // step = 3 * dt
    );
    // X[0]
    FP_8_Mult Mult_1(
        .A(neg_dyn),
        .B(i_x[1]),
        .product(x0_dyn) // x0_dyn = -dynprm * x(1)
    );
    FP_8_Mult Mult_2(
        .A(temp1),
        .B(step),
        .product(x0)  // x0 = temp1 * step
    );
    FP_8_Add_Sub  Sub_0(
        .A(x0_dyn),
        .B(i_x[0]),
        .add(1'b0),
        .Sum(temp1) // temp1 = x0_dyn - x(0)
    );
    FP_8_Add_Sub  Add_0(
        .A(x0),
        .B(i_cmd[0]),
        .add(1'b1),
        .Sum(x0_cmd) // x0_cmd = x0 + c[0]
    );
    FP_8_Add_Sub  Add_1(
        .A(x0_cmd),
        .B(i_x[0]),
        .add(1'b1),
        .Sum(o_x0)
    );
    // X[1]
    FP_8_Mult Mult_3(
        .A(step),
        .B(i_x[0]),
        .product(x1) // x1 = step * x[0]
    );
    FP_8_Add_Sub  Add_2(
        .A(x1),
        .B(i_cmd[1]),
        .add(1'b1),
        .Sum(x1_cmd) // x1_cmd = x1 + c[1]
    );
    FP_8_Add_Sub  Add_3(
        .A(x1_cmd),
        .B(i_x[1]),
        .add(1'b1),
        .Sum(o_x1)
    );

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            o_x <= '{default: '0};
            done   <= 0;
        end 
        else begin
            if (start) begin
                o_x[0] <= o_x0;
                o_x[1] <= o_x1;
                done   <= 1;
            end
            else done <= 0;
            
        end
    end
       
endmodule