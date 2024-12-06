module memory_manager #(
    parameter N    = 64,
    parameter Dims = 2
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        load_trigger_cmd, // Signal to start wf & cmd loading
    input  logic        load_trigger_wf,  // Signal to start wf & cmd loading
    input  logic        start_neuron,     // Signal from neuron core
    input  logic        load_mem,      // Signal to start initialization (from init module)
    output logic        load_complete,    // Flag to indicate loading completion
    output logic [31:0] i_wf       [N],
    output logic [31:0] i_dec      [Dims * N],
    output logic [31:0] pot_thresh [N],
    output logic [31:0] randn      [N],
    output logic [31:0] i_cmd      [Dims]
);

    // BRAM interfaces for i_wf, i_dec, pot_thresh, randn, and i_cmd (preloaded from COE files)
    logic [31:0]  pot_thresh_data;
    logic [31:0]  i_wf_data;
    logic [31:0]  i_dec_data;
    logic [31:0]  randn_data;
    logic [31:0]  cmd_data;
    // BRAM read delay
    logic [1:0]   read_delay_counter_init;
    logic [1:0]   read_delay_counter_cmd;
    logic [1:0]   read_delay_counter_wf;
    // Memory Read Adrr
    logic [14:0]  cmd_addr;
    logic [11:0]  wf_addr;
    logic [6:0]   dec_addr;
    logic [5:0]   pot_thresh_addr;
    logic [5:0]   randn_addr;
    // Memory Enable
    logic         cmd_en;
    logic         wf_en;
    logic         dec_en;
    logic         pot_thresh_en;
    logic         randn_en;
    // Index counters for loading data (write addr)
    logic [6:0]   dec_index;       
    logic [5:0]   pot_thresh_index;
    logic [5:0]   randn_index;
    logic [5:0]   wf_index;
    logic [0:0]   cmd_index;
    // Write Complete
    logic         load_complete_thr;
    logic         load_complete_cmd;
    logic         load_complete_wf;
    logic         cmd_loading;
    logic         wf_loading;
    
    // Instantiate BRAMs for the preloaded memory
    cmd_bram u_cmd_bram (
        .clka(clk),
        .addra(cmd_addr),
        .ena(cmd_en),
        .douta(cmd_data)  // Command output
    );

    i_wf_bram u_i_wf_bram (
        .clka(clk),
        .addra(wf_addr),
        .ena(wf_en),
        .douta(i_wf_data)  // Fast weights output
    );

    i_dec_bram u_i_dec_bram (
        .clka(clk),
        .addra(dec_addr),
        .ena(dec_en),
        .douta(i_dec_data)  // Decoder output
    );

    pot_thresh_bram u_pot_thresh_bram (
        .clka(clk),
        .addra(pot_thresh_addr),
        .ena(pot_thresh_en),
        .douta(pot_thresh_data)  // Threshold output
    );

    rand_bram u_rand_bram (
        .clka(clk),
        .addra(randn_addr),
        .ena(randn_en),
        .douta(randn_data)  // Random number output
    );

    // Initialization logic for i_dec
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            i_dec                   <= '{default: '0};
            dec_en                  <= 1;
            dec_addr                <= 0;
            dec_index               <= 0;
            load_complete           <= 0;
            read_delay_counter_init <= 0;
        end 
        else if (load_mem && !load_complete) begin
            // BRAM read delay
            if (read_delay_counter_init < 2) begin
                dec_addr                <= dec_addr + 1;
                read_delay_counter_init <= read_delay_counter_init + 1;
            end
            else begin
                if (dec_index < Dims * N) begin
                    i_dec[dec_index] <= i_dec_data;
                    dec_index        <= dec_index + 1;
                    dec_addr         <= dec_addr + 1;
                end
            end
            // Load Complete
            if (dec_index == ((Dims * N) - 1)) begin
                load_complete <= 1;  // Set load_complete when everything is loaded
                dec_en        <= 0;
            end
        end
    end

    // Logic to update pot_thresh & randn
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            pot_thresh        <= '{default: '0};
            randn             <= '{default: '0};
            pot_thresh_en     <= 1;
            randn_en          <= 1;
            pot_thresh_index  <= 0;
            pot_thresh_addr   <= 0;
            randn_index       <= 0;
            randn_addr        <= 0;
            load_complete_thr <= 0;
        end
        else if (load_mem && !load_complete_thr) begin
            // BRAM read delay
            if (read_delay_counter_init < 2) begin
                pot_thresh_addr <= pot_thresh_addr + 1;
                randn_addr      <= randn_addr + 1;
            end
            else begin
                // Update pot_thresh
                if (pot_thresh_index < N) begin
                    pot_thresh[pot_thresh_index] <= pot_thresh_data;
                    pot_thresh_index             <= pot_thresh_index + 1;
                    pot_thresh_addr              <= pot_thresh_addr + 1;
                end
                // Update randn
                if (randn_index < N) begin
                    randn[randn_index] <= randn_data;
                    randn_index        <= randn_index + 1;
                    randn_addr         <= randn_addr + 1;
                end
            end
            // Load Complete
            if (pot_thresh_index == N - 1) begin
                load_complete_thr <= 1;
                pot_thresh_en     <= 0;
                randn_en          <= 0;
            end
        end
    end

    // Logic to update i_wf (64 elements, 1 per clock cycle) including init signal
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            i_wf                  <= '{default: '0};
            wf_en                 <= 1;
            wf_index              <= 0;
            wf_addr               <= 0;
            wf_loading            <= 0;
            load_complete_wf      <= 0;
            read_delay_counter_wf <= 0;
            
        end 
        else if (load_mem && !load_complete_wf) begin
            // Load the first 64 elements when the init signal is active
            if (read_delay_counter_init < 2) begin
                wf_addr        <= wf_addr + 1;
            end
            else begin
                if (wf_index < N - 1) begin
                    i_wf[wf_index] <= i_wf_data;  
                    wf_index       <= wf_index + 1;
                    if (wf_index < N - 2) begin
                        wf_addr        <= wf_addr + 1;
                    end
                end 
                else if (wf_index == N - 1) begin
                    i_wf[wf_index]   <= i_wf_data;  // Load last element
                    wf_index         <= 0;
                    load_complete_wf <= 1;
                end
            end
        end 
        else if (load_trigger_wf && start_neuron && !wf_loading && load_complete_wf) begin
            wf_loading              <= 1;  // Start loading when load_trigger_wf is set
            read_delay_counter_wf   <= 0;
        end 
        else if (wf_loading) begin
            if (read_delay_counter_wf < 2) begin
                wf_addr                 <= wf_addr + 1;
                read_delay_counter_wf   <= read_delay_counter_wf + 1;
            end
            else begin
                if (wf_index < N - 1) begin
                    i_wf[wf_index] <= i_wf_data;
                    wf_index       <= wf_index + 1;
                    if (wf_index < N - 2) begin
                        wf_addr    <= wf_addr + 1;
                    end
                end 
                else if (wf_index == N - 1) begin
                    i_wf[wf_index] <= i_wf_data;  // Load last element
                    wf_index       <= 0;
                    wf_loading <= 0;
                end
            end
        end
    end

    // Logic to update i_cmd (2 elements, 1 per clock cycle) including init signal
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            i_cmd                   <= '{default: '0};
            cmd_en                  <= 1;
            cmd_index               <= 0;
            cmd_addr                <= 0;
            cmd_loading             <= 0;
            load_complete_cmd       <= 0;
            read_delay_counter_cmd  <= 0;
        end 
        else if (load_mem && !load_complete_cmd) begin
            // Load the first 2 elements when the init signal is active
            if (read_delay_counter_init < 2) begin
                cmd_addr        <= cmd_addr + 1;
            end
            else begin
                if (cmd_index == 0) begin
                    i_cmd[cmd_index] <= cmd_data;  // Load 1st element
                    cmd_index        <= cmd_index + 1;
                end 
                else if (cmd_index == 1) begin
                    i_cmd[cmd_index]  <= cmd_data;  // Load 2nd element
                    cmd_index         <= 0;
                    load_complete_cmd <= 1;
                end
            end
        end 
        else if (load_trigger_cmd && start_neuron && !cmd_loading && load_complete_cmd) begin
            cmd_loading              <= 1;
            read_delay_counter_cmd   <= 0;
        end 
        else if (cmd_loading) begin
            if (read_delay_counter_cmd < 2) begin
                if (cmd_addr == 29999) begin
                    cmd_addr    <= 0;
                end
                else cmd_addr   <= cmd_addr + 1;
                read_delay_counter_cmd   <= read_delay_counter_cmd + 1;
            end
            else begin
                if (cmd_index == 0) begin
                    i_cmd[cmd_index] <= cmd_data;  // Load 1st element
                    cmd_index        <= cmd_index + 1;
                end 
                else if (cmd_index == 1) begin
                    i_cmd[cmd_index]  <= cmd_data;  // Load 2nd element
                    cmd_index         <= 0;
                    cmd_loading       <= 0;
                end
            end
        end
    end

endmodule