module spike_out #(
    parameter N                 = 64,
    parameter INTEGER_BITS      = 5,
    parameter FRACTIONAL_BITS   = 11
) (
    input  logic                                                clk,
    input  logic                                                reset,
    input  logic                                                reset_iteration,
    input  logic                                                start,
    input  logic         [5:0]                                  index,
    input  logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] pot_thresh_diff,
    output logic                                                spike_flg, // Spike happened if = 1;
    output logic         [5:0]                                  spike_pos,
    output logic signed  [INTEGER_BITS + FRACTIONAL_BITS - 1:0] o_spike[N], // Spikes
    output logic                                                done
);
    integer i;
    logic        [5:0]                                  max_pos;
    logic signed [INTEGER_BITS + FRACTIONAL_BITS - 1:0] max_pot;

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            done        <= 0;
            max_pot     <= 0;
            max_pos     <= 0;
            spike_pos   <= 0;
            spike_flg   <= 0;
            o_spike     <= '{default: '0};
        end
        else begin
            if(pot_thresh_diff > max_pot) begin
                max_pot <= pot_thresh_diff;
                max_pos <= index;
            end
            if(start) begin   
                for(i = 0; i < N; i++) begin
                    if (max_pot > 0 && (i == max_pos)) begin
                        o_spike[i]   <= { {(INTEGER_BITS - 1){1'b0}}, 1'b1, {(FRACTIONAL_BITS){1'b0}} };
                    end
                    else o_spike[i]  <= 0;  
                end
                if(max_pot) begin
                    spike_flg        <= 1;
                    spike_pos        <= max_pos;   
                end
                max_pot <= 0;
                max_pos <= 0;
                done  <= 1;  
            end
            else begin
                spike_pos   <= 0;
                spike_flg   <= 0;
                done <= 0;
            end
        end
    end
endmodule
