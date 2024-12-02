module lif_AU #(
    parameter N                 = 64,
    parameter Dims              = 2,
    parameter NzMemb            = 16'h 38d2,
    parameter Gain_D            = 16'h 3c00,
    parameter LambdaV           = 16'h 4248,
    parameter One               = 16'h 3f80,
    parameter K                 = 16'h 3a03,
    parameter dt                = 16'h 38d2,
    parameter ROWS_A            = 1,
    parameter COLS_B            = 1
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic        wait_spike,
    input  logic [15:0] i_pot,                // membrane potential state from  mem
    input  logic [15:0] i_dec_t   [Dims],     // Transposed Decoder
    input  logic [15:0] i_cmd     [Dims],     // Commands
    input  logic [15:0] i_err     [Dims],     // Calculation error
    input  logic [15:0] i_wf      [N],        // Fast Weights
    input  logic [15:0] i_ws      [N],        // Slow Weights
    input  logic [15:0] i_spike   [N],        // Spikes
    input  logic [15:0] i_spike_f [N],        // Filtered Spikes
    input  logic [15:0] randn,
    output logic [15:0] o_pot,                // Memberane potential
    output logic        start_w,
    output logic        start_w_reg,
    output logic        next,
    output logic        done    
);

    logic        done_dec_cmd;
    logic        done_dec_err;
    logic        done_wf_spike;
    logic        done_ws_spike_f;
    logic        next_dec;
    logic [15:0] leak_str;
    logic [15:0] pot_leak;
    logic [15:0] lambdaV_dt;
    logic [15:0] ws_spike_f_dt;
    logic [15:0] dec_err_k;
    logic [15:0] noise;
    logic [15:0] Gain_D_sqr;
    logic [15:0] noise_randn;
    logic [15:0] sum_0;
    logic [15:0] sum_1;
    logic [15:0] sum_2;
    logic [15:0] sum_3;
    logic [15:0] o_dec_cmd    [ROWS_A];
    logic [15:0] o_dec_err    [ROWS_A];
    logic [15:0] o_ws_spike_f [ROWS_A];
    logic [15:0] o_wf_spike   [ROWS_A]; 

    BF16_Sub Sub_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(One),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(lambdaV_dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(leak_str) // leak_str = (1-lambdaV*dt)
    );
    BF16_Add Add_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_dec_cmd[0]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(o_wf_spike[0]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(sum_0) // sum_0 = D'*c(:,t) + Wf*O(:,t)
    );
    BF16_Add Add_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(sum_0),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(pot_leak),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(sum_1) // sum_1 = sum_0 + (1-lambdaV*dt) * V
    );
    BF16_Add Add_2 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(dec_err_k),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(noise_randn),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(sum_2) // sum_2 = K*D'* (e(:,t)) + nzMemb * randn(N,1)*gainD^2
    );
    BF16_Add Add_3 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(sum_2),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(ws_spike_f_dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(sum_3) // sum_3 = sum_2 + W*rO(:,t)*dt
    );
    BF16_Add Add_4 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(sum_1),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(sum_3),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(o_pot) // o_pot = (1-lambdaV*dt)*V(:,t)+  D'*c(:,t) + Wf*O(:,t) + W*rO(:,t)*dt + nzMemb * randn(N,1)*gainD^2 + K*D'* (e(:,t));
    );
       
    typedef enum logic [1:0] {
        IDLE,
        WAIT_SPIKE,
        START_DEC,
        START_W
    } state_t;

    state_t state, next_state;

    // State machine
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
            state         <= IDLE;
            start_w_reg   <= 0;
            done          <= 0;
        end 
        else begin
            state         <= next_state;
            start_w_reg   <= start_w;
            done          <= done_ws_spike_f;
        end
    end

    always_comb begin
        start_w = 0;
        next_state = state;
        case (state)
            IDLE: begin
                if (start) begin
                    start_w    = 1;
                    next_state = START_DEC;
                end
            end
            WAIT_SPIKE: begin
                if (!wait_spike) begin
                    start_w    = 1;
                    next_state = START_DEC;
                end
            end
            START_DEC: begin
                if (wait_spike) begin
                    start_w    = 0;
                    next_state = WAIT_SPIKE;
                end
                else begin
                    if (done) begin
                        start_w    = 1;
                        next_state = START_DEC;
                    end
                    else begin
                        start_w    = 0;
                        next_state = START_DEC;
                    end
                end
            end
        endcase
    end
    /////////////// Decoder * Command ///////////////
    BF16_Matrix_Mult #(
        .ROWS_A(ROWS_A),
        .COLS_A_ROWS_B(Dims),
        .COLS_B(COLS_B)
    ) dec_cmd (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_w_reg),
        .matrix_a(i_dec_t),
        .matrix_b(i_cmd),
        .result(o_dec_cmd), // D'*c(:,t)
        .next(next_dec),
        .done(done_dec_cmd)
    );
    /////////////// Decoder * Error ///////////////
    BF16_Matrix_Mult #(
        .ROWS_A(ROWS_A),
        .COLS_A_ROWS_B(Dims),
        .COLS_B(COLS_B)
    ) dec_err (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_w_reg),
        .matrix_a(i_dec_t),
        .matrix_b(i_err),
        .result(o_dec_err), // D'* (e(:,t))
        .next(),
        .done(done_dec_err)
    );
    /////////////// Fast Weights * Spikes ///////////////
    BF16_Matrix_Mult #(
        .ROWS_A(ROWS_A),
        .COLS_A_ROWS_B(N),
        .COLS_B(COLS_B)
    ) wf_spike (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_w_reg),
        .matrix_a(i_wf),
        .matrix_b(i_spike),
        .result(o_wf_spike), // Wf*O(:,t)
        .next(),
        .done(done_wf_spike)
    );
    /////////////// Slow Weights * Filtered Spikes ///////////////
    BF16_Matrix_Mult #(
        .ROWS_A(ROWS_A),
        .COLS_A_ROWS_B(N),
        .COLS_B(COLS_B)
    ) ws_spike_f (
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start_w_reg),
        .matrix_a(i_ws),
        .matrix_b(i_spike_f),
        .result(o_ws_spike_f), // W*rO(:,t)
        .next(next),
        .done(done_ws_spike_f)
    );
    /////////////// Slow Weight/Spikes * Dt  ///////////////
    BF16_Mult spike_f_dt (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_ws_spike_f[0]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(ws_spike_f_dt) // ws_spike_f_dt = W*rO(:,t)*dt
    );
    /////////////// Decoder/Error *  Gain Error During Learning ///////////////
    BF16_Mult D_err_K (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_dec_err[0]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(K),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(dec_err_k) // dec_err_k = K*D'* (e(:,t))
    );
    /////////////// Noise Calculations ///////////////
    BF16_Mult Gain_sqr (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(Gain_D),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(Gain_D),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(Gain_D_sqr) // gainD^2
    );
    BF16_Mult Noise (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(NzMemb),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(Gain_D_sqr),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(noise) // nzMemb * gainD^2
    );
    BF16_Mult Noise_rand (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(noise),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(randn),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(noise_randn) // noise_randn = nzMemb * randn(N,1)*gainD^2
    );
    /////////////// Leak ///////////////
    BF16_Mult lambdaVdt (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(LambdaV),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(dt),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(lambdaV_dt) // lambdaV_dt = lambdaV*dt
    );
    BF16_Mult potleak (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(leak_str),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(i_pot),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(pot_leak) // pot_leak = (1-lambdaV*dt) * V
    );

endmodule
