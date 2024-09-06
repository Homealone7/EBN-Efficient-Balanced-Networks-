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
    parameter learn_thresh      = 1006,
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
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  pot_thresh [N],
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0]  randn      [N],
    output  logic                                                 done
);

    integer i;
    logic wait_spike, learn_en, done_neuron, done_synaptic, done_dyn;
    logic done_lif_AU, done_spike_f, done_spike_f_buff, spike_flg, start_spike_f;                                                 
    logic [5:0] spike_pos;
    logic [11:0] wf_index, delay_counter;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_ws[N], i_wf_tmp[N], o_spike_f[N], i_cmd [Dims], old_cmd[Dims], o_err[Dims], old_err[Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] spike_f_data[N], old_spike_f_data[N];

    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin
            done <= 0;
        end
        else begin
            if (done_dyn) begin
                done <= 1;
            end
            else done <= 0;
        end 
    end
    
    always_ff @(posedge clk or posedge reset) begin 
        if (reset) begin
            wf_index <= 64;
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

    controller #(
        .N(N),
        .learn_thresh(learn_thresh), 
        .learn_flg(learn_flg) 
    ) controller_inst (
        .clk(clk),                              
        .reset(reset),
        .next_synaptic_update(next),          // Signal from the neuron core indicating next synaptic update
        .neuron_processing_done(done_lif_AU), // Signal from neuron core indicating neuron processing is complete
        .done_spike(done_spike),              // Signal from neuron core indicating spike processing is complete
        .learn_en(learn_en),                  // Output signal enabling learning
        .start_spike_filter(start_spike_f),   // Start signal for spike filtering
        .wait_spike(wait_spike),              // Output signal indicating the system is waiting for spikes Output
        .delay_counter(delay_counter)
    );

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
        .wait_spike(wait_spike),
        .i_dec(i_dec),
        .i_cmd(i_cmd),
        .i_err(o_err),
        .i_wf(i_wf_tmp),
        .i_ws(o_ws),
        .i_spike_f(spike_f_data),
        .pot_thresh(pot_thresh),
        .randn(randn),
        .spike_pos(spike_pos),
        .spike_flg(spike_flg),
        .next(next),
        .done_lif_AU(done_lif_AU),
        .done_spike(done_spike),
        .done(done_neuron)
    );

    synaptic_core #(
        .N(N),
        .Dims(Dims),
        .Eta_W(Eta_W),
        .dt(dt),
        .learn_thresh(learn_thresh),
        .learn_flg(learn_flg),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    )synaptic_core(
        .clk(clk),
        .reset(reset),
        .delay_counter(delay_counter),
        .i_dec(i_dec),
        .i_err(old_err),    
        .i_spike_f(old_spike_f_data),     
        .o_ws(o_ws),
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
