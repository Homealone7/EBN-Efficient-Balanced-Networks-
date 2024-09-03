module EBN #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter dyn               = 40'h 800000000,
    parameter NzMemb            = 40'h 68DB8,
    parameter Gain_D            = 40'h 2000000,
    parameter K                 = 40'h 20C49B,
    parameter LambdaV           = 40'h 3200000000,
    parameter Lambda            = 40'h A00000000,
    parameter One               = 40'h 100000000,
    parameter Three             = 40'h300000000,
    parameter Eta_W             = 40'h 4CCCCCCC, //learning rate
    parameter dt                = 40'h 68DB8,
    parameter learn             = 100,
    parameter learn_flg         = 1,
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32,
    parameter A_ROWS            = 1,
    parameter B_COLS            = 1
) (
    input   logic                                                 clk,
    input   logic                                                 reset,
    input   logic                                                 start_neuron,
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  i_dec      [Dims * N],
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  i_wf       [N * N],
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  pot_thr    [N],
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  randn      [N],
    output  logic                                                 done
);

    integer i;
    logic wait_spike, next_synaptic, start_ws, learn_en, done_neuron, done_synaptic, done_dyn;
    logic done_lif_AU, done_spike_f, done_spike_f_buff, spike_flg, start_spike_f, buff, buff_2, start_spike_filter;                                                 
    logic [5:0] spike_pos;
    logic [11:0] wf_index;
    logic [6:0] spike_f_counter, l;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_ws[N], i_wf_tmp[N], o_spike[N], o_spike_f[N], old_spike_f_data[N], i_cmd [Dims], old_cmd[Dims], o_err[Dims], old_err[Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] spike_f_data[N];

    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin
            done <= 0;
            buff <= 0;
            buff_2 <= 0;
            start_spike_filter <= 0;
        end
        else begin
            buff <= start_spike_f;
            buff_2 <= buff;
            start_spike_filter <= buff_2;
            if (done_spike_f) begin
                done <= 1;
            end
            else done <= 0;
        end 
    end
    
    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin
            wf_index <= 64;
            l <= 0;
            i_wf_tmp <= i_wf[0:63];
            i_cmd[0] <= 0;
            i_cmd[1] <= 0;
        end
        else begin
            if (wait_spike) begin
                if (Neuron.done_spike) begin
                    wf_index <= 64;
                    i_wf_tmp <= i_wf[0:63];
                end
            end
            else begin
                if (Neuron.done_lif_AU) begin
                    wf_index <= wf_index + 64;
                    i_wf_tmp <= i_wf[wf_index +: 64];
                end
            end
        end           
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done_spike_f_buff  <= 0;
        end
        else begin
            done_spike_f_buff  <= done_spike_f;
        end
    end

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
        .reset(reset),
        .start(start_neuron),
        .i_dec(i_dec),
        .i_cmd(i_cmd),
        .i_err(o_err),
        .i_wf(i_wf_tmp),
        .i_ws(o_ws),
        .i_spike_f(spike_f_data),
        .pot_thr(pot_thr),
        .randn(randn),
        .o_spike(o_spike),
        .spike_pos(spike_pos),
        .spike_flg(spike_flg), 
        .next_synaptic(next_synaptic),
        .start_ws(start_ws),
        .wait_spike(wait_spike),
        .start_spike_f(start_spike_f),
        .done(done_neuron)
    );

    synaptic_core #(
        .N(N),
        .Dims(Dims),
        .Eta_W(Eta_W),
        .dt(dt),
        .learn(learn),
        .learn_flg(learn_flg),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS)
    )synaptic_core(
        .clk(clk),
        .reset(reset),
        .start_ct(start_ws),
        .i_dec(i_dec),
        .i_err(old_err),    
        .i_spike_f(old_spike_f_data),     
        .o_ws(o_ws),
        .next(next_synaptic),
        .wait_spike(wait_spike),
        .start_count(Neuron.done_spike),
        .spike_f_counter(Neuron.spike_f_counter),
        .done_lif_AU(Neuron.done_lif_AU),
        .learn_en(learn_en),     
        .done(done_synaptic)
    );

    spike_filter #(
        .N(N),
        .Lambda(Lambda),
        .dt(dt),
        .One(One),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    )spike_f(
        .clk(clk),
        .reset(reset),
        .start(start_spike_f), 
        .i_spike_f(spike_f_data),    
        .o_spike_f(o_spike_f),    
        .done(done_spike_f)
    );

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < N; i++) begin
                spike_f_data[i] <= 0;
                old_spike_f_data [i] <= 0;
            end
            old_err[0]  <= 0;
            old_err[1]  <= 0;
            old_cmd[0]  <= 0;
            old_cmd[1]  <= 0;
        end
        else begin
            if (Neuron.spike_out_index == N - 1) begin
                old_spike_f_data <= spike_f_data;
                old_err[0]  <= o_err[0];
                old_err[1]  <= o_err[1];
                old_cmd[0]  <= i_cmd[0];
                old_cmd[1]  <= i_cmd[1];
            end
            if (done_spike_f_buff) begin
                for (i = 0; i < N; i++) begin
                    spike_f_data[i] <= (spike_flg && (i == spike_pos))? o_spike_f[i] + { {(INTEGER_BITS - 1){1'b0}}, 1'b1, {(FRACTIONAL_BITS){1'b0}} }: o_spike_f[i];
                end
            end 
        end         
    end

    Desired_Dynamic #(
    .N(N),              
    .Dims(Dims),           
    .dyn(dyn),            
    .Lambda(Lambda),
    .dt(dt),
    .One(One),
    .Three(Three),         
    .INTEGER_BITS(INTEGER_BITS),   
    .FRACTIONAL_BITS(FRACTIONAL_BITS)        
    )Dynamic(
    .clk(clk),
    .reset(reset),
    .start(done_spike_f_buff),
    .i_cmd(i_cmd),
    .i_dec(i_dec),
    .spike_pos(spike_pos),
    .spike_flg(spike_flg),
    .o_err(o_err),
    .done(done_dyn)
    );
        
endmodule