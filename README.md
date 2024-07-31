# Hardware Accelerated Matrix Multiplier
## Project Overview

This project implements a high-performance matrix multiplier designed for FPGAs. The goal is to efficiently compute the result of the following matrix equation:

Y (24-bit) = A (8-bit) * B (8-bit) + C (16-bit)

where:

- A: 128x128 matrix of 8-bit unsigned integers
- B: 128x1 column vector of 8-bit unsigned integers
- C: 128x1 column vector of 16-bit unsigned integers
- Y: 128x1 column vector of 24-bit unsigned integers

The project addresses the challenge of performing this computation efficiently in hardware, leveraging the FPGA's parallel processing capabilities and specialized hardware resources.

## Module Summaries
**MatrixMultiplier**

&#45; Top-Level Module: Integrates and connects all other modules to form the complete matrix multiplier system.

**Controller**

&#45; Finite State Machine (FSM): Controls the sequence of operations (reading input data, performing MAC operations, storing results) through different states (READ, LOAD, WRITE, CLEAR, END).                                                
&#45; Address Generation: Generates addresses for the ROMs (romA, romB, romC) and the result RAM based on the current state.                
&#45; Control Signal Generation: Produces control signals (sum, clear, mult, write) to activate specific operations in the MAC unit and result RAM.            
&#45; Clock Cycle Counter: Keeps track of the total clock cycles used for the matrix multiplication.            
&#45; End-of-Operation Signal: Generates the end_operation signal when the computation is finished.            

**Matrices**

&#45; ROM Interfaces: Instantiates multiple ROM modules to store the input matrices A, B, and C.
&#45; Parallel Data Access: Provides parallel access to the data elements of the input matrices, utilizing dual-port ROMs.
&#45; Pipelined Outputs: Registers the ROM output data to improve timing performance.

**MultAccumulate (MAC)**

&#45; Parallel Multipliers: Instantiates multiple Multiplier modules to perform parallel multiplication of data elements from ROM A and ROM B.        
&#45; Accumulation: Accumulates the results of the multiplications, along with the corresponding values from ROM C.                
&#45; Pipelining: Uses pipeline registers to synchronize control signals and data flow, to meet timing requirements.                
&#45; Output: Provides the final accumulated results (finalResultA, finalResultB) for each computation cycle.

**ResultMatrix**

&#45; Result Storage: Stores the final results from the MAC unit in a dual-port RAM.                        
&#45; Result Accumulator: Accumulates the sum of all the results stored in the RAM.                                    
&#45; Read/Write Interface: Provides ports for reading individual results and the final accumulated sum.                        
&#45; End-of-Operation Signal: Generates the end_operation signal when all results have been written to RAM and accumulated.

**ChipInterface**

&#45; I/O Interface: Connects the matrix multiplier design to the FPGA board's switches and seven-segment displays.                        
&#45; Control and Display: Uses switches to control the reset signal and select between displaying the result or cycle count on the seven-segment displays.            
&#45; Seven-Segment Decoder: Instantiates SevenSegmentDecoder modules to convert numerical values into the appropriate patterns for the displays.        

## Timing Constraints and Optimization

The design is targeted for a 50 MHz clock constraint. Significant effort was put into meeting this constraint while maintaining high throughput.  Some of the key challenges and solutions included:

- Wallace Tree Multiplier: Initial attempts to use a Wallace tree multiplier were unsuccessful due to the long critical path. Switching to the lpm_mult IP core significantly reduced this path and improved overall timing. 
- Controller Signal Delays: Delayed load signals to the ROMs caused the same address values to be multiplied twice. Adding pipeline registers to synchronize the control signals resolved this issue.
- IO Pin Limitations: Early implementations exceeded the FPGA's 224 available IO output pads due to the large number of instantiated ROM blocks in the Matrices module. Limiting the number of ROM blocks to 8 resolved this issue.
- Accumulator Bottleneck: The original design used a single accumulator for all multiplication results, which became a timing bottleneck. By introducing additional accumulators to handle the addition of two results at a time instead of four, the FMAX was improved to 93 MHz.

## Design Testing

Each module in the design (Controller, Matrices, MultAccumulate, and ResultMatrix) was individually tested to verify their functionality. However, these tests were not comprehensive and are not included in this repository. A more thorough testbench is currently under development to comprehensively test the entire MatrixMultiplier module.

## Future Work and Improvements

**Increased Parallelism:** Explore increasing the number of ROM blocks and parallel multipliers in the Matrices and MultAccumulate modules to further accelerate computation.    
**Systolic Array Implementation:** Investigate implementing a systolic array architecture for the MAC unit, potentially leading to significant improvements in throughput and efficiency.                          
**Alternative Algorithms:** Experiment with alternative matrix multiplication algorithms (e.g., Strassen's algorithm) to potentially reduce the number of operations required.  
**Improved Error Handling:** Add robust error detection and handling mechanisms to ensure the reliability of the design.

## Implementation Details

**ROM Initialization:** The input matrices A, B, and C are initialized using .mif (Memory Initialization File) format.               
**Load Matrix Data:** Loaded the input matrices (A, B, and C) into the corresponding .mif files.                          
**Synthesize and Implement:** Used Intel Quartus Prime to synthesize and implement the design for your Cyclone V FPGA board.             
**Program the FPGA:** Loaded the generated bitstream to the Cyclone V FPGA Board.                       
**Observe Results:** The seven-segment displays will show either the calculated matrix sum or the number of clock cycles taken, depending on the state of switch SW[1].

## Acknowledgments

This project was inspired by a project assignment in the Logic Design and Verification course at Carnegie Mellon University.  The original assignment provided the foundation for this implementation.
Below are files from the 18341 repository that were used or modified for this project. 

Files used: matA.mif, matA_2.mif, matB.mif, matB_2.mif, matC.mif, matC_2.mif                                                    
Files used and modified: Multiplier.sv, ChipInterface.sv
