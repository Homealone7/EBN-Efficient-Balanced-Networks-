module hex_to_7seg(
    input [3:0] hex,       // 4-bit input representing a digit (0-9)
    output reg [6:0] seg   // 7-segment output (active low)
);
    always @(*) begin
        case (hex)
            4'h0: seg = 7'b0000001; // Display 0
            4'h1: seg = 7'b1001111; // Display 1
            4'h2: seg = 7'b0010010; // Display 2
            4'h3: seg = 7'b0000110; // Display 3
            4'h4: seg = 7'b1001100; // Display 4
            4'h5: seg = 7'b0100100; // Display 5
            4'h6: seg = 7'b0100000; // Display 6
            4'h7: seg = 7'b0001111; // Display 7
            4'h8: seg = 7'b0000000; // Display 8
            4'h9: seg = 7'b0000100; // Display 9
            default: seg = 7'b0000001; // All segments off (default)
        endcase
    end
endmodule
