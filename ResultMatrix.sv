`timescale 1ps / 1ps

module ResultMatrix 
   #(parameter ADDR_WIDTH = 7,        // Address width for the RAM (supports up to 128 addresses)
             RESULT_WIDTH = 24)        // Data width for the RAM and accumulator (24 bits)
   (
     input logic clock, reset, write,                // Clock, reset, and write enable signals
     input logic [ADDR_WIDTH-1:0] addrA, addrB,      // Read/write addresses for the RAM
     input logic [RESULT_WIDTH-1:0] dataA_in, dataB_in,  // Input data to be written to the RAM
     output logic end_operation,                  // Signal indicating the end of the matrix operation
     output logic [RESULT_WIDTH-1:0] addrA_value, addrB_value, // Output data read from the RAM
     output logic [RESULT_WIDTH-1:0] matrixSum     // Accumulated sum of all values in the RAM
   );

   logic write_q;                     
   logic [RESULT_WIDTH-1:0] accumulator;  

   /*** Delays the 'write' signal by one clock cycle. ***/
   always_ff @(posedge clock) begin
     if (reset) begin
       write_q <= '0;
     end else begin
       write_q <= write;   
     end
   end

   assign end_operation = &addrB; 

   /*** Dual-port RAM  Instantiation for Results of Matrix Operation ***/
   ram_result #(ADDR_WIDTH, RESULT_WIDTH) ResultMatrix 
      (.address_a(addrA),      
      .address_b(addrB),      
      .clock(clock),
      .data_a(dataA_in),   
      .data_b(dataB_in),      
      .q_a(addrA_value),      
      .q_b(addrB_value),      
      .wren_a(write_q),     
      .wren_b(write_q));

   /*** Accumulates the sum of all values written to the RAM ***/
   always_ff @(posedge clock) begin
     if (reset) begin
       accumulator <= '0;       
     end else if (write_q) begin
       accumulator <= accumulator + dataA_in + dataB_in; 
     end
   end

   /*** Matrix Sum provides the final accumulated sumwhen the 'end_operation' signal is asserted ***/
   assign matrixSum = (end_operation) ? accumulator : 'z;
endmodule : ResultMatrix

