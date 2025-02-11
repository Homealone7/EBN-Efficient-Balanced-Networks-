module bin_to_bcd(
    input [11:0] binary,        // 12-bit binary input
    output reg [3:0] thousands,
    output reg [3:0] hundreds,
    output reg [3:0] tens,
    output reg [3:0] ones
);
    reg [19:0] shift;
    integer i;

    always @(*) begin
        // Initialize shift register
        shift = {8'b0, binary};  // 20-bit register, top 8 bits are 0, bottom 12 bits are the input

        // Perform the double-dabble algorithm
        for (i = 0; i < 12; i = i + 1) begin
            // Shift left by 1
            shift = shift << 1;

            // If BCD digits are >= 5, add 3
            if (shift[19:16] >= 5)
                shift[19:16] = shift[19:16] + 3;

            if (shift[15:12] >= 5)
                shift[15:12] = shift[15:12] + 3;

            if (shift[11:8] >= 5)
                shift[11:8] = shift[11:8] + 3;
        end

        // Assign the BCD digits
        thousands = shift[19:16];
        hundreds  = shift[15:12];
        tens      = shift[11:8];
        ones      = shift[7:4];
    end
endmodule
