`timescale 1ps / 1ps

module MatrixMultiplier 
  #(parameter DATA_WIDTH = 8,        // Width of individual data elements (8 bits)
            ADDR_WIDTH = 7,         // Width of the address bus for smaller ROMs (7 bits)
            RESULT_WIDTH = 24)       // Width of the final result and accumulator (24 bits)
  (
    input logic CLOCK_50, reset,            
    output logic [23:0] cycle_count,        			// Counter for clock cycles during operation
    output logic [RESULT_WIDTH-1:0] ReadResultA,    // Data read from Result RAM port A
    output logic [RESULT_WIDTH-1:0] ReadResultB,    // Data read from Result RAM port B
    output logic [RESULT_WIDTH-1:0] ResultMatrixSum // Final sum of Result RAM
  );

  // Control Signals
  logic mult, clear, sum, write, end_operation;   

  // Address Buses for ROMs and Result RAM
  logic [(2*ADDR_WIDTH)-1:0] romA_addrA, romA_addrB; // ROM A addresses (dual-port)
  logic [ADDR_WIDTH-1:0] romB_addrA, romB_addrB;    // ROM B addresses (dual-port)
  logic [ADDR_WIDTH-1:0] romC_addrA, romC_addrB;    // ROM C addresses (dual-port)
  logic [ADDR_WIDTH-1:0] result_addrA, result_addrB; // Result RAM addresses (dual-port)

  // Data Buses
  logic [3:0] [DATA_WIDTH-1:0] romA_busA_data, romA_busB_data;  // ROM A data output
  logic [3:0] [DATA_WIDTH-1:0] romB_busA_data, romB_busB_data;  // ROM B data output
  logic [(2*DATA_WIDTH)-1:0] romC_dataA, romC_dataB;          // ROM C data output
  logic [RESULT_WIDTH-1:0] finalResultA, finalResultB;         // Final results from MAC unit

  /***************************************************************
  * Controller Module:
  *   - Manages the overall operation of the matrix multiplier.
  *   - Generates control signals (sum, clear, mult, write) based on the state of the computation.
  *   - Provides addresses for the ROMs and the result RAM.
  ***************************************************************/
  Controller #(ADDR_WIDTH) Controller (
    .clock(CLOCK_50),
    .reset(reset),
    .sum(sum),
    .clear(clear),
    .mult(mult),
    .cycle_count(cycle_count),
    .write(write),
    .end_operation(end_operation),
    .romA_addrA(romA_addrA), 
    .romA_addrB(romA_addrB),
    .romB_addrA(romB_addrA), 
    .romB_addrB(romB_addrB),
    .romC_addrA(romC_addrA), 
    .romC_addrB(romC_addrB),
    .result_addrA(result_addrA),
    .result_addrB(result_addrB)
  );

  /***************************************************************
  * Matrices Module:
  *   - Instantiates the ROMs (romA, romB, romC) used to store the input matrices.
  *   - Provides the data from the ROMs to the MAC unit based on the addresses from the controller.
  ***************************************************************/
	Matrices #(DATA_WIDTH, ADDR_WIDTH) Matrices
		(.clock(CLOCK_50),
		.reset(reset),
		.romA_addrA(romA_addrA),
		.romA_addrB(romA_addrB),
		.romB_addrA(romB_addrA),
		.romB_addrB(romB_addrB),
		.romC_addrA(romC_addrA),
		.romC_addrB(romC_addrB),
		.romA_busA_out(romA_busA_data),
		.romA_busB_out(romA_busB_data),
		.romB_busA_out(romB_busA_data),
		.romB_busB_out(romB_busB_data),
		.romC_dataA_out(romC_dataA),
		.romC_dataB_out(romC_dataB));
	
	/***************************************************************
  * MultAccumulate (MAC) Unit:
  *   - Performs the core multiply-accumulate operations.
  *   - Takes data from the ROMs and accumulates the results.
  ***************************************************************/
	MultAccumulate #(DATA_WIDTH, RESULT_WIDTH) MAC_Unit
		(.enable_sum(sum),
		.enable_mult(mult),
		.clock(CLOCK_50),
		.clear(clear),
		.reset(reset),
		.romA_busA_data(romA_busA_data),
		.romA_busB_data(romA_busB_data),
		.romB_busA_data(romB_busA_data),
		.romB_busB_data(romB_busB_data),
		.romC_dataA(romC_dataA),
		.romC_dataB(romC_dataB),
		.finalResultA(finalResultA),
		.finalResultB(finalResultB));
	
	/***************************************************************
  * ResultMatrix Module:
  *   - Stores the final results of the MAC operations in a RAM.
  *   - Provides the capability to read back results and also calculates the final sum of the matrix.
  ***************************************************************/
   ResultMatrix #(ADDR_WIDTH, RESULT_WIDTH) ResultMatrix
		(.clock(CLOCK_50),
		.reset(reset),
		.write(write),
		.addrA(result_addrA), 
		.addrB(result_addrB),
		.end_operation(end_operation),
		.dataA_in(finalResultA),
		.dataB_in(finalResultB),
		.addrA_value(ReadResultA),
		.addrB_value(ReadResultB),
		.matrixSum(ResultMatrixSum));
		
endmodule 
