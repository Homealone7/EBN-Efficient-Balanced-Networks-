module EBN #(
    parameter N            = 64,
    parameter Dims         = 2,
    parameter dyn          = 16'h 4100, // 8
    parameter NzMemb       = 16'h 38d2, // 0.0001
    parameter Gain_D       = 16'h 3c00, // 0.0078125 (1/N/2) 
    parameter K            = 16'h 3a03, // 0.0005
    parameter LambdaV      = 16'h 4248, // 50
    parameter Lambda       = 16'h 4120, // 10
    parameter One          = 16'h 3f80, // 1
    parameter Three        = 16'h 4040, // 3
    parameter Eta_W        = 16'h 3e9a, // 0.3
    parameter dt           = 16'h 38d2, // 0.0001
    parameter learn_thresh = 1006,
    parameter ROWS_A       = 1,
    parameter COLS_B       = 1
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        init_signal,
    input  logic        learn_flg,
    output logic        reset_iteration,
    output logic        spike_flg_out,
    output logic [5:0]  spike_pos_out,
    output logic [15:0] o_x_0,
    output logic [15:0] o_x_1,
    output logic [15:0] o_x_est_0,
    output logic [15:0] o_x_est_1,
    output logic [15:0] pot_out,
    output logic [15:0] ws_out,
    output logic        done
);
    //24 Adders, 25 Multipliers
    assign done = done_dyn;
    assign o_x_0 = o_x[0];
    assign o_x_1 = o_x[1];
    assign o_x_est_0 = o_x_est[0];
    assign o_x_est_1 = o_x_est[1];
    assign ws_out = o_ws[0];
    assign spike_flg_out = spike_flg;
    assign spike_pos_out = spike_pos;
    assign pot_out = o_pot;
    integer i;
    // Signals from controller
    //logic        reset_iteration;
    logic        learn_en;
    logic        start_spike_filter;
    logic        wait_spike;
    logic        start_neuron;
    logic        load_trigger_cmd;
    logic        ws_start;

    // Signals from memory_manager
    logic        load_complete;
    logic [15:0] i_wf             [N];
    logic [15:0] pot_thresh       [N];
    logic [15:0] randn            [N];
    logic [15:0] i_cmd            [Dims];
    logic [15:0] i_dec            [N* Dims];

    // Delayed Signals for Synaptic_core
    logic [15:0] old_spike_f_data [N];
    logic [15:0] old_err          [Dims];

    // Signals from Synaptic_core
    logic        done_synaptic;
    logic [15:0] o_ws             [N];

    // Signals from Nueron_core
    logic        spike_flg;
    logic        done_lif_AU; 
    logic        done_neuron;
    logic        done_spike;
    logic        next_ws;
    logic        load_trigger_wf;
    logic [5:0]  spike_out_index;
    logic [5:0]  spike_pos;
    logic [15:0] o_pot;

    // Signals from spike_filter
    logic        done_spike_f;
    logic [15:0] spife_f_add;
    logic [15:0] o_spike_f        [N];
    
    // Signals from Desired_Dynamic
    logic        done_dyn; 
    logic [15:0] o_err       [Dims];
    logic [15:0] o_x         [Dims];
    logic [15:0] o_x_est     [Dims];

    // Signals for Spike_filter sync
    logic [15:0] spike_f_data     [N]; 
    logic        done_spike_f_buff;

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done_spike_f_buff   <= 0;
        end
        else begin
            done_spike_f_buff   <= done_spike_f;
        end
    end 

    // Instantiate the memory manager module
    memory_manager #(
        .N(N),
        .Dims(Dims)
    ) u_memory_manager (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .load_trigger_cmd(load_trigger_cmd),  // Signal to start i_cmd loading
        .load_trigger_wf(load_trigger_wf),   // Signal to i_wf loading
        .start_neuron(start_neuron),
        .load_mem(load_mem),            // Initialization signal
        .load_complete(load_complete),        // Load completion flag
        .i_wf(i_wf),
        .i_dec(i_dec),
        .pot_thresh(pot_thresh),
        .randn(randn),
        .i_cmd(i_cmd)
    );

    controller #(
        .N(N),
        .learn_thresh(learn_thresh)
    ) controller_inst (
        .clk(clk),                              
        .reset(reset),
        .learn_flg(learn_flg),
        .load_complete(load_complete),
        .init_signal(init_signal),
        .next_synaptic_update(next_ws),       // Signal from the neuron core indicating next synaptic update
        .neuron_processing_done(done_lif_AU), // Signal from neuron core indicating neuron processing is complete
        .done_dyn(done_dyn),
        .done_spike(done_spike),              // Signal from neuron core indicating spike processing is complete
        .reset_iteration(reset_iteration),
        .load_mem(load_mem),
        .load_trigger_cmd(load_trigger_cmd),
        .start_neuron(start_neuron),
        .learn_en(learn_en),                  // Output signal enabling learning
        .start_spike_filter(start_spike_filter),   // Start signal for spike filtering
        .wait_spike(wait_spike)               // Output signal indicating the system is waiting for spikes Output
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
        .ROWS_A(ROWS_A),
        .COLS_B(COLS_B)
    )Neuron(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_neuron),
        .wait_spike(wait_spike),
        .i_dec(i_dec),
        .i_cmd(i_cmd),
        .i_err(o_err),
        .i_wf(i_wf),
        .i_ws(o_ws),
        .i_spike_f(spike_f_data),
        .pot_thresh(pot_thresh),
        .randn(randn),
        .o_pot(o_pot),
        .spike_out_index(spike_out_index),
        .spike_pos(spike_pos),
        .spike_flg(spike_flg),
        .ws_start(ws_start),
        .next(next_ws),
        .load_trigger_wf(load_trigger_wf),
        .done_lif_AU(done_lif_AU),
        .done_spike(done_spike),
        .done(done_neuron)
    );

    synaptic_core #(
        .N(N),
        .Dims(Dims),
        .Eta_W(Eta_W),
        .dt(dt),
        .learn_thresh(learn_thresh)
    )synaptic_core(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .load_mem(load_mem),
        .learn_en(learn_en),
        .ws_start(ws_start),
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
        .One(One)
    )spike_f(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_spike_filter), 
        .i_spike_f(spike_f_data),    
        .o_spike_f(o_spike_f),    
        .done(done_spike_f)
    );

    Dynamic_Error #(
        .N(N),              
        .Dims(Dims),           
        .dyn(dyn),            
        .Lambda(Lambda),
        .dt(dt),
        .One(One),
        .Three(Three)     
    )Dynamic(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(done_spike_f_buff),
        .i_cmd(i_cmd),
        .i_dec(i_dec),
        .spike_pos(spike_pos),
        .spike_flg(spike_flg),
        .o_err(o_err),
        .o_x(o_x),
        .o_x_est(o_x_est),
        .done(done_dyn)
    );

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            spike_f_data     <= '{default: '0};
            old_spike_f_data <= '{default: '0};
            old_err          <= '{default: '0};
        end
        else begin
            if (spike_out_index == N - 1) begin
                old_spike_f_data <= spike_f_data;
                old_err[0]  <= o_err[0];
                old_err[1]  <= o_err[1];
            end
            if (done_spike_f_buff) begin
                for (i = 0; i < N; i++) begin
                    spike_f_data[i] <= (spike_flg && (i == spike_pos))? spife_f_add : o_spike_f[i];
                end
            end 
        end         
    end
    BF16_Add Add_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_spike_f[spike_pos]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(16'h3f80),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(spife_f_add)
    );
     
endmodule