module spike_filter #(
    parameter N                 = 64,
    parameter Lambda            = 16'h A000,
    parameter dt                = 16'h 68DB,
    parameter One               = 16'h 1000,
    parameter INTEGER_BITS      = 5,
    parameter FRACTIONAL_BITS   = 11
) (
    input  logic                                                clk,
    input  logic                                                reset,
    input  logic                                                reset_iteration,
    input  logic                                                start,
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f  [N],    // Filtered Spikes from MEM
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_spike_f  [N],    // Updated Filtered Spikes
    output logic                                                done
); 

    logic                                              calculating;
    logic        [5:0]                                 index;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS -1:0] spike_leak;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS -1:0] lambda_dt;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS -1:0] leak;
    
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done        <= 0;
            calculating <= 0;
            index       <= 0;
            o_spike_f   <= '{default: '0};
        end
        else begin
            if (start && !calculating) begin
                calculating <= 1;
                index       <= 0;
                done        <= 0;
            end
            else if (calculating) begin
                o_spike_f [index] <= spike_leak;
                index <= index + 1;
                if (index == N - 1) begin
                    calculating <= 0;
                    index       <= 0;
                    done        <= 1;
                end
            end
            else begin
                done <= 0;
            end
        end       
    end  

    assign leak = One - lambda_dt;

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) lambdadt (
        .a(Lambda), 
        .b(dt),
        .result(lambda_dt),
        .overflow()
    );

    fixed_point_mult #(
        .INTEGER_BITS(INTEGER_BITS),
        .FRACTIONAL_BITS(FRACTIONAL_BITS)
    ) spike_f_leak (
        .a(leak), 
        .b(i_spike_f[index]), // Protect against out-of-bounds access
        .result(spike_leak),
        .overflow()
    );
endmodule
