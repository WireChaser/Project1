`default_nettype none

module ChipInterface
  (input  logic       CLOCK_50,
   input  logic [3:0] SW,
   input  logic [0:0] KEY,
   output logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5);
	
	logic [23:0] sum, cycles;
	logic [5:0] [3:0] result;
	logic [5:0] [6:0] display;
	
	assign {HEX5, HEX4, HEX3, HEX2, HEX1, HEX0} = display;
	
	assign result = (SW[1]) ? sum : cycles;
	
	MatrixMultiplier MatrixMultiplier
	  (
		 .CLOCK_50(CLOCK_50), 
		 .reset(SW[0]),            
		 .cycle_count(cycles),        			
		 .ReadResultA(),    
		 .ReadResultB(), 
		 .ResultMatrixSum(sum) 
	  );
	 
  genvar a;
  generate 
    for (a = 0; a < 6; a++) begin : generate__decoders 
      SevenSegmentDecoder hex_decoder (
        .hex_input(result[a]),      
        .segment_out(display[a])        
    );
    end
  endgenerate
	
endmodule : ChipInterface