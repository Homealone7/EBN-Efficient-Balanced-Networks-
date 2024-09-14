`timescale 1ns / 1ps
module top_tb;
logic clk100mhz = 0; 
logic reset = 0;    
logic init_signal = 0;
logic spike_flg; 
logic done;       

    top u_top(
        .clk100mhz(clk100mhz),
        .reset(reset),
        .init_signal(init_signal),
        .spike_flg(spike_flg),
        .done(done)
    );
    always begin
        #10 clk100mhz = ~clk100mhz;
    end
    initial begin
        #20
        reset = 1;
        #20
        reset = 0;
        init_signal = 1;
    end
    
endmodule
