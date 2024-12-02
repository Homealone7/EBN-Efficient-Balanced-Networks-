module spike_filter #(
    parameter N      = 64,
    parameter Lambda = 8'h 10,
    parameter dt     = 8'h 07,
    parameter One    = 8'h 3c
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic [7:0] i_spike_f  [N],    // Filtered Spikes from MEM
    output logic [7:0] o_spike_f  [N],    // Updated Filtered Spikes
    output logic       done
); 

    logic       calculating;
    logic [5:0] index;
    logic [7:0] spike_leak;
    logic [7:0] lambda_dt;
    logic [7:0] leak;
    
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

    FP_8_Add_Sub  Sub_0(
        .A(One),
        .B(lambda_dt),
        .add(1'b0),
        .Sum(leak)
    );
    FP_8_Mult lambdadt(
        .A(Lambda),
        .B(dt),
        .product(lambda_dt)
    );
    FP_8_Mult spike_f_leak(
        .A(leak),
        .B(i_spike_f[index]),
        .product(spike_leak)
    );

endmodule