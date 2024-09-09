module memory_manager #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32
)(
    input  logic                                                clk,
    input  logic                                                reset,
    input  logic                                                load_trigger,   // Signal to start i_wf & i_cmd loading
    input  logic                                                init_signal,     // Signal to start initialization (from init module)
    output logic                                                load_complete,   // Flag to indicate loading completion
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf       [N],
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec      [Dims * N],
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thresh [N],
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] randn      [N],
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd      [Dims]
);

    // BRAM interfaces for i_wf, i_dec, pot_thresh, randn, and i_cmd (preloaded from COE files)
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf_data;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec_data;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thresh_data;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] randn_data;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] cmd_data;

    // Index counters for loading data
    logic [6:0] dec_index;       
    logic [5:0] pot_thresh_index;
    logic [5:0] randn_index;
    
    // BRAM address control for i_wf and i_cmd
    logic        cmd_loading;
    logic [13:0] cmd_global_index;
    logic [0:0]  cmd_index;
    logic        wf_loading;
    logic [5:0]  wf_global_index;
    logic [5:0]  wf_index;
    
    // Instantiate BRAMs for the preloaded memory
    i_wf_bram u_i_wf_bram (
        .clka(clk),
        .addra({wf_global_index, wf_index}),  // Address based on global and local index
        .douta(i_wf_data)  // Fast weights output
    );

    cmd_bram u_cmd_bram (
        .clka(clk),
        .addra({cmd_global_index, cmd_index}),  // Address based on global and local index
        .douta(cmd_data)  // Command output
    );

    i_dec_bram u_i_dec_bram (
        .clka(clk),
        .addra(dec_index),
        .douta(i_dec_data)  // Decoder output
    );

    pot_thresh_bram u_pot_thresh_bram (
        .clka(clk),
        .addra(pot_thresh_index),
        .douta(pot_thresh_data)  // Threshold output
    );

    rand_bram u_rand_bram (
        .clka(clk),
        .addra(randn_index),
        .douta(randn_data)  // Random number output
    );

    // Initialization logic for i_dec, pot_thresh, and randn
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            i_dec            <= '{default: '0};
            pot_thresh       <= '{default: '0};
            randn            <= '{default: '0};
            dec_index        <= 0;
            randn_index      <= 0;
            pot_thresh_index <= 0;
            load_complete    <= 0;
        end 
        else if (init_signal && !load_complete) begin
            // Load BRAM data only once when the init_signal is active
            if (dec_index < Dims * N) begin
                i_dec[dec_index] <= i_dec_data;
                dec_index <= dec_index + 1;
            end

            if (pot_thresh_index < N) begin
                pot_thresh[pot_thresh_index] <= pot_thresh_data;
                pot_thresh_index <= pot_thresh_index + 1;
            end

            if (randn_index < N) begin
                randn[randn_index] <= randn_data;
                randn_index <= randn_index + 1;
            end

            if (dec_index == Dims * N && pot_thresh_index == N && randn_index == N) begin
                load_complete <= 1;  // Set load_complete when everything is loaded
            end
        end
    end

    // Logic to update i_wf (64 elements, 1 per clock cycle)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            wf_index        <= 0;
            wf_global_index <= 0;
            wf_loading      <= 0;
            i_wf            <= '{default: '0};
        end 
        else if (load_trigger && !wf_loading) begin
            wf_loading <= 1;  // Start loading when load_trigger is set
        end 
        else if (wf_loading) begin
            if (wf_index < 63) begin
                i_wf[wf_index] <= i_wf_data;  // Load first 63 elements
                wf_index <= wf_index + 1;
            end 
            else if (wf_index == 63) begin
                i_wf[wf_index] <= i_wf_data;  // Load last element
                wf_loading <= 0;
                wf_index   <= 0;
                wf_global_index <= wf_global_index + 1;  // Move to next block of 64 elements
            end
        end
    end

    // Logic to update i_cmd (2 elements, 1 per clock cycle)
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            cmd_index        <= 0;
            cmd_global_index <= 0;
            cmd_loading      <= 0;
            i_cmd            <= '{default: '0};
        end 
        else if (load_trigger && !cmd_loading) begin
            cmd_loading <= 1;
        end 
        else if (cmd_loading) begin
            if (cmd_index == 0) begin
                i_cmd[cmd_index] <= cmd_data;  // Load 1st element
                cmd_index <= cmd_index + 1;
            end 
            else if (cmd_index == 1) begin
                i_cmd[cmd_index] <= cmd_data;  // Load 2nd element
                cmd_loading <= 0;
                cmd_index   <= 0;
                cmd_global_index <= cmd_global_index + 1;  // Move to next block of 2 elements
            end
        end
    end

endmodule