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
    output  logic                                                 done
);

    integer i;

    // Signals from controller
    logic        [11:0]                                 delay_counter;
    logic                                               learn_en;
    logic                                               start_spike_filter;
    logic                                               wait_spike;

    // Signals from memory_manager
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf             [N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thresh       [N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] randn            [N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd            [Dims];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec            [N* Dims];

    // Delayed Signals for Synaptic_core
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] old_spike_f_data [N];
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] old_cmd          [Dims]; 
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] old_err          [Dims];

    // Signals from Synaptic_core
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_ws             [N];
    logic                                               done_synaptic;

    // Signals from Nueron_core
    logic        [5:0]                                  spike_pos;
    logic                                               done_lif_AU; 
    logic                                               done_neuron;
    logic                                               spike_flg;

    // Signals from spike_filter
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_spike_f        [N];
    logic                                               done_spike_f;
    
    // Signals from Desired_Dynamic
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_err            [Dims];
    logic                                               done_dyn; 

    // Signals for Spike_filter sync
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] spike_f_data     [N]; 
    logic                                               done_spike_f_buff;
    

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done               <= 0;
            done_spike_f_buff  <= 0;
        end
        else begin
            if (done_dyn) done <= 1;
            else          done <= 0;
            done_spike_f_buff  <= done_spike_f;
        end
    end

    // Instantiate the memory manager module
    memory_manager #(
        .N(N),
        .Dims(Dims),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) memory_inst (
        .clk(clk),
        .reset(reset),
        .i_wf(i_wf),
        .i_dec(i_dec),
        .pot_thresh(pot_thresh),
        .randn(randn),
        .i_cmd(i_cmd)
    );

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
        .start_spike_filter(start_spike_filter),   // Start signal for spike filtering
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
        .learn_en(learn_en),
        .delay_counter(delay_counter),
        .i_dec(i_dec),
        .i_err(old_err),    
        .i_spike_f(old_spike_f_data),     
        .o_ws(o_ws), 
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
        .start(start_spike_filter), 
        .i_spike_f(spike_f_data),    
        .o_spike_f(o_spike_f),    
        .done(done_spike_f)
    );

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

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spike_f_data     <= '{default: '0};
            old_spike_f_data <= '{default: '0};
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
        
endmodule