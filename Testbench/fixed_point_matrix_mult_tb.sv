`timescale 1ns / 1ps

module fixed_point_matrix_mult_tb;

parameter integer INTEGER_BITS = 8;
parameter integer FRACTIONAL_BITS = 8;
parameter integer A_ROWS = 2;
parameter integer B_COLS = 2;
parameter integer A_COLS_B_ROWS = 2;
parameter integer DATA_WIDTH = INTEGER_BITS + FRACTIONAL_BITS;

logic [1:0] state_debug;
integer i_debug , j_debug, k_debug, counter=0;

logic clk, reset, start, done;
logic signed [DATA_WIDTH-1:0] A [A_ROWS * A_COLS_B_ROWS];
logic signed [DATA_WIDTH-1:0] B [A_COLS_B_ROWS * B_COLS];
logic signed [DATA_WIDTH-1:0] C [A_ROWS * B_COLS];  // For capturing the result

fixed_point_matrix_mult #(
    .INTEGER_BITS(INTEGER_BITS),
    .FRACTIONAL_BITS(FRACTIONAL_BITS),
    .A_ROWS(A_ROWS),
    .B_COLS(B_COLS),
    .A_COLS_B_ROWS(A_COLS_B_ROWS)
) dut (
    .clk(clk),
    .reset(reset),
    .done(done),
    .A(A),
    .B(B),
    .C(C)
);

always begin
#5 clk = ~clk;
 // Generate a clock with a period of 10ns
end

always_ff @(posedge clk) begin
    state_debug <= dut.state;
    i_debug <= dut.i;
    j_debug <= dut.j;
    k_debug <= dut.k;
    counter = counter + 1;
end


initial begin
A = {16'b 00000001_10000000, 16'b 00000011_10000000, 16'b 00000010_10000000, 16'b 00000100_10000000}; // 1.5, 3.5, 2.5, 4.5
B = {16'b 00000001_10000000, 16'b 00000011_10000000, 16'b 00000010_10000000, 16'b 00000100_10000000}; // 1.5, 3.5, 2.5, 4.5
clk = 0;
reset = 1;
/*for (int i = 0; i < A_ROWS * A_COLS_B_ROWS; i++) begin
        A[i] = {7'b0, $random & 9'h1FF};
        B[i] = {7'b0, $random & 9'h1FF};
    end*/
#10
reset = 0; // Ensure reset is asserted for enough time

    wait(done);
    A = {16'b 00000100_10000000, 16'b 00000111_10000000, 16'b 00000010_10000000, 16'b 00000011_10000000}; // 4.5, 7.5, 2.5, 3.5
    B = {16'b 00000100_10000000, 16'b 00000111_10000000, 16'b 00000010_10000000, 16'b 00000011_10000000}; // 4.5, 7.5, 2.5, 3.5
    #15
    wait(done);
    $finish;
end
endmodule
