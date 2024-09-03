module controller #(
    parameter N = 64
)(
    input logic        clk,
    input logic        reset,
    input logic        start,         // Start signal for the controller
    input logic        done_lif_AU,   // Done signal from lif_AU in neuron_core
    input logic        done_spike,    // Done signal when a spike occurs
    input logic        done_synaptic, // Done signal from synaptic_core
    output logic       next_synaptic, // Control signal to synaptic_core
    output logic       start_ws,      // Start signal for synaptic_core weight updates
    output logic       wait_spike,    // Wait signal for spikes
    output logic       start_spike_f, // Start signal for spike filter
    output logic       done,          // Overall done signal
    output logic [11:0] read_addr,    // Address to read synaptic weights
    output logic [11:0] write_addr,   // Address to write synaptic weights
    output logic       learn_en       // Enable learning process
);

    // Internal signals for control logic
    logic [6:0] spike_counter;
    logic [11:0] test_count;
    logic [1:0] wait_counter;

    // Manage next_synaptic signal
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            next_synaptic <= 0;
        else
            next_synaptic <= done_lif_AU;
    end

    // Generate wait_spike signal
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            wait_spike <= 0;
        else if (done_spike)
            wait_spike <= 0;
        else if (spike_counter == N - 1)
            wait_spike <= 1;
    end

    // Start weight updates in synaptic_core
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            spike_counter <= 0;
            start_ws <= 0;
        end else begin
            if (next_synaptic) begin
                if (spike_counter >= N - 1)
                    spike_counter <= 0;
                else
                    spike_counter <= spike_counter + 1;

                if (spike_counter == N - 2)
                    start_ws <= 1;
                else
                    start_ws <= 0;
            end
        end
    end

    // Control start_spike_f signal
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            start_spike_f <= 0;
        else if (done_lif_AU)
            start_spike_f <= (spike_counter == N - 2);
    end

    // Manage test_count for learning and weight updates
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            test_count <= 0;
            wait_counter <= 0;
        end else if (done_lif_AU && spike_counter == N - 2) begin
            wait_counter <= 2;
            test_count <= 0;
        end else if (wait_counter > 0) begin
            wait_counter <= wait_counter - 1;
        end else if (done_spike && spike_counter == 0) begin
            wait_counter <= 1;
        end else if (wait_counter > 0) begin
            wait_counter <= wait_counter - 1;
        end else if (test_count >= N + 1) begin
            test_count <= 0;
        end else if (learn_en) begin
            test_count <= test_count + 1;
        end
    end

    // Generate learning enable signal
    logic [31:0] learn_counter;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            learn_counter <= 0;
        end else if (start_ws) begin
            learn_counter <= learn_counter + 1;
        end
    end

    assign learn_en = (reset) ? 1'b0 : ((learn_counter > 100) && (start_ws)) ? 1'b1 : 1'b0;
    assign read_addr = test_count;
    assign write_addr = test_count;

    // Manage done signal for the overall process
    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            done <= 0;
        else if (done_spike)
            done <= 1;
        else
            done <= 0;
    end

endmodule
