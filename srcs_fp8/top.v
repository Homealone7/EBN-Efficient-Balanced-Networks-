module top(
    input clk,
    input reset_high,        
    //input init_signal,
    input axi_tready,
    output spike_flg_out,
    output done,
    output reg [31:0] axi_tdata,
    //output [7:0] axi_tkeep,    
    output reg axi_tvalid,          // Data valid signal for AXI DMA
    output reg axi_tlast  
);
    // Internal signals
    wire clk_25;
    wire [5:0] spike_pos_out;
    wire [7:0] o_x_0;
    wire [7:0] o_x_1;
    wire [7:0] o_x_est_0;
    wire [7:0] o_x_est_1;
    wire [7:0] ws_out;
    wire [7:0] pot_out;
    reg [15:0] counter;

    wire reset_sync;
    reg  reset_sync_ff1, reset_sync_ff2;

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

    //assign axi_tdata = {o_x_0, o_x_1, pot_out, ws_out}; 
    //assign axi_tkeep = 8'b00111111;  // Lower 6 bytes are valid
    
    always @(posedge clk) begin
        if (reset_sync) begin
            axi_tvalid <= 1'b0;    // Reset axi_tvalid
            axi_tlast  <= 1'b0;    // Reset axi_tlast
            counter    <= 0;
            axi_tdata  <=  0;
        end 
        else begin
            if (done && counter < 15000) begin
                // When 'done' is high, start the transfer
                counter    <= counter + 1;
                axi_tvalid <= 1'b1;      
                axi_tlast  <= 1'b1;
                axi_tdata  <= {o_x_0, o_x_1, o_x_est_0, o_x_est_1};
            end 
            else if (axi_tvalid && axi_tready) begin
                // Transfer has occurred
                axi_tvalid <= 1'b0;
                axi_tlast  <= 1'b0;
            end
        end
    end
    
    EBN ebn_inst (
        .clk(clk),
        .reset(reset_sync),
        .init_signal(1'b1),
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
/*

    clk_wiz_0 clkwiz
   (
    // Clock out ports
    .clk_out1(clk_25),     // output clk_out1
   // Clock in ports
    .clk_in1(clk)      // input clk_in1
);
    ila_0 ILA (
	.clk(clk), // input wire clk
	.probe0(done), // input wire [0:0]  probe0  
	.probe1(spike_flg_out), // input wire [0:0]  probe1 
	.probe2(spike_pos_out), // input wire [5:0]  probe2 
	.probe3(o_x_0), // input wire [7:0]  probe3 
	.probe4(o_x_1), // input wire [7:0]  probe4 
	.probe5(o_x_est_0), // input wire [7:0]  probe5 
	.probe6(o_x_est_1), // input wire [7:0]  probe6 
	.probe7(pot_out), // input wire [7:0]  probe7
    .probe8(ws_out) // input wire [7:0]  probe8
);
*/