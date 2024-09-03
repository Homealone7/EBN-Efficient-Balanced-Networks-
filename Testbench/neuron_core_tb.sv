module neuron_core_tb;

    parameter N                 = 64;
    parameter Dims              = 2;
    parameter NzMemb            = 40'h 68DB8;
    parameter Gain_D            = 40'h 2000000;
    parameter K                 = 40'h 20C49B;
    parameter LambdaV           = 40'h 3200000000;
    parameter dt                = 40'h 68DB8;
    parameter One               = 40'h 100000000;
    parameter INTEGER_BITS      = 8;
    parameter FRACTIONAL_BITS   = 32;
    parameter A_ROWS            = 1;
    parameter B_COLS            = 1;

    integer counter = 0, mv;
    logic clk, reset, done, next, next_synaptic, start_ws, start_spike_f;
    
    logic                                                 spike_flg;                // Spike happened if = 1;
    logic         [5:0]                                   spike_pos;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec[N * Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd[Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_err[Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_spike[N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf[N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_ws[N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf_tmp[N*N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_ws_tmp[N*N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f[N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thr[N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] randn[N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_test[N];

    neuron_core #(
        .N(N),
        .Dims(Dims),
        .NzMemb(NzMemb),
        .Gain_D(Gain_D),
        .K(K),
        .One(One),
        .dt(dt),
        .LambdaV(LambdaV),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS)
    )Neuron(
        .clk(clk),
        .i_dec(i_dec),
        .i_cmd(i_cmd),
        .i_err(i_err),
        .i_wf(i_wf),
        .i_ws(i_ws),
        .o_spike(o_spike),
        .i_spike_f(i_spike_f),
        .pot_thr(pot_thr),
        .randn(randn),
        .spike_flg(spike_flg),
        .spike_pos(spike_pos),
        .reset(reset),
        .next(next),
        .next_synaptic(next_synaptic),
        .start_ws(start_ws),
        .start_spike_f(start_spike_f),  
        .done(done)
    );

    always begin
        #5 clk = ~clk; 
    end

    always_ff @(posedge clk) begin
        counter <= counter + 1;
        if (reset) begin
            mv <= 64;
            i_ws <= i_ws_tmp[0:63];
            i_wf <= i_wf_tmp[0:63];
        end
        if (next) begin
            if (mv < 4096) begin
            i_ws <= i_ws_tmp[63 + mv -: 64];
            i_wf <= i_wf_tmp[63 + mv -: 64];
            mv <= mv + 64;
            end     
        end
    end

    initial begin
        clk = 0;
        reset = 1;
        $readmemb("W_f.txt", i_ws_tmp);
        $readmemb("Wf_f.txt", i_wf_tmp);
        $readmemb("dec_f.txt", i_dec);
        $readmemb("e_f.txt", i_err);
        $readmemb("rO_f.txt", i_spike_f);
        $readmemb("ran_f.txt", randn);
        $readmemb("thres_f.txt", pot_thr);
        $readmemb("V_f.txt", pot_test);               
        #10
        reset = 0;
        $readmemb("V_f.txt", Neuron.Neuron_Memory.mem);
        for (int i = 0; i < Dims; i++) begin
            i_cmd[i]        = 0;
        end
        @(posedge done);
        #1000
        $finish;
    end
endmodule