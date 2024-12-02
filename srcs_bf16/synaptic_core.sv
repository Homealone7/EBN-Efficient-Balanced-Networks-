module synaptic_core #(
    parameter N            = 64,
    parameter Dims         = 2,
    parameter Eta_W        = 8'h 35,
    parameter dt           = 8'h 07,
    parameter learn_thresh = 1006
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         load_mem,
    input  logic         ws_start,
    input  logic         learn_en,
    input  logic [15:0]  i_dec      [Dims * N],
    input  logic [15:0]  i_err      [Dims],
    input  logic [15:0]  i_spike_f  [N],
    output logic [15:0]  o_ws       [N],
    output logic         done
);

    // FSM States
    typedef enum logic [1:0] {
        IDLE,
        LOAD_INIT,    // Load first 64 entries of synaptic memory
        LOAD_NEXT,    // Wait to load the next 64 entries
        LEARN         // Learning mode
    } state_t;

    state_t current_state, next_state;

    // Internal signals
    logic [5:0]   index_ws;
    logic [11:0]  read_addr;       // Read address goes from 0 to 4095
    logic [11:0]  write_addr;
    logic [15:0]  ws_data;
    logic         read_en;
    logic         write_en;
    logic         load_complete;
    logic         loading_active;

    // State Register
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
        end
    end

    // State Transition Logic
    always_comb begin
        case (current_state)
            IDLE: begin
                if (ws_start) begin
                    next_state = LOAD_NEXT;
                end
                else if (load_mem) begin
                    next_state = LOAD_INIT;
                end
                else begin
                    next_state = IDLE;
                end
            end
            LOAD_INIT: begin
                if (load_complete) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = LOAD_INIT;
                end
            end
            LOAD_NEXT: begin
                if (!loading_active) begin
                    next_state = IDLE;
                end
                else if (learn_en) begin
                    next_state = LEARN;
                end
                else begin
                    next_state = LOAD_NEXT;
                end
            end
            LEARN: begin
                if (!learn_en) begin
                    next_state = IDLE; // Go back to IDLE when learning is off
                end
                else begin
                    next_state = LEARN;
                end
            end
            default: next_state = IDLE;
        endcase
    end

    // Output Logic and Operations for Each State
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            // Reset internal variables
            index_ws       <= 0;
            read_addr      <= 0;
            write_addr     <= 0;
            read_en        <= 0;
            write_en       <= 0;
            done           <= 0;
            load_complete  <= 0;
            loading_active <= 0;
        end
        else begin
            case (current_state)
                LOAD_INIT: begin
                    if (load_mem) begin
                        // Start loading the first 64 entries
                        read_en       <= 1;
                        if (index_ws < N - 1) begin
                            read_addr <= read_addr + 1;
                            index_ws  <= index_ws + 1;
                        end
                        else begin
                            read_en        <= 0;
                            load_complete  <= 1; // Loading complete
                            done           <= 1;
                        end
                    end
                end
                LOAD_NEXT: begin
                    loading_active <= 1;  // Indicates that loading is in progress
                    read_en        <= 1;
                    // Continue loading until 64 entries are loaded
                    if (index_ws < N - 1) begin
                        read_addr <= read_addr + 1;
                        index_ws  <= index_ws + 1;
                    end
                    else begin
                        read_en        <= 0;
                        done           <= 1; // Loading complete
                        index_ws       <= 0; // Reset index_ws for the next loading cycle
                        loading_active <= 0; // Loading is complete
                    end
                end
                LEARN: begin
                    // In learning mode, take output from learn submodule
                    if (learn_en) begin
                        write_en <= 1;
                        // Logic for writing from the learn module
                        // Assume learning submodule logic already updates write_addr and ws_data appropriately
                    end
                    else begin
                        write_en <= 0;
                    end
                end
            endcase
        end
    end

    // Instantiate learn_rule
    learn_rule #(
        .N(N),
        .Dims(Dims),
        .dt(dt),
        .Eta_W(Eta_W)
    ) learn_calc (
        .clk(clk),
        .reset(reset),
        .reset_iteration(1'b0), // Assuming iteration reset logic is separate
        .start(ws_start),
        .dec(i_dec),
        .i_err(i_err),
        .i_ws(ws_data),
        .i_spike_f(i_spike_f[0]), // Example spike input
        .upd_ws(ws_data), // Example updated weight output
        .o_ws(o_ws),
        .done(done)
    );

    // Instantiate Synaptic_Memory
    Synaptic_Memory u_synaptic_mem (
        .clka(clk),
        .ena(write_en),
        .wea(write_en),
        .addra(write_addr),
        .dina(ws_data),
        .clkb(clk),
        .enb(read_en),
        .addrb(read_addr),
        .doutb(ws_data)
    );

endmodule
