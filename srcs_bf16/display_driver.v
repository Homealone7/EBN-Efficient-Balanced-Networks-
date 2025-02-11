module display_driver(
    input [3:0] thousands,
    input [3:0] hundreds,
    input [3:0] tens,
    input [3:0] ones,
    output [3:0] an,          // Anode signals for 4 digits (active low)
    output [6:0] seg0,        // Segment signals for each 7-segment display (active low)
    output [6:0] seg1,
    output [6:0] seg2,
    output [6:0] seg3
);
    // Instantiate the hex to 7-segment converter for each digit
    hex_to_7seg hex_decoder_thousands(
        .hex(thousands),
        .seg(seg3)
    );

    hex_to_7seg hex_decoder_hundreds(
        .hex(hundreds),
        .seg(seg2)
    );

    hex_to_7seg hex_decoder_tens(
        .hex(tens),
        .seg(seg1)
    );

    hex_to_7seg hex_decoder_ones(
        .hex(ones),
        .seg(seg0)
    );

    // Drive the anode signals (active low)
    assign an = 4'b0000; // All digits are always on (active low)
endmodule
