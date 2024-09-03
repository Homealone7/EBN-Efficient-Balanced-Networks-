module learn_rule_tb;

    parameter N                 = 64;
    parameter Dims              = 2;
    parameter Eta_W             = 40'h 4CCCCCCC;
    parameter dt                = 40'h 68DB8;                                                         
    parameter INTEGER_BITS      = 8;
    parameter FRACTIONAL_BITS   = 32;
    parameter A_ROWS            = 1;
    parameter B_COLS            = 1;

    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_dec_err[1], i_ws, i_spike_f, o_ws;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec[N * Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_err[Dims], dec_t[Dims];
    logic clk, reset, start;
    integer counter = 0; 

    fixed_point_matrix_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(1),
        .B_COLS(1),
        .A_COLS_B_ROWS(Dims)
    ) dec_err (
        .clk(clk),
        .reset(reset),
        .done(done_dec_err),
        .A(dec_t),
        .B(i_err),
        .C(o_dec_err)
    ); 

    learn_rule #(
        .N(N),
        .Dims(Dims),
        .dt(dt),
        .Eta_W(Eta_W),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS)
    )learn(
        .clk(clk),
        .reset(reset),
        .start(done_dec_err),
        .dec_err(o_dec_err),
        .i_ws(i_ws),
        .i_spike_f(i_spike_f),   
        .o_ws(o_ws),
        .done(done)
    ); 

always begin
        #5 clk = ~clk; 
    end

    always_ff @(posedge clk) begin
        counter = counter + 1;
    end

    initial begin
        clk = 0;
        reset = 1;
        $readmemb("dec_f.txt", i_dec);
        $readmemb("e_f.txt", i_err);
        dec_t[0] = i_dec[61];
        dec_t[1] = i_dec[125];                   
        i_ws        = 40'b 00000000_00000000000001000010100010110011;
        i_spike_f   = 40'b 00000011_10100100110101111111101100100110;
        #15
        reset = 0;
        start = 1;
        #10
        start = 0;
        @(posedge done);
        #100
        $finish;
    end
endmodule