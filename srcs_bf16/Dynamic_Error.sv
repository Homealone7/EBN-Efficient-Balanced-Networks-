module Dynamic_Error #(
    parameter N      = 64,
    parameter Dims   = 2,
    parameter dyn    = 16'h 4100,
    parameter Lambda = 16'h 4120,
    parameter dt     = 16'h 38d2,
    parameter One    = 16'h 3f80,
    parameter Three  = 16'h 4040
)(
    input  logic        clk,
    input  logic        reset,
    input  logic        reset_iteration,
    input  logic        start,
    input  logic        spike_flg,
    input  logic [5:0]  spike_pos,
    input  logic [15:0] i_cmd   [Dims],        // Commands
    input  logic [15:0] i_dec   [Dims * N],    // Decoder
    output logic [15:0] o_err   [Dims],        // Calculation error
    output logic [15:0] o_x     [Dims],
    output logic [15:0] o_x_est [Dims],
    output logic        done
);

    logic        done_est;
    logic [14:0] read_addr_x0;
    logic [14:0] read_addr_x1;
    logic [15:0] i_x_est [Dims];

    always_ff @(posedge clk ) begin
        if (reset || reset_iteration) begin
            i_x_est   <= '{default: '0};
            read_addr_x0 <= 0;
        end
        else begin
            if (done_est) begin
                i_x_est[0] <= o_x_est[0];
                i_x_est[1] <= o_x_est[1];
                if (read_addr_x0 == 29998)
                    read_addr_x0  <= 0;
                else
                    read_addr_x0  <= read_addr_x0 + 2;
            end
        end
    end

    assign done = done_est;
    assign read_addr_x1 = read_addr_x0 + 14'b1;

    BF16_Sub Sub_0 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_x[0]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(o_x_est[0]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(o_err[0])
    );
    BF16_Sub Sub_1 (
        .s_axis_a_tvalid(1'b1),
        .s_axis_a_tdata(o_x[1]),
        .s_axis_b_tvalid(1'b1),
        .s_axis_b_tdata(o_x_est[1]),
        .m_axis_result_tvalid(),
        .m_axis_result_tdata(o_err[1])
    );

    dynamic_est #(
        .N(N),            
        .Dims(Dims),         
        .Lambda(Lambda),
        .dt(dt),
        .One(One)
    )Estimate(
        .clk(clk),
        .reset(reset),
        .reset_iteration(reset_iteration),
        .start(start),
        .spike_flg(spike_flg),
        .spike_pos(spike_pos),
        .i_dec(i_dec),   
        .i_x_est(i_x_est),    
        .o_x_est(o_x_est), 
        .done(done_est)
    );

    /////////////// Desired Dynamic Memory ///////////////
    Desired_Dyn Desired (
        .clka(clk),    // input wire clka
        .ena(start),      // input wire ena
        .addra(read_addr_x0),  // input wire [14 : 0] addra
        .douta(o_x[0]),  // output wire [15 : 0] douta
        .clkb(clk),    // input wire clkb
        .enb(start),      // input wire enb
        .addrb(read_addr_x1),  // input wire [14 : 0] addrb
        .doutb(o_x[1])
    );

endmodule