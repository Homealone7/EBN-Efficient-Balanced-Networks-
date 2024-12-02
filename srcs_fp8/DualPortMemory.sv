module DualPortMemory #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6,   
    parameter DEPTH = 64 
)(
    input  logic                  clk,
    input  logic                  reset,
    input  logic                  reset_iteration,       
    // Write
    input  logic                  write_en,  
    input  logic [ADDR_WIDTH-1:0] write_addr, 
    input  logic [DATA_WIDTH-1:0] write_data, 
    // Read
    input  logic                  read_en,          
    input  logic [ADDR_WIDTH-1:0] read_addr,  
    output logic [DATA_WIDTH-1:0] read_data  
);
    integer i;
    logic [DATA_WIDTH-1:0] mem [0: DEPTH - 1];
    // Write operation
    always_ff @(posedge clk) begin
        if (reset || reset_iteration) begin
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