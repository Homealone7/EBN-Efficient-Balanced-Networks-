module spike_filter_tb;
    parameter N                 = 64;
    parameter Lambda            = 40'h A00000000;
    parameter dt                = 40'h 68DB8;
    parameter One               = 40'h 100000000;                                                           
    parameter INTEGER_BITS      = 8;
    parameter FRACTIONAL_BITS   = 32;

    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f[N], o_spike_f[N], i_spike[N];
    logic clk, reset, start, done;
    integer counter = 0;

    spike_filter #(
        .N(N),
        .Lambda(Lambda),
        .dt(dt),
        .One(One),
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    )spike(
        .clk(clk),
        .reset(reset),
        .start(start),
        .i_spike(i_spike), 
        .i_spike_f(i_spike_f),    
        .o_spike_f(o_spike_f),    
        .done(done)
    ); 

    always begin
        #5 clk = ~clk; 
    end

    always_ff @(posedge clk) begin
        counter = counter + 1;
    end

    initial begin
        clk = 0;
        reset = 1;                  
        #15
        reset = 0;
        start = 1;
        $readmemb("rO_f.txt", i_spike_f);
        $readmemb("O_f.txt", i_spike);
        @(posedge done);
        #50
        $finish;
    end 

endmodule