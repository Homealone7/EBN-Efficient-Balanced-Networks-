module spike_out #(
    parameter N = 64
) (
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic [5:0]  index,
    input  logic [15:0] pot_thresh_diff,
    output logic [15:0] o_spike[N], // Spikes
    output logic [5:0]  spike_pos,
    output logic        spike_flg, // Spike happened if = 1;
    output logic        done
);
    integer i;
    logic        pot_greater;
    logic        greater_than_zero;
    logic [5:0]  max_pos;
    logic [15:0] max_pot;
    assign pot_greater = (pot_thresh_diff[15] != max_pot[15]) ? ~pot_thresh_diff[15]:                // If signs are different, 'a' > 'b' if 'a' is positive
                         (pot_thresh_diff[15] == 1'b0) ? (pot_thresh_diff[6:0] > max_pot[6:0]) :   // If both are positive, compare normally
                         (pot_thresh_diff[6:0] < max_pot[6:0]);                                   // If both are negative, invert the comparison
    assign greater_than_zero = (~max_pot[15]) && (max_pot[6:0] != 15'b0);


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
            if(pot_greater) begin
                max_pot <= pot_thresh_diff;
                max_pos <= index;
            end
            if(start) begin   
                for(i = 0; i < N; i++) begin
                    if (greater_than_zero && (i == max_pos)) begin
                        o_spike[i]   <= 16'h 3f80;
                    end
                    else o_spike[i]  <= 0;  
                end
                if(max_pot) begin
                    spike_flg <= 1;
                    spike_pos <= max_pos;   
                end
                max_pot <= 0;
                max_pos <= 0;
                done    <= 1;  
            end
            else begin
                spike_pos <= 0;
                spike_flg <= 0;
                done      <= 0;
            end
        end
    end
endmodule
