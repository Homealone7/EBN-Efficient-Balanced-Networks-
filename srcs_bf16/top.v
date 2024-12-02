module top(
    input clk,
    input reset_high,        
    input axi_tready,
    output spike_flg_out,
    output done,
    output reg [31:0] axi_tdata,   
    output reg axi_tvalid,          // Data valid signal for AXI DMA
    output reg axi_tlast  
);
    // Internal signals
    wire [5:0]  spike_pos_out;
    wire [15:0] o_x_0;
    wire [15:0] o_x_1;
    wire [15:0] o_x_est_0;
    wire [15:0] o_x_est_1;
    wire [15:0] ws_out;
    wire [15:0] pot_out;
    reg  [15:0] counter;
    reg  [6:0]  iteration_counter; // Counter for learning iterations
    reg learn_flg;
    wire reset_sync;
    reg  reset_sync_ff1, reset_sync_ff2;

    // Reset synchronization
    always @(posedge clk) begin
        if (reset_high) begin
            reset_sync_ff1 <= 1'b1;
            reset_sync_ff2 <= 1'b1;
        end else begin
            reset_sync_ff1 <= 1'b0;
            reset_sync_ff2 <= reset_sync_ff1;
        end
    end
    assign reset_sync = reset_sync_ff2;

    always @(posedge clk) begin
        if (reset_sync) begin
            iteration_counter <= 0;
            learn_flg  <= 1;
        end
        else begin
            if (reset_iteration) begin
                iteration_counter <= iteration_counter + 1;
            end
            if (iteration_counter >= 100) begin
                learn_flg <= 0;
            end
        end
    end

    always @(posedge clk) begin
        if (reset_sync) begin
            axi_tvalid <= 1'b0;    // Reset axi_tvalid
            axi_tlast  <= 1'b0;    // Reset axi_tlast
            axi_tdata  <= 0;
            counter    <= 0;
        end
        else begin
            if (!learn_flg) begin
                if (done && counter < 15000) begin
                    counter    <= counter + 1;
                    axi_tvalid <= 1'b1;      
                    axi_tlast  <= 1'b1;
                    axi_tdata  <= {o_x_est_0, o_x_est_1};
                end
                else if (axi_tvalid && axi_tready) begin
                    // Transfer has occurred
                    axi_tvalid <= 1'b0;
                    axi_tlast  <= 1'b0;
                end
            end      
        end
    end

    // EBN Module Instantiation
    EBN ebn_inst (
        .clk(clk),
        .reset(reset_sync),
        .init_signal(1'b1),
        .learn_flg(learn_flg),
        .reset_iteration(reset_iteration),
        .spike_flg_out(spike_flg_out),
        .spike_pos_out(spike_pos_out),
        .o_x_0(o_x_0),
        .o_x_1(o_x_1),
        .o_x_est_0(o_x_est_0),
        .o_x_est_1(o_x_est_1),
        .pot_out(pot_out),
        .ws_out(ws_out),
        .done(done)
    );

endmodule
