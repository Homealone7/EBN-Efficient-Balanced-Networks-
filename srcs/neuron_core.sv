module neuron_core #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter NzMemb            = 16'h 1000,
    parameter Gain_D            = 16'h 1000,
    parameter K                 = 16'h 1000,
    parameter LambdaV           = 16'h 3200,
    parameter dt                = 16'h 68D0,
    parameter One               = 16'h 1000,
    parameter INTEGER_BITS      = 5,
    parameter FRACTIONAL_BITS   = 11,
    parameter A_ROWS            = 1,
    parameter B_COLS            = 1
)(
    input  logic                                                clk,
    input  logic                                                reset,
    input  logic                                                reset_iteration,
    input  logic                                                start,
    input  logic                                                wait_spike,
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_dec      [Dims * N],
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_cmd      [Dims],     // Commands
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_err      [Dims],     // Calculation error
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_wf       [N],        // Fast Weights
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_ws       [N],        // Slow Weights
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f  [N],
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thresh [N],
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] randn      [N],
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_pot,
    output logic         [5:0]                                  spike_out_index,
    output logic         [5:0]                                  spike_pos,
    output logic                                                spike_flg, // Spike happened if = 1;
    output logic                                                next,
    output logic                                                load_trigger_wf,
    output logic                                                done_lif_AU,
    output logic                                                done_spike,
    output logic                                                done 
);

    logic                                                start_spike_out;
    logic                                                start_w;
    logic                                                read_en;
    logic                                                write_en;
    logic         [5:0]                                  read_addr;
    logic         [5:0]                                  write_addr;
    logic         [5:0]                                  prev_index;
    logic         [6:0]                                  index;
    //logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_pot;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] randn_tmp;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] neur_data;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thresh_diff;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_spike   [N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] spike_tmp [N];
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] dec_t     [Dims];
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
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            spike_out_index <= 0;
            prev_index      <= 0;
            start_spike_out <= 0;
            pot_thresh_diff <= 0;
        end
        else begin
            prev_index <=  spike_out_index;
            if (done_lif_AU) begin
                if (spike_out_index == N - 1) begin
                    start_spike_out <= 1;
                end 
                pot_thresh_diff <= o_pot - pot_thresh[prev_index];
                spike_out_index <= spike_out_index + 1;                 
            end
            else start_spike_out <= 0; 
        end
    end  
    /////////////// Decoder Transpose & Addr ///////////////
    always_ff @(posedge clk) begin 
        if (reset || reset_iteration) begin
            index       <= 0;
            randn_tmp   <= 0;
            dec_t       <= '{default: '0}; 
        end
        else begin
            if (wait_spike) begin
                if (done_lif_AU) begin
                    index             <= 0;
                    randn_tmp         <= randn[63];
                    dec_t[0]          <= i_dec[63];
                    dec_t[1]          <= i_dec[127];
                end
            end
            else begin
                if (load_trigger_wf) begin
                    if (index >= N - 1) begin
                        index             <= 0;
                        randn_tmp         <= randn[63];
                        dec_t[0]          <= i_dec[63];
                        dec_t[1]          <= i_dec[127];
                    end
                    else begin
                        index             <= index + 1;
                        randn_tmp         <= randn[index];
                        dec_t[0]          <= i_dec[index];
                        dec_t[1]          <= i_dec[index + 64];  
                    end
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
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS),
        .A_ROWS(A_ROWS),
        .B_COLS(B_COLS)
    ) lif_AU (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start),
        .i_dec_t(dec_t),
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
        .next(next),
        .o_pot(o_pot),
        .done(done_lif_AU)
    );

    spike_out #(
        .N(N),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) spike_out(
        .clk(clk),
        .index(prev_index),
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
        .DATA_WIDTH(INTEGER_BITS + FRACTIONAL_BITS),
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
