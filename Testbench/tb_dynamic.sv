module tb_dynamic;
parameter N       = 64;
parameter Dims    = 2;
parameter dyn     = 16'h 4100;
parameter dt      = 16'h 38d2;
parameter Three   = 16'h 4040;
parameter LambdaV = 16'h 4120;

integer counter = 0, index = 0;
logic clk = 0;
logic reset;
logic reset_iteration;
logic start;
logic done_est;
logic [15:0] i_cmd [30000];
logic [15:0] cmd   [Dims];
logic [15:0] i_x   [Dims];
logic [15:0] o_x   [Dims];

    always begin
        #5
        clk = ~clk;
    end

    always_ff @(posedge clk) begin
        if(done_est) counter <= counter + 1;
    end

    always_ff @(posedge clk ) begin
        if (reset || reset_iteration) begin
            i_x     <= '{default: '0};
        end
        else begin
            if (done_est) begin
                i_x[0]     <= o_x[0];
                i_x[1]     <= o_x[1];
            end
        end
    end

    always_ff @(posedge clk ) begin
        if (reset || reset_iteration) begin
            cmd[0] <= 0;
            cmd[1] <= 0;
        end
        else begin
            cmd[0] <= i_cmd[index];
            cmd[1] <= i_cmd[index + 1];
            if (done_est) begin
                index <= index + 2;
            end
        end
    end

    dynamic #(
        .N(N),            
        .Dims(Dims),         
        .dyn(dyn),
        .dt(dt),
        .Three(Three)
    )Desired(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start),
        .i_cmd(cmd),
        .i_x(i_x),
        .o_x(o_x),
        .done(done_est)
    );


    initial begin
    // Load the commands
    $readmemb("Command_bf16.txt", i_cmd);

    // Initialize signals
    reset = 1;
    reset_iteration = 0;
    start = 0;  

    // Apply reset
    #10
    reset = 0;

    // Start toggling start signal
    fork
        // Toggle start signal continuously
        forever begin
            start = 1; // Turn on for 1 cycle
            #10;       // Wait for 1 cycle
            start = 0; // Turn off for 2 cycles
            #20;
        end

        // Wait for the counter to reach 15000 and finish
        begin
            wait (counter >= 15000);
            $finish;
        end
    join
end


endmodule