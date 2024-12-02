module BF16_Matrix_Mult #(
    parameter ROWS_A = 2,
    parameter COLS_A_ROWS_B = 2,
    parameter COLS_B = 3
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic [15:0] matrix_a [ROWS_A * COLS_A_ROWS_B], // Matrix A
    input  logic [15:0] matrix_b [COLS_A_ROWS_B * COLS_B], // Matrix B
    output logic [15:0] result   [ROWS_A * COLS_B],       // Result Matrix
    output logic        next,
    output logic        done
);

    // Internal Signals
    logic m_axis_result_tvalid;
    logic [15:0] s_axis_a_tdata;
    logic [15:0] s_axis_b_tdata;
    logic [15:0] s_axis_c_tdata;
    logic [15:0] m_axis_result_tdata;
    logic [15:0] acc;

    // FSM States
    typedef enum logic [1:0] {
        IDLE,
        IN_PROGRESS
    } state_t;

    state_t state;
    integer i, j, k;

    // Instantiate the BF16_MAC module
    BF16_MAC mac_inst (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(matrix_a[i * COLS_A_ROWS_B + k]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(matrix_b[k * COLS_B + j]),
        .s_axis_c_tvalid(1'b1),
        .s_axis_c_tdata(acc),
        .m_axis_result_tvalid(m_axis_result_tvalid),
        .m_axis_result_tdata(m_axis_result_tdata)
    );

    // Control Logic FSM
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            result[i] <= '{default: '0};
            state     <= IDLE;
            acc       <= 16'b0;
            done      <= 0;
            i         <= 0;
            j         <= 0;
            k         <= 0;
        end 
        else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= IN_PROGRESS;
                        acc   <= 16'b0;
                        i     <= 0;
                        j     <= 0;
                        k     <= 0;
                    end
                end
                IN_PROGRESS: begin
                    if (k < COLS_A_ROWS_B - 1) begin
                        acc <= m_axis_result_tdata;
                        k <= k + 1;
                    end 
                    else begin
                        result[i * COLS_B + j] <= m_axis_result_tdata; // Store result in C
                        acc                    <= 16'b0;       // Reset sum for the next row
                        k                      <= 0;          // Reset k
                        // j & i
                        if (j == COLS_B - 1) begin
                            j <= 0;  // Reset j when last column is done
                            if (i == ROWS_A - 1) begin
                                state <= IDLE;
                                done  <= 1;
                                i     <= 0;
                            end 
                            else i <= i + 1;
                        end
                        else j <= j + 1;
                    end
                end
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            next <= 0;
        end
        else begin
            if (i == ROWS_A - 1 && j == COLS_B - 1 && k == COLS_A_ROWS_B - 2) begin
                next <= 1;
            end
            else next <= 0;
        end
    end

endmodule
