module controller #(
    parameter N             = 64,
    parameter learn_thresh  = 1006,   // Threshold for enabling learning
    parameter learn_flg     = 1       // Flag to enable or disable learning
)(
    input logic         clk,
    input logic         reset,
    input logic         next_synaptic_update,   // Signal to start the next synaptic update
    input logic         neuron_processing_done, // Done signal from LIF in neuron_core
    input logic         done_spike,             // Done signal from spike processing
    output logic        learn_en,               // Enable learning process       
    output logic        start_spike_filter,     // Start signal for spike filtering
    output logic        wait_spike,             // Signal indicating wait for spike output
    output logic [11:0] delay_counter           // Delay counter to synchronize synaptic logic
);

    // Internal signals
    logic [6:0]     synaptic_update_counter;      // Synaptic weight update counter
    logic [31:0]    learning_cycle_counter;      // Learning counter
    logic [1:0]     sync_wait_counter;            // Wait counter for delay             
    logic [6:0]     spike_filter_counter;         // Spike filter counter
    logic           start_learning_counter;             // Internal signal to start learning counter
    logic           buff;                               // Buffer for spike filtering start signal
    

    // Enable learning if the counter exceeds the threshold and learn_flg is set
    assign learn_en = (reset) ? 1'b0 : ((learning_cycle_counter > learn_thresh) && learn_flg) ? 1'b1 : 1'b0;

    // Manage the learning counter start (internal start_learning_counter)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            synaptic_update_counter <= 0;
            start_learning_counter  <= 0;
        end
        else begin
            if (next_synaptic_update) begin
                if (synaptic_update_counter == N - 2) begin              
                    start_learning_counter <= 1;   // Signal to start the learning counter
                end
                if (synaptic_update_counter >= N - 1) begin
                    synaptic_update_counter <= 0;  // Reset the counter
                end
                else begin
                    synaptic_update_counter <= synaptic_update_counter + 1;  // Increment the counter
                end
            end
            else begin
                start_learning_counter <= 0;   // Keep the signal low when not active
            end
        end             
    end

    // Manage learning enable logic (learn_en)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            learning_cycle_counter <= 0;
        end
        else if (start_learning_counter) begin
            learning_cycle_counter <= learning_cycle_counter + 1;   // Increment the learning counter
        end
    end

    // Delay counter logic for synchronizing synaptic logic
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            sync_wait_counter <= 0;
            delay_counter     <= 0;
        end 
        else begin
            if (neuron_processing_done && spike_filter_counter == N - 2) begin
                sync_wait_counter <= 2;
                delay_counter     <= 0;
            end 
            else if (sync_wait_counter > 0) begin
                sync_wait_counter <= sync_wait_counter - 1;
                delay_counter     <= 0;
            end
            else begin
                if (done_spike && spike_filter_counter == 0) begin
                    sync_wait_counter <= 1;
                    delay_counter     <= 0;
                end 
                else if (sync_wait_counter > 0) begin
                    sync_wait_counter <= sync_wait_counter - 1;
                    delay_counter     <= 0;
                end 
                else begin
                    if (delay_counter >= N + 1) begin
                        delay_counter <= 0;
                    end 
                    else begin
                        if (learn_en) begin
                            delay_counter <= delay_counter + 1;  // Increment delay counter when learning is enabled
                        end
                    end
                end
            end
        end
    end

    // Manage start_spike_filter signal (spike filter logic)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            start_spike_filter <= 0;
            spike_filter_counter <= 0;
            buff          <= 0;
        end 
        else begin
            buff <= neuron_processing_done;  // Buffering the neuron_processing_done signal
            if (buff) begin
                if (spike_filter_counter == N - 2) begin              
                    start_spike_filter <= 1;  // Trigger spike filter start
                end
                if (spike_filter_counter >= N - 1) begin
                    spike_filter_counter <= 0;  // Reset the spike filter counter
                end 
                else begin
                    spike_filter_counter <= spike_filter_counter + 1;  // Increment the spike filter counter
                end
            end 
            else begin
                start_spike_filter <= 0;  // Disable spike filter start when not needed
            end
        end
    end

    // Manage wait_spike signal (Wait for spike output)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wait_spike <= 0;
        end
        else begin
            if (done_spike) begin
                wait_spike <= 0;  // No longer wait once spike is done
            end
            else if (spike_filter_counter == N - 1) begin
                wait_spike <= 1;  // Set to wait for spikes when spike filter processing is ongoing
            end
        end 
    end

endmodule