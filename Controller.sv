`timescale 1ps / 1ps

module Controller 
	#(parameter ADDR_WIDTH = 7)
	(
	input logic clock, reset, end_operation,    // Clock, reset, and signal indicating end of matrix operation
	output logic sum, clear, mult, write,       // Control signals for MAC unit and RAM
	output logic [23:0] cycle_count,           // Counter for clock cycles used in matrix operation
	output logic [(2*ADDR_WIDTH)-1:0] romA_addrA, romA_addrB,  // Address for ROM A (dual-port)
	output logic [ADDR_WIDTH-1:0] romB_addrA, romB_addrB,      // Address for ROM B (dual-port)
	output logic [ADDR_WIDTH-1:0] romC_addrA, romC_addrB,      // Address for ROM C (dual-port)
	output logic [ADDR_WIDTH-1:0] result_addrA, result_addrB  // Address for result RAM (dual-port)
	);
	
	/*** Starting addresses for ROMs and RAM ***/
	localparam ROM_A_START_ADDR = 14'd8192; 
	localparam ROM_B_START_ADDR = 7'd0;
	localparam ROM_C_START_ADDR = 7'd64;
	localparam RAM_START_ADDR = 7'd64;
	
	typedef enum logic [2:0] {READ, LOAD, WRITE, CLEAR, END} state_t;   // State machine states
	logic cycle_stop, last_addressB;                                    // Control signals
	
	state_t current_state;
	
	/*** Logic to Determine Last Address for romB_addrB ***/
	always_comb begin
		last_addressB = (romB_addrB == 7'd124);   // Assert last_addressB if romB_addrB reaches its final value
	end
	
	/*** State Machine: Controls the Flow of the Matrix Multiplication Process ***/
	always_ff @(posedge clock) begin
		if (reset) begin
			current_state <= READ;
		end 
		else begin
			case (current_state)
				READ:   current_state <= (last_addressB) ? LOAD : READ;   // Read data from ROM A and ROM B for multiplication
				LOAD:   current_state <= WRITE;                           // Load data from ROM C for final addition
				WRITE:  current_state <= (end_operation) ? END : CLEAR;   // Write final result to RAM or clear for next iteration
				CLEAR:  current_state <= READ;                          	// Clear the accumulator in the MAC unit
				END:    current_state <= END;                          	// End state (halt operation)
				default: current_state <= READ;                           // Default to READ state
			endcase
		end
	end
	
	/*** Combinational Logic to Generate Control Signals Based on Current State ***/
	always_comb begin 
		sum     = (current_state == LOAD);    // Enable final addition in MAC unit
		write   = (current_state == WRITE);   // Enable write to result RAM
		clear   = (current_state == CLEAR);   // Clear MAC unit accumulators
		mult    = (current_state == READ);    // Enable multiplication in MAC unit
		cycle_stop = (current_state == END); // Stop the cycle counter when in END state
	end
	
	/*** Clock Cycle Counter: Tracks the Total Cycles for the Matrix Operation ***/
	always_ff @(posedge clock) begin
		if (reset) begin
			cycle_count <= 0;
		end else if (~cycle_stop) begin        
			cycle_count <= cycle_count + 24'd1; // Increment cycle count if not in END state
		end 
	end 
	
	/*** Address Counters for ROMs and RAM: Generates Addresses for Data Access ***/
	always_ff @(posedge clock) begin
		if (reset) begin
			// Initialize all addresses to their starting values
			romA_addrA   <= '0;         
			romB_addrA   <= '0;        
			romC_addrA   <= '0;
			result_addrA <= '0;
			romA_addrB   <= ROM_A_START_ADDR;   
			romB_addrB   <= ROM_B_START_ADDR;   
			romC_addrB   <= ROM_C_START_ADDR;  
			result_addrB <= RAM_START_ADDR;   
		end 
		else if (current_state == READ) begin 
			// Increment addresses for ROM A and B in the READ state
			romA_addrA <= romA_addrA + 14'd4;    
			romB_addrA <= romB_addrA + 7'd4;
			romA_addrB <= romA_addrB + 14'd4;    
			romB_addrB <= romB_addrB + 7'd4;     
		end 
		else if (current_state == LOAD) begin
			// Increment addresses for ROM C in the LOAD state and resets ROM B to avoid overflow
			romB_addrA <= '0;
			romB_addrB <= '0;
			romC_addrA <= romC_addrA + 7'd1;   
			romC_addrB <= romC_addrB + 7'd1;   
		end 
		else if (current_state == CLEAR) begin 
			// Increment addresses for result RAM in the CLEAR state
			result_addrA <= result_addrA + 7'd1; 
			result_addrB <= result_addrB + 7'd1;
		end 
	end
endmodule : Controller
