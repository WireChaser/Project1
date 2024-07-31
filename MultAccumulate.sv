`timescale 1ps / 1ps

module MultAccumulate 
  #(parameter DATA_WIDTH = 8,        // Width of individual data elements (8 bits)
            RESULT_WIDTH = 24)        // Width of the multiplication results and accumulators (24 bits)
  (
    input logic enable_sum,                 // Control signal to enable final output
    input logic enable_mult,                // Control signal to enable multiplication and accumulation
    input logic clock, clear, reset,        // Clock, clear, and reset signals
    input logic [3:0] [DATA_WIDTH-1:0] romA_busA_data, romA_busB_data,  // Data from ROM A (port A and port B)
    input logic [3:0] [DATA_WIDTH-1:0] romB_busA_data, romB_busB_data,  // Data from ROM B (port A and port B)
    input logic [2*DATA_WIDTH-1:0] romC_dataA, romC_dataB,             // Data from ROM C
    output logic [RESULT_WIDTH-1:0] finalResultA, finalResultB          // Final results
  );

  // Intermediate signals to hold multiplication results
  logic [RESULT_WIDTH-1:0] multResultA [3:0]; 
  logic [RESULT_WIDTH-1:0] multResultB [3:0];

  /*** Instantiate 4 Multipliers for (ROM-A Port-A data x ROM-B Port-A data) ***/
  genvar a;
  generate 
    for (a = 0; a < 4; a++) begin : generate_multA_instances 
      Multiplier #(DATA_WIDTH, RESULT_WIDTH) Multipliers_inst (
        .dataa(romA_busA_data[a]),        // Input data from ROM A (port A)
        .datab(romB_busA_data[a]),        // Input data from ROM B (port A)
        .result(multResultA[a])           // Output the multiplication result
      );
    end
  endgenerate

  /*** Instantiate 4 Multipliers for (ROM-A Port-B data x ROM-B Port-B data) ***/
  genvar b;
  generate 
    for (b = 0; b < 4; b++) begin : generate_multB_instances 
      Multiplier #(DATA_WIDTH, RESULT_WIDTH) Multipliers_inst (
        .dataa(romA_busB_data[b]),        // Input data from ROM A (port B)
        .datab(romB_busB_data[b]),        // Input data from ROM B (port B)
        .result(multResultB[b])           // Output the multiplication result
      );
    end
  endgenerate

  /**********************************************************************************************************************************
   * Pipeline Registers: 
   *  - Delay the 'enable_sum' and 'enable_mult' control signals by two clock cycles.
   **********************************************************************************************************************************/
  logic enable_sum_q1, enable_sum_q2, enable_mult_q1, enable_mult_q2;
  always_ff @(posedge clock) begin
    if (reset) begin
      enable_sum_q1 <= '0;
      enable_mult_q1 <= '0;
    end else begin 
      enable_sum_q1 <= enable_sum;
      enable_mult_q1 <= enable_mult;
      enable_sum_q2 <= enable_sum_q1;
      enable_mult_q2 <= enable_mult_q1;
    end 
  end 

  /**********************************************************************************************************************************
   * Accumulators and Data Registers:
   *   - 'accumResultA1', 'accumResultA2', 'accumResultB1', 'accumResultB2': Accumulate partial sums of multiplication results.
   *   - 'romC_dataA_reg', 'romC_dataB_reg': Registers to hold data from ROM C for the final addition.
   **********************************************************************************************************************************/
  logic [RESULT_WIDTH-1:0] accumResultA1, accumResultB1, accumResultA2, accumResultB2;
  logic [RESULT_WIDTH-1:0] romC_dataA_reg, romC_dataB_reg; // Registers for data from ROM C

  always_ff @(posedge clock) begin
    if (reset) begin
      // Reset all accumulator and register values to 0
      accumResultA1 <= '0;    
      accumResultA2 <= '0;    
      accumResultB1 <= '0;    
      accumResultB2 <= '0;   
      romC_dataA_reg <= '0;
      romC_dataB_reg <= '0;
    end else if (clear) begin
      // Clear only the accumulator values, keeping ROM C data intact
      accumResultA1 <= '0; 
      accumResultA2 <= '0;
      accumResultB1 <= '0;
      accumResultB2 <= '0;
    end else if (enable_mult_q2) begin  
      // Accumulate multiplication results and register ROM C data
      romC_dataA_reg <= romC_dataA; // Capture ROM C data to avoid timing hazards 
      romC_dataB_reg <= romC_dataB;
      accumResultA1 <= accumResultA1 + multResultA[0] + multResultA[1]; 
      accumResultA2 <= accumResultA2 + multResultA[2] + multResultA[3];
      accumResultB1 <= accumResultB1 + multResultB[0] + multResultB[1];
      accumResultB2 <= accumResultB2 + multResultB[2] + multResultB[3];
    end
  end
  
  /**********************************************************************************************************************************
   * Final Output:
   *   - Combine accumulator results with ROM C data and output when 'enable_sum' is asserted.
   *   - Use 'z' (high-impedance) output when 'enable_sum' is not asserted.
   **********************************************************************************************************************************/

  assign finalResultA = (enable_sum_q2) ? (accumResultA1 + accumResultA2 + romC_dataA_reg) : 'z; 
  assign finalResultB = (enable_sum_q2) ? (accumResultB1 + accumResultB2 + romC_dataB_reg) : 'z;      
endmodule : MultAccumulate


