module neuron_core #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter NzMemb            = 16'h 38d2,
    parameter Gain_D            = 16'h 3c00,
    parameter LambdaV           = 16'h 4248,
    parameter One               = 16'h 3f80,
    parameter K                 = 16'h 3a03,
    parameter dt                = 16'h 38d2,
    parameter ROWS_A            = 1,
    parameter COLS_B            = 1
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic        wait_spike,
    input  logic [15:0] i_dec      [Dims * N],
    input  logic [15:0] i_cmd      [Dims],     // Commands
    input  logic [15:0] i_err      [Dims],     // Calculation error
    input  logic [15:0] i_wf       [N],        // Fast Weights
    input  logic [15:0] i_ws       [N],        // Slow Weights
    input  logic [15:0] i_spike_f  [N],
    input  logic [15:0] pot_thresh [N],
    input  logic [15:0] randn      [N],
    output logic [15:0] o_pot,
    output logic [5:0]  spike_out_index,
    output logic [5:0]  spike_pos,
    output logic        spike_flg,           // Spike happened if = 1;
    output logic        ws_start,
    output logic        next,
    output logic        load_trigger_wf,
    output logic        done_lif_AU,
    output logic        done_spike,
    output logic        done 
);

    logic        start_spike_out;
    logic        read_en;
    logic        write_en;
    logic [5:0]  read_addr;
    logic [5:0]  write_addr;
    logic [5:0]  randn_index;
    logic [5:0]  thresh_index;
    logic [6:0]  dec_index;
    logic [15:0] randn_tmp;
    logic [15:0] neur_data;
    logic [15:0] pot_thrs_diff;
    logic [15:0] pot_thresh_diff;
    logic [15:0] o_spike   [N];
    logic [15:0] spike_tmp [N];
    logic [15:0] dec     [Dims];
    /////////////// Done ///////////////
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done        <= 0;
        end
        else begin
            if (done_spike) begin
                done    <= 1;
            end
            else begin
                done   <= 0;
            end
        end     
    end
    ///////////////// Output Spikes Start ///////////////
    BF16_Sub Sub_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_pot),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(pot_thresh[thresh_index]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(pot_thrs_diff)
    );
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            spike_out_index <= 0;
            thresh_index      <= 0;
            start_spike_out <= 0;
            pot_thresh_diff <= 0;
        end
        else begin
            thresh_index <=  spike_out_index;
            if (done_lif_AU) begin
                if (spike_out_index == N - 1) begin
                    start_spike_out <= 1;
                end 
                pot_thresh_diff <= pot_thrs_diff;
                spike_out_index <= spike_out_index + 1;                 
            end
            else start_spike_out <= 0; 
        end
    end  
    /////////////// Decoder Transpose & Addr ///////////////
    always_ff @(posedge clk) begin 
        if (reset || reset_iteration) begin
            dec_index   <= 0;
            randn_index <= 0;
            randn_tmp   <= 0;
            dec         <= '{default: '0}; 
        end
        else begin
            randn_tmp   <= randn[randn_index];
            dec[0]      <= i_dec[dec_index];
            dec[1]      <= i_dec[dec_index + 1];
            if (done_lif_AU) begin
                if (dec_index == 126) begin
                    dec_index   <= 0;
                    randn_index <= 0;
                end
                else begin
                    dec_index   <= dec_index + 2;
                    randn_index <= randn_index + 1;   
                end
            end
        end          
    end

    // Read/Write Addr
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            read_addr   <= 0;
            write_addr  <= 0;
        end
        else begin
            write_addr  <= read_addr;
            if (wait_spike) begin
                if (done_lif_AU) begin
                    read_addr   <= 0;
                end
            end
            else begin
                if (done_lif_AU) begin
                    if (read_addr >= N - 1) begin
                        read_addr   <= 0;
                    end
                    else begin
                        read_addr   <= read_addr + 1;
                    end
                end
            end
        end
    end
    assign read_en = next;
    assign write_en = done_lif_AU;

    // Neuron update logic for leaky integrate-and-fire (LIF) model
    lif_AU #(
        .N(N),
        .Dims(Dims),
        .NzMemb(NzMemb),
        .Gain_D(Gain_D),
        .LambdaV(LambdaV),
        .One(One),
        .K(K),
        .dt(dt),
        .ROWS_A(ROWS_A),
        .COLS_B(COLS_B)
    ) lif_AU (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start),
        .i_dec_t(dec),
        .i_cmd(i_cmd),
        .i_err(i_err),
        .i_wf(i_wf),
        .i_ws(i_ws),
        .i_spike(spike_tmp),
        .i_spike_f(i_spike_f),
        .i_pot(neur_data),
        .wait_spike(wait_spike),
        .randn(randn_tmp),
        .start_w(load_trigger_wf),
        .start_w_reg(ws_start),
        .next(next),
        .o_pot(o_pot),
        .done(done_lif_AU)
    );

    spike_out #(
        .N(N)
    ) spike_out(
        .clk(clk),
        .index(thresh_index),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_spike_out),
        .pot_thresh_diff(pot_thresh_diff),
        .spike_pos(spike_pos),
        .spike_flg(spike_flg),
        .o_spike(o_spike),
        .done(done_spike)
    );
    /////////////// Spikes Memory ///////////////
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            spike_tmp <= '{default: '0};
        end
        else if (done_spike) begin
                spike_tmp <= o_spike;
        end
    end
    /////////////// Membrane Potential Memory ///////////////
    DualPortMemory #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(6),
        .DEPTH(N)
    )Neuron_Memory(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .read_en(read_en),
        .read_addr(read_addr),
        .read_data(neur_data),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(o_pot)         
    );

endmodule
