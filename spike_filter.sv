module spike_filter #(
    parameter N                 = 64,
    parameter Lambda            = 40'hA00000000,
    parameter dt                = 40'h68DB8,
    parameter One               = 40'h100000000,
    parameter INTEGER_BITS      = 8,
    parameter FRACTIONAL_BITS   = 32
) (
    input   logic                                                clk,
    input   logic                                                reset,
    input   logic                                                start,
    input   logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] i_spike_f  [N],    // Filtered Spikes from MEM
    output  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_spike_f  [N],    // Updated Filtered Spikes
    output  logic                                                done
); 

    logic signed [INTEGER_BITS + FRACTIONAL_BITS -1:0] spike_leak, lambda_dt, leak;
    logic [5:0] index;
    logic calculating;
    integer i;

    // Shift register to delay the calculation by 4 cycles
    logic signed [INTEGER_BITS + FRACTIONAL_BITS -1:0] spike_leak_shift [3:0];
    
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            done        <= 0;
            calculating <= 0;
            index       <= 0;
            for (i = 0; i < N; i++) begin
                o_spike_f[i] <= 0;
            end
        end
        else begin
            if (start && !calculating) begin
                calculating <= 1;
                index       <= 0;
                done        <= 0;
            end
            else if (calculating) begin
                o_spike_f [index] = spike_leak;
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
        .b(i_spike_f[index < N ? index : N-1]), // Protect against out-of-bounds access
        .result(spike_leak),
        .overflow()
    );
endmodule
