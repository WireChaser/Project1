module SevenSegmentDecoder (
    input logic [3:0] hex_input,          // 4-bit Hexadecimal input
    output logic [6:0] segment_out       // 7-segment outputs (a, b, c, d, e, f, g)
);

  always_comb begin
    case (hex_input)
      4'h0: segment_out = ~7'b011_1111;  // 0
      4'h1: segment_out = ~7'b000_0110;  // 1
      4'h2: segment_out = ~7'b101_1011;  // 2
      4'h3: segment_out = ~7'b100_1111;  // 3
      4'h4: segment_out = ~7'b110_0110;  // 4
      4'h5: segment_out = ~7'b110_1101;  // 5
      4'h6: segment_out = ~7'b111_1101;  // 6
      4'h7: segment_out = ~7'b000_0111;  // 7
      4'h8: segment_out = ~7'b111_1111;  // 8
      4'h9: segment_out = ~7'b110_0111;  // 9
      4'hA: segment_out = ~7'b111_0111;  // A
      4'hB: segment_out = ~7'b111_1100;  // b
      4'hC: segment_out = ~7'b011_1001;  // C
      4'hD: segment_out = ~7'b101_1110;  // d
      4'hE: segment_out = ~7'b111_1001;  // E
      4'hF: segment_out = ~7'b111_0001;  // F 
      default: segment_out = ~7'b000_0000; 
    endcase
  end
endmodule
