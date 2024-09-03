`timescale 1ns / 1ps

module lif_AU_tb;


localparam N = 64;
localparam Dims = 2;
localparam INTEGER_BITS = 8;
localparam FRACTIONAL_BITS = 32;
integer counter = 0;

logic done_dec_cmd, done_dec_err, done_wf_spike, done_ws_spike_f;

logic clk, reset;
logic signed [39:0] dec [128];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec_t[Dims];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd[Dims];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_err[Dims];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf[N];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_ws[N];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f[N], spike[N];
logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] v_out, randn, dec_cmd[1], wf_spike[1], ws_spike_f_dt, dec_err_k;
logic done;

always_comb begin
    done_dec_cmd = uut.done_dec_cmd;
    done_dec_err = uut.done_dec_err;
    done_wf_spike = uut.done_wf_spike;
    done_ws_spike_f= uut.done_ws_spike_f;
    dec_cmd = uut.o_dec_cmd;
    wf_spike = uut.o_wf_spike;
    ws_spike_f_dt= uut.ws_spike_f_dt;
    dec_err_k =  uut.dec_err_k;
end

lif_AU #(
    .N(N),
    .Dims(Dims),
    .NzMemb(40'h68DB8),
    .Gain_D(40'h2000000),
    .K(40'h20C49B),
    .dt(40'h68DB8),
    .INTEGER_BITS(INTEGER_BITS),
    .FRACTIONAL_BITS(FRACTIONAL_BITS),
    .A_ROWS(1),
    .B_COLS(1)
) uut (
    .clk(clk),
    .i_dec_t(i_dec_t),
    .i_cmd(i_cmd),
    .i_err(i_err),
    .i_wf(i_wf),
    .i_ws(i_ws),
    .i_spike(spike),
    .i_spike_f(i_spike_f),
    .randn(randn),
    .reset(reset),
    .v_out(v_out),
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
    randn = 40'b 1111111101011001110110100011101111100000;
    $readmemb("dec_f.txt", dec);
    i_dec_t[0] = dec[0];
    i_dec_t[1] = dec[64];
    for (int i = 0; i < Dims; i++) begin
        //i_dec_t[i]      = 0;
        i_cmd[i]        = 0;
        i_err[i]        = 0;
    end
    for (int i = 0; i < N; i++) begin
        i_wf[i]         = 0;
        i_ws[i]         = 0;
        spike[i]      = 0;
        i_spike_f[i]    = 0;
    end
    #10
    reset = 0;
    @(posedge done);
    #15

    $display("Time: %t, Result: %h, Done: %b", $time, v_out, done);
    $display("\tDone Flags - Dec Cmd: %b, Dec Err: %b, Wf Spike: %b, Ws Spike F: %b", uut.done_dec_cmd, uut.done_dec_err, uut.done_wf_spike, uut.done_ws_spike_f);
    $display("\tMatrix Multiplication Outputs - Dec Cmd: %p, Dec Err: %p, Wf Spike: %p, Ws Spike F: %p", uut.o_dec_cmd, uut.o_dec_err, uut.o_wf_spike, uut.o_ws_spike_f);
    $finish;
end

endmodule
