module DualPortMemory_tb #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 6,   
    parameter DEPTH = 64 
)(
    input logic                          clk,
    input logic                          reset,       
    // Write port
    input logic                          write_en,  
    input logic         [ADDR_WIDTH-1:0] write_addr, 
    input logic signed  [DATA_WIDTH-1:0] write_data, 
    // Read port
    input logic                          read_en,          
    input logic         [ADDR_WIDTH-1:0] read_addr,  
    output logic signed [DATA_WIDTH-1:0] read_data  
);
    integer i;
    logic signed [DATA_WIDTH-1:0] mem [0: DEPTH-1];
    // Write operation
    always_ff @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < DEPTH; i++) begin
                mem[i] <= 0;
            end
        end
        else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end
    // Read operation
    always_ff @(posedge clk) begin
        if (read_en) begin
            read_data <= mem[read_addr];
        end
    end

endmodule

module mem_tb;
    parameter N                 = 64;
    parameter Dims              = 2;
    parameter Noise             = 16'b 1;
    parameter Gain_Dec          = 16'b 1;
    parameter Gain_err          = 16'b 1;
    parameter pot_thr           = 16'b 1;
    parameter LambdaV           = 16'b 1;
    parameter dt                = 16'b 1;
    parameter One               = 16'b 1;
    parameter INTEGER_BITS      = 8;
    parameter FRACTIONAL_BITS   = 8;
    parameter A_ROWS            = 1;
    parameter B_COLS            = 1;
    logic start_spike_out, done_lif_AU, done_lif_neuron, done_spike;
    logic [5:0] neur_addr, read_addr, index;
    logic signed  [INTEGER_BITS + FRACTIONAL_BITS -1:0]  neur_data, lif_AU_result, o_pot, dec_t[Dims], spike_tmp [N]; //i_cmd[Dims];
    logic spike_data[N]; 
    logic clk, reset, start;
    integer counter = 0;

    DualPortMemory_tb #(
        .DATA_WIDTH(INTEGER_BITS + FRACTIONAL_BITS),
        .ADDR_WIDTH(6),
        .DEPTH(N)
    )DualPortMemory_tb(
        .clk(clk),
        .reset(reset),
        .read_en(done_lif_AU),
        .read_addr(read_addr),
        .read_data(neur_data),
        .write_en(done_lif_neuron),
        .write_addr(read_addr - 1'b1),
        .write_data(o_pot)         
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
        start = 0;
        done_lif_neuron = 0;
        read_addr = 0;
        #10
        reset = 0;
        start = 1;
        #15
        $finish;
    end
    
endmodule