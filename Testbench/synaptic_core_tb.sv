module synaptic_core_tb;

    parameter N                 = 64;
    parameter Dims              = 2;
    parameter Eta_W             = 40'h 4CCCCCCC;
    parameter dt                = 40'h 68DB8;                                                         
    parameter INTEGER_BITS      = 8;
    parameter FRACTIONAL_BITS   = 32;
    parameter A_ROWS            = 1;
    parameter B_COLS            = 1;
    parameter learn_flg         = 1;

    integer counter = 0, mv;

    logic                                                clk;
    logic                                                reset;
    logic                                                start_ct;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec      [Dims * N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_err      [Dims];    
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f  [N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_ws_tmp[N*N];       
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_ws       [N];       
    logic                                                done;

    synaptic_core #(
        .N(N),
        .Dims(Dims),
        .Eta_W(Eta_W),
        .dt(dt),
        .learn_flg(learn_flg),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS)
    )synaptic_core(
        .clk(clk),
        .reset(reset),
        .start_ct(start_ct),
        .i_dec(i_dec),
        .i_err(i_err),    
        .i_spike_f(i_spike_f),     
        .o_ws(o_ws),     
        .done(done)
    );

    always begin
        #5 clk = ~clk; 
    end

    always_ff @(posedge clk) begin
        counter <= counter + 1;
    end

    initial begin
        clk = 0;
        reset = 1;
        $readmemb("dec_f.txt", i_dec);
        $readmemb("e_f.txt", i_err);
        $readmemb("rO_f.txt", i_spike_f);               
        #10
        reset = 0;
        start_ct = 1;
        $readmemb("W_f.txt", synaptic_core.Synaptic_Memory.mem);
        @(posedge done);
        #50
        $finish;
    end

endmodule