module synaptic_core #(
    parameter N            = 64,
    parameter Dims         = 2,
    parameter Eta_W        = 8'h 35,
    parameter dt           = 8'h 07,
    parameter learn_thresh = 1006
)(
    input  logic         clk,
    input  logic         reset,
    input  logic         reset_iteration,
    input  logic         load_mem,
    input  logic         ws_start,
    input  logic         learn_en,
    input  logic [31:0]  i_dec      [Dims * N],
    input  logic [31:0]  i_err      [Dims],
    input  logic [31:0]  i_spike_f  [N],
    output logic [31:0]  o_ws       [N],
    output logic         done
);

    // Internal signals
    logic [5:0]   index;
    logic [5:0]   index_ws;
    logic [5:0]   index_spike_f;
    logic [6:0]   index_dec;
    logic [11:0]  read_addr;       // Read address goes from 0 to 4095
    logic [11:0]  write_addr;
    logic [31:0]  ws_data;
    logic [31:0]  upd_ws;
    logic [31:0]  spike_f;  
    logic [31:0]  dec [Dims];
    logic         learn_state;
    logic         ws_start_reg;
    logic         start_learn;
    logic         done_learn;
    logic         read_en;
    logic         write_en;
    logic         load_complete;
    logic         write_complete;

    assign learn_state = (ws_start || start_learn) && learn_en;
    assign write_en  = done_learn;
    // State management without FSM - keep track of control using signals
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            // Reset internal variables
            read_en        <= 0;
            index_ws       <= 0;
            index          <= 0;
            read_addr      <= 0;
            done           <= 0;
            load_complete  <= 0;
            write_complete <= 0;
            spike_f        <= 0;
            dec            <= '{default: '0};
            o_ws           <= '{default: '0};
        end
        else begin
            index_ws    <= index;
            // Load initial 64 entries if load_mem is high
            if (load_mem && !load_complete) begin
                read_en <= 1;
                if (read_en) begin
                    o_ws[index_ws] <= ws_data;
                    if (index_ws < N - 1) begin
                        read_addr      <= read_addr + 1;
                        index          <= index + 1;
                    end
                    else begin
                        load_complete <= 1;
                        done          <= 1;
                        read_en       <= 0;
                        index         <= 0;
                    end
                end      
            end
            // Load next 64 entries if ws_start is high
            else if ((ws_start || read_en) && !learn_en) begin
                read_en        <= 1;
                o_ws[index_ws] <= ws_data;
                if (index_ws < N - 1) begin
                    read_addr <= read_addr + 1;
                    index <= index + 1;
                end
                else begin
                    write_complete <= 1;
                    done <= 1;
                    read_en <= 0;
                    index <= 0;
                end
            end
            // Learning mode if learn_en is high
            else if (learn_state || write_en) begin
                o_ws[index_ws] <= upd_ws;
                if (learn_state) begin
                    read_en   <= 1;
                    if (index < N - 1) begin
                        read_addr <= read_addr + 1;
                    end
                    if (index == N - 1) begin
                        read_en        <= 0; 
                        write_complete <= 0;
                        done           <= 1;
                        index          <= 0;
                    end
                    else if (start_learn) begin
                        index     <= index + 1;
                    end 
                end
            end
               // Reset done and write_complete signals when idle
            else begin
                done <= 0;
                write_complete <= 0;
            end
        end
    end
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            index_spike_f  <= 0;
            write_addr     <= 0;
            index_dec      <= 0;
            start_learn    <= 0;
        end
        else begin
            dec[0]  <= i_dec[index_dec];
            dec[1]  <= i_dec[index_dec + 1];
            spike_f <= i_spike_f[index_spike_f];
            if (done_learn) begin
                write_addr  <= write_addr + 1;
            end
            if (learn_en && ws_start) begin
                start_learn <= 1;
            end
            if (learn_state) begin
                if (index == 63) begin
                    start_learn   <= 0;
                    index_dec     <= 0;
                    index_spike_f <= 0;
                end
                else begin
                    index_spike_f <= index_spike_f + 1;
                    index_dec <= index_dec + 2;         
                end
            end
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
        .reset_iteration(reset_iteration),
        .start(start_learn),
        .dec(dec),
        .i_err(i_err),
        .i_ws(ws_data),
        .i_spike_f(spike_f), // spike input
        .upd_ws(upd_ws),          // updated weight output
        .done(done_learn)
    );

    // Instantiate Synaptic_Memory
    Synaptic_Memory u_synaptic_mem (
        .clka(clk),
        .ena(write_en),
        .wea(write_en),
        .addra(write_addr),
        .dina(upd_ws),
        .clkb(clk),
        .enb(read_en),
        .addrb(read_addr),
        .doutb(ws_data)
    );

endmodule