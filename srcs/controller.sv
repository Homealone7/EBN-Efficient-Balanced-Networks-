module controller #(
    parameter N             = 64,
    parameter learn_flg     = 1;
    parameter learn_thresh  = 1006   // Threshold for enabling learning  
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        load_complete,
    //input  logic        learn_flg,              // Flag to enable or disable learning
    input  logic        next_synaptic_update,   // Signal to start the next synaptic update
    input  logic        neuron_processing_done, // Done signal from LIF in neuron_core
    input  logic        done_dyn,
    input  logic        done_spike,             // Done signal from spike processing
    output logic        reset_iteration,        // Internal Reset Signal
    output logic        load_trigger_cmd,       // Command load trigger
    output logic        start_neuron,           // Start Nueron Core
    output logic        learn_en,               // Enable learning process       
    output logic        start_spike_filter,     // Start signal for spike filtering
    output logic        wait_spike              // Signal indicating wait for spike output
);

    // Internal signals
    logic [13:0] learning_cycle_counter;     // Learning counter
    logic [13:0] reset_iteration_counter;    // Synaptic weight update counter
    logic [6:0]  synaptic_update_counter;    // Synaptic weight update counter
    logic [6:0]  spike_filter_counter;       // Spike filter counter
    logic [5:0]  load_trigger_counter;       // Command load trigger counter           
    logic        reset_iteration_reg;
    logic        start_learning_counter;     // Internal signal to start learning counter
    logic        buff, buff_2;               // Buffer for spike filtering start signal           
    
    // Reset After 1 learning iteration
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            reset_iteration_counter <= 0;
            reset_iteration         <= 0;
            reset_iteration_reg     <= 0;
        end
        else begin
            reset_iteration <= reset_iteration_reg;
            if (done_dyn) begin
                if (reset_iteration_counter == 15000) begin
                    reset_iteration_counter <= 0;
                    reset_iteration_reg         <= 1;
                end
                else reset_iteration_counter <= reset_iteration_counter + 1;
            end
            else    reset_iteration_reg        <= 0;
        end  
    end

    // Signal to start Neuron Core 
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            start_neuron <= 0;
        end
        else start_neuron <= load_complete;
    end

    // Manage learning enable logic
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            learning_cycle_counter <= 0;
        end
        else if (start_learning_counter && !learn_en) begin
            learning_cycle_counter <= learning_cycle_counter + 1;
        end
    end
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            learn_en     <= 0;
        end
        else begin
            if ((learning_cycle_counter >= learn_thresh) && learn_flg) begin
                learn_en  <= 1;
            end
        end
    end
    
    // Manage the learning counter start
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            synaptic_update_counter <= 0;
            start_learning_counter  <= 0;
        end
        else begin
            if (next_synaptic_update) begin
                if (synaptic_update_counter == N - 2) begin              
                    start_learning_counter <= 1;
                end
                if (synaptic_update_counter >= N - 1) begin
                    synaptic_update_counter <= 0;
                end
                else begin
                    synaptic_update_counter <= synaptic_update_counter + 1;
                end
            end
            else begin
                start_learning_counter <= 0;
            end
        end             
    end

    // Load trigger for cmd Mem
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            load_trigger_counter <= 0;
            load_trigger_cmd     <= 0;
        end
        else begin
            if (next_synaptic_update) begin
                if (load_trigger_counter >= N - 1) begin
                    load_trigger_cmd <= 1;
                end
                load_trigger_counter <= load_trigger_counter + 1;
            end
            else load_trigger_cmd <= 0;
        end
    end

    // Manage start_spike_filter signal (spike filter logic)
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            start_spike_filter   <= 0;
            spike_filter_counter <= 0;
            buff                 <= 0;
            buff_2               <= 0;
        end 
        else begin
            buff   <= neuron_processing_done;
            buff_2 <= buff;
            if (buff_2) begin
                if (spike_filter_counter == N - 2) begin              
                    start_spike_filter <= 1;
                end
                if (spike_filter_counter >= N - 1) begin
                    spike_filter_counter <= 0;
                end 
                else begin
                    spike_filter_counter <= spike_filter_counter + 1;
                end
            end 
            else begin
                start_spike_filter <= 0;
            end
        end
    end

    // Manage wait_spike signal (Wait for spike output)
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            wait_spike <= 0;
        end
        else begin
            if (done_spike) begin
                wait_spike <= 0;
            end
            else if (spike_filter_counter == N - 1) begin
                wait_spike <= 1;
            end
        end 
    end

endmodule