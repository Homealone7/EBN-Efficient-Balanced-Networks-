`timescale 1ns / 1ps
module top_tb;
    logic clk100mhz = 0; 
    logic reset = 1;    
    logic init_signal = 0;
    logic spike_flg; 
    logic done;
    logic axi_tvalid, axi_tlast;
    logic [31:0] axi_tdata;
    integer counter = 0, l = 0, count_done = 0, count_lif = 0, count_it = 1;       
    
    top u_top(
        .clk(clk100mhz),
        .axi_tready(1'b1),
        .reset_high(reset),
        .spike_flg_out(spike_flg),
        .axi_tdata(axi_tdata),
        .axi_tvalid(axi_tvalid),
        .axi_tlast(axi_tlast),
        .done(done)
    );
    always begin
        #10 clk100mhz = ~clk100mhz;
    end

    always_ff @(posedge u_top.clk) begin
        counter <= counter + 1;
        if (EBN.Neuron.done_lif_AU) begin
            count_lif <= count_lif + 1;
        end
        if (EBN.done_dyn) begin
            count_done <= count_done + 1;
            $display("Completed Cycles: %0d", count_done); // Display the counter
        end
        if (EBN.Neuron.done_spike) begin
            if (l >= 15000) begin
                l <= 0;
                count_it <= count_it + 1;
                $display("Iteration Count: %0d", count_it); // Display the counter
            end
            else begin 
                l <= l + 1; 
            end
        end
    end

    initial begin
        #20
        reset = 0;
    end
    
endmodule
