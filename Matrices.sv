`timescale 1ps / 1ps

module Matrices 
  #(parameter DATA_WIDTH = 8,        // Width of individual data elements (8 bits)
            ADDR_WIDTH = 7)        // Width of the address bus for ROMs B and C (7 bits)
  (
    input logic clock, reset,                   // Clock and reset signals
    input logic [(2*ADDR_WIDTH)-1:0] romA_addrA, romA_addrB,    // Address for ROM A (dual-port, 14-bit)
    input logic [ADDR_WIDTH-1:0] romB_addrA, romB_addrB,        // Address for ROM B (dual-port, 7-bit)
    input logic [ADDR_WIDTH-1:0] romC_addrA, romC_addrB,        // Address for ROM C (dual-port, 7-bit)
    output logic [3:0] [DATA_WIDTH-1:0] romA_busA_out,         // Data output from ROM A (port A)
    output logic [3:0] [DATA_WIDTH-1:0] romA_busB_out,         // Data output from ROM A (port B)
    output logic [3:0] [DATA_WIDTH-1:0] romB_busA_out,         // Data output from ROM B (port A)
    output logic [3:0] [DATA_WIDTH-1:0] romB_busB_out,         // Data output from ROM B (port B)
    output logic [(2*DATA_WIDTH)-1:0] romC_dataA_out, romC_dataB_out // Data output from ROM C
  );

  // Intermediate signals to hold data read from the ROMs
  logic [3:0] [DATA_WIDTH-1:0] romA_addrA_value, romA_addrB_value;  
  logic [3:0] [DATA_WIDTH-1:0] romB_addrA_value, romB_addrB_value; 
  logic [(2*DATA_WIDTH)-1:0] romC_addrA_value, romC_addrB_value;

  /*** Pipelined Data Outputs for all ROMs ***/
  always_ff @(posedge clock) begin
    if (reset) begin
      romA_busA_out <= '0;
      romA_busB_out <= '0;
      romB_busA_out <= '0;
      romB_busB_out <= '0;
      romC_dataA_out <= '0;
      romC_dataB_out <= '0;
    end else begin
      romA_busA_out <= romA_addrA_value;  
      romA_busB_out <= romA_addrB_value;  
      romB_busA_out <= romB_addrA_value;  
      romB_busB_out <= romB_addrB_value;  
      romC_dataA_out <= romC_addrA_value; 
      romC_dataB_out <= romC_addrB_value; 
    end 
  end
 
  /*** ROM Instantiations ***/
  genvar a;
  generate 
    for (a = 0; a < 4 ; a++) begin : generate_romA_instances  
      romA #(DATA_WIDTH, 2*ADDR_WIDTH) MatrixA_inst_gen 
        (.address_a(romA_addrA + 6'(a)),     // Increment address for each ROM A instance
        .address_b(romA_addrB + 6'(a)),     // Increment address for each ROM A instance (dual-port)
        .clock(clock), 
        .q_a(romA_addrA_value[a]),         // Output data from ROM A (port A)
        .q_b(romA_addrB_value[a]));        // Output data from ROM A (port B)
    end
  endgenerate

  genvar b;
  generate 
    for (b = 0; b < 4 ; b++) begin : generate_romB_instances  
      romB #(DATA_WIDTH, ADDR_WIDTH) MatrixB_inst_gen 
        (.address_a(romB_addrA + 3'(b)),      // Increment address for each ROM B instance
        .address_b(romB_addrB + 3'(b)),      // Increment address for each ROM B instance (dual-port)
        .clock(clock), 
        .q_a(romB_addrA_value[b]),         // Output data from ROM B (port A)
        .q_b(romB_addrB_value[b]));        // Output data from ROM B (port B)
    end
  endgenerate

  romC #(2*DATA_WIDTH, ADDR_WIDTH) MatrixC 
    (.address_a(romC_addrA),             // Address for ROM C (port A)
    .address_b(romC_addrB),             // Address for ROM C (port B)
    .clock(clock), 
    .q_a(romC_addrA_value),            // Output data from ROM C (port A)
    .q_b(romC_addrB_value));           // Output data from ROM C (port B)

endmodule : Matrices
