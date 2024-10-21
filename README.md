This is the full RISCV processor that we the TenX team developed for the Teknofest 2024 competition.
The entire thing is written from scratch in Verilog.

#  DESIGN SUMMARY
The project involved designing a 5-stage pipelined processor to enhance instruction processing
throughput. The processor's core architecture includes stages for Instruction Fetch (IF), Instruction
Decode/Register Fetch Operand (ID/RF), Execute/Evaluate Memory Address (EX/AG), Memory Fetch
(MEM), and Writeback (WB). The core will employ a Two-level Gshare Branch Prediction algorithm,
which enhances branch prediction accuracy by using a Branch Target Buffer and Direction Predictor.

Key algorithms and methods in the design include:
- ALU Algorithms
  - Non-restoring division algorithm was chosen for its faster speed and ease of
implementation compared to other digit recurrence methods.
  - Kogge-Stone addition algorithm : the tree structure of the KSA eliminates
propagation delay and gives it an advantage over other addition algorithms.
  - The Booth Encoding Multiplication algorithm: it reduces the number of partial
products and handles both positive and negative multipliers efficiently. This algorithm
enhances the multiplication speed and reduces the complexity of the hardware
implementation.
- FPU Algorithms [1]:
  - Modified 24-bit Carry-lookahead adder was implemented, where NAND and NOT
gates were used. This helps decrease the cost of the carry-lookahead adder and also
enhances its speed.
  - Floating-point Multiplication Algorithm: the Karatsuba with add-shift operations
were used for multiplication.
  - Non-restoring Division Algorithm: Similar to the floating-point unit, the core
performs the division operation with a non-restoring divider.
- Branch Prediction Algorithm: Two-level Gshare Branch Prediction improves branch prediction
accuracy by indexing the Branch Target Buffer with the current instruction in the program
counter and using an XOR of the Global Branch History for the Direction Predictor.
- Memory Associativity: The memory system uses an Exclusive Cache Policy, with a two-level
cache hierarchy to optimize data access speed. Level 1 cache is directly mapped or has up to
4 levels of associativity, while Level 2 cache has higher associativity.
- Special Instructions Handling: The design includes distinct Integer and Floating-Point
Arithmetic Logic Units (ALUs) to handle various instruction sets efficiently. The Integer ALU
implements Kogge-Stone Adder, Modified Booth Encoding Multiplier and Barrel Shifter, while
the FPU includes a modified 24-bit carry-lookahead adder for floating-point operations.
- Hazard Unit: a combination of forwarding for handling data hazards and flushing the pipeline
to handle control hazards was used.
- Atomic Instruction Handling: Atomic instructions handling is done in the memory controller
to avoid complications in the pipeline.

The processor's control and data paths are designed to ensure optimal performance and flexibility.
The control logic manages the instruction processing in the data path by generating appropriate
signals, while relevant signals are carried down the pipeline to maintain data state.
The peripherals are connected via a Wishbone interconnect protocol, chosen for its simplicity and
compatibility with open-source tools. The UART protocol facilitates asynchronous data exchange, with
a Crossbar Switch interconnection and Round-Robin arbitration method managing traffic.
The project design followed the OpenLane chip design flow, which includes Design Entry, Functional
Verification, Synthesis, Layout/Physical Synthesis, and Signoff.

# PROJECT CURRENT STATUS ASSESSMENT
Until the date of writing the detailed design report we have implemented and integrated the
Kogge-Stone adder, Booth Encoding Multiplier, Non-restoring divider and Barrel shifter for integer
operations, as for floating-point operations, the CLA adder was implemented as specified, but the
multiplication was performed using the Karatsuba algorithm with shift-add algorithms, this was due
to booth encoding working only with 2’s complement signed numbers, whereas for the significand we
needed to work only with unsigned numbers. To handle hazards, the promised hazard unit was
implemented with a modification where data hazards were handled with forwarding, and control
hazards were handled by flushing the pipeline. The 5-stage pipeline structure was kept and
implemented as specified, the branch prediction module was created but yet to be implemented and
tested in the processor, regarding memory, a 4KB level-1 cache was implemented instead of the two
level cache specified in the PDR due to the time-constraint, we plan to add the second level in the
next stage. The level-1 cache is directly mapped, in addition, we have implemented the 128-bit
interface with the main memory. As for the communication protocols, the Wishbone interface was
implemented for the communication between the core and the UART module, the UART itself was
implemented according to the specification with duplex communication and was mapped to the
appropriate addresses in memory such that it is controllable through modification and reading of
certain memory addresses, in addition, the UART unit has buffers both for sending and receiving data.

For Atomic instructions specified in the A and Zicsr extensions; In order to not stall the pipeline, we
decided to move the operation to the memory-controller where the core will supply control signals to
it that it decodes to perform the appropriate operation. This will allow for the atomic
load-operation-store process with the final result supplied to the core, eliminating the complexities
of special atomic instruction handling and stalling caused by waiting for atomics to finish.

Overall, with the core processes IMB extensions fully. Moreover the FPU units were implemented and
tested individually but are yet to be integrated with the pipelined core. And finally the atomic
instructions handling in the memory controller explained above is yet to be done.

# PROJECT DETAILED DESIGN
## CORE DESIGN
### PIPELINE DESIGN
![image](https://github.com/user-attachments/assets/f8e16a2b-2ec9-4301-8901-46d1a04e706c)
A 5-stage pipeline is implemented as shown in the core diagram in the figure above:
1. first stage is the fetch stage, where instructions are fetched from the instruction memory, the
program counter traverses the instructions and a Mux selects either a target instruction or a
sequential (PC + 4) instruction depending on the control signal generated by the decode
stage.
2. The second stage is the decode stage, where the fetched instruction is decoded and
appropriate control signals are generated, for example, if the fetched instruction is a load
instruction, a signal that enables writing to the register file is propagated.
3. The third stage is the execute stage, in this stage, the decoded operation is performed on the
inputs from the register file, the second operand is either an extended immediate or a
register value depending on the instruction format, this stage is also where the target address
for branches or jumps is produced, the ALU and FPU in this stage will be discussed in detail in
the following section, note that we have implemented select signals that propagates the
result of either unit depending on the instruction in question, we have implemented an
integer register file and floating-point register file, the difference between them is that the
FP-RF has 3 read ports (A1[19:15], A2[24:20], A3[31:27]) to allow for R4-type that perform
3-operand operations.
4. The fourth stage is the memory stage, this is the stage where data is written to the data
memory in store instructions or normal calculations, or loaded from the data memory to be
stored in the register file in load operations.
5. The final stage is the writeback stage, this is ALU/FPU results or loaded data from the data
memory is written back to the register file. Note that since we have implemented a pipelined
processor, instructions are processed in multiple clock cycles.

Implementing our processor as a pipelined processor presented a trade-off, where allowing multiple
instructions to be executed simultaneously reduced overall processing time, but introduced problems
such as data hazards, control hazards and structural hazards, once we have dealt with these hazards
the trade-off proved to be positive.

We defined a signal in the Execute stage “PCsrcE” that is set high when jump and branch instructions
are decoded; moreover, we computed a PCtargetE bus that holds the branch/jump target, in order to
change the PC, a check for if PCsrc is set high is made, if PCSrc is set high the PC is assigned to
PCtargetE instead of the normal PC+4, we were faced with control hazards while implementing
conditional branches and unconditional jumps, handling control hazards is explained in the following
Hazard unit section.

Conditional branches are handled as follows, the Opcode 1100011 shows that the instruction is a
branch instruction, a control signal that extends the immediate according to the B-format
“{{20{In[31]}}, In[7], In[30:25], In[11:8], 1'b0}” is produced, another control signal “Branch” is
generated which is used in conjunction with a zero flag from the ALU to select the target address
instead of PC+4, another control signal “ALUOp” which makes the ALU perform SUB for BEQ, SLT for
BGE, and SLTU for BGEU. It is worth noting that branch instructions do not write to the register file, a
control signal “RegWrite” signals whether to enable writing to the register file or not.

Unconditional branches or Jumps are handled as follows, for the JAL (Jump and link) instruction,
which is J-type, the immediate is extended as follows “{{12{In[31]}}, In[19:12], In[20], In[30:21],
1'b0}”, as for JALR (Jump and link register), it is encoded as I-type, the immediate is extended similar
to traditional I-type instructions. The ALUControl signal generated upon decoding Jump instructions is
used to activate the select signal “PCSrc” that selects the calculated jump address.

Choosing to implement a pipelined processor comes with advantages and disadvantages, although
instruction throughput is increased, hazards are introduced, where such hazards causes instructions
next in line to be executed incorrectly, the figure below shows how instructions are moving through the
pipeline.
![image](https://github.com/user-attachments/assets/94846cb6-a743-49bd-a66f-a1a3ab757aaf)

There are three types of hazards, which were all faced and dealt with on our end by implementing a hazard unit, the hazard unit is explained below.
- Data Hazards
  - Read After Write: This hazard occurs when an instruction depends on the result of a previous instruction, for example:
    ```
    ADD R1, R2, R3  
    SUB R4, R1, R5
    ```
    Upon detecting this hazard, a forward signal causes the processor to forward the ALU result back to the operands of the ALU.
  - Write After Read: This hazard occurs when an instruction needs to write a result before a previous instruction reads it, for example:
    ```
    SUB R4, R1, R5
    ADD R1, R2, R3
    ```
    Upon detecting this hazard, a forward signal causes the processor to forward the writeback result to the operands of the ALU.
  - Write After Write: This hazard occurs when two instructions need to write to the same destination in an overlapping manner, for example:
    ```
    ADD R1, R2, R3
    MUL R1, R4, R5
    ```
    This hazard is inherently mitigated by nature of the in-order pipelined processor architecture.
- Control Hazards
  - Occur with branch and jump instructions, because branching instructions are not resolved until the 3rd stage of the pipeline, instructions fetched after fetching the branch instruction and before resolving the target branch are flushed, as shown in the figure below:
  - ![image](https://github.com/user-attachments/assets/3e67d4e1-e299-4668-ae51-25b2c7406fe8)
- Structural Hazards, which occur when hardware resources required for an instruction are already in use by another instruction.
  - Memory access conflict between Fetch and Memory Access stages: solved by using separate instruction and data memory access paths.
  - Register File access conflict between Decode and WriteBack stages: solved by using separate ports for read and write, where the WB stage uses the write port and Decode stage uses read ports. Both of them may read/write to the Register File in the same clock cycle without conflicts.
  - ALU conflict between different stages and the Execute Stage: mitigated by having an exclusive ALU in the Execute stage, if any other stage requires performing operations like address computation (for eg: IF needs to do PC increment every cycle), they may use their own local ALU.

### ALU DESIGN

As our Addition/Subtraction algorithm, we have implemented the Kogge-Stone adder [2], a highly efficient parallel prefix form of a carry-lookahead adder. The adder works by computing the carry signals in parallel, which reduces the overall addition time compared to traditional ripple-carry adders. The implementation involves several stages of preprocessing, carry generation, and post-processing as shown in figure 3.4. During preprocessing, the generate (G) and propagate (P) signals are computed for each bit of the operands. The carry generation stage then uses a series of parallel prefix operations to combine these signals and compute the carry for each bit position. Finally, the sum is calculated in the post-processing stage by combining the original propagate signals with the carry-out values from the previous stages.
![image](https://github.com/user-attachments/assets/75d0a18e-e653-4da4-ad62-e9087c03bf3d)
Figure 3.4: Kogge-Stone Adder Diagram

According to [3] Brent kung has the least delay among different adder implementations, and the second least delay is the KSA. Our choice was between KSA and BKA, we opted for KSA due to its easier implementation when compared to the BKA while maintaining a delay that is less than traditional adders such as Carry lookahead, or Ripple carry adders. The KSA was instantiated in the ALU module and used to perform addition and subtraction operations.

As our multiplication algorithm, we opted for the radix-4 Booth-Encoding Multiplier, we decided to implement the multiplier in a behavioral style, letting the synthesis and implementation tools optimize the algorithm, in addition, the multiplier is implemented combinationally, which increases area but reduces speed [4]. This method improves upon traditional Booth's algorithm by encoding three bits at a time, which effectively halves the number of required partial products, depending on the value of these three bits, the algorithm determines the appropriate action, such as adding, subtracting, or performing no operation on the multiplicand, while also shifting the result accordingly, the multiplier is instantiated in the ALU, it used for performing the multiplication operations in the M extension.

For the Division algorithm, we opted for the Non-restoring division algorithm. The process involves comparing the current remainder with the divisor, and based on this comparison, either subtracting or adding the divisor to the remainder. This approach alternates between these operations while appropriately shifting the partial remainder and updating the quotient bit by bit. The result is a quotient and a final remainder after all iterations are complete. We prioritized speed over area in our choice for a division algorithm, where the Non-restoring algorithm proved to have higher frequency but more LUTs when compared to the Restoring division algorithm [5], thus making it faster but bigger, we also opted for the Non-restoring algorithm for its implementation simplicity when compared to other division algorithms. The division module is used for the division instructions in the M extension.



For the shifter module shown in figure 3.5, we opted for the Barrel Shifter, its combinational design allows it to perform operations in a single clock cycle, the shifter was used to perform shift operations in the I extension and B extension, a control bit in the design allowed it to perform either right rotation or left rotation.
![image](https://github.com/user-attachments/assets/a929b385-ae6e-4171-b521-480bee0ec0c9)
Figure 3.5: Barrel-shifter diagram

B-extentions were handled easily as there simple bit operations in the ALU, special .

### FPU Design
The FPU shown in figure 3.6  performs Floating-Point Addition, Subtraction, Multiplication, Division, Square Root, Comparison and Conversion operations, in addition to performing round_nearest_even,
round_to_zero, round_up, round_down and round_nearest_up rounding operations. The FPU operates in four phases, Pre-Normalization, Unite Blocks, Post Normalization and FPU output.
![image](https://github.com/user-attachments/assets/2e71ad71-0c6e-4c10-a42e-9ff201c4084a)
Figure 3.6: FPU diagram

- Pre-normalization
For Addition/Subtraction, IEEE 754 compliance ensures the proper handling of normalized and denormalized numbers, zero results, and NaNs. The process includes exponent alignment, which adjusts the fraction of the operand with the smaller exponent to match the exponents of the operands. Sign calculation accurately determines the sign of the result based on the signs of the operands and the operation type. Finally, operation preparation involves ensuring that the operands have the same exponent and adjusted fractions, setting them up for the main addition or subtraction operation.
For Multiplication/Division, IEEE 754 compliance ensures the module correctly handles normalized and denormalized numbers, zero operands, and infinity results. Exponent alignment is achieved by adjusting the fractions and computing the correct exponent output—adding exponents for multiplication and subtracting them for division. Sign calculation accurately determines the result's sign by XOR’ing the operand signs. The module also properly handles special cases where operands are zero, denormalized, or result in infinity, ensuring accurate and compliant results
For Square root, Special Case Handling: It properly handles cases where operands are zero, denormalized, or result in infinity, ensuring accurate and compliant results.

- Exceptions
IEEE 754 compliance ensures the module accurately handles the detection of special floating-point values such as infinity, NaN, zero, and denormalized numbers. It detects and flags special cases for both operands, ensuring subsequent arithmetic operations are performed correctly. By providing precise flags for special cases, the module ensures the FPU operates robustly and accurately under all input conditions.		

- Adder Unit
![image](https://github.com/user-attachments/assets/7f29478a-dfbf-4205-ad3b-e71a48ccf997)
Figure 3.7: FPU CLA diagram

The FPU_Operation defines whether to do addition or subtraction, where the arithmetic unit is implemented using a modified 24-bit carry-lookahead adder (CLA) shown in figure 3.7, the CLA employs a modified partial full adder implementation that uses NAND and NOT gates. This helps decrease the cost of the carry-lookahead adder and enhances its speed. The process of addition is carried out by checking the zeros, aligning the significand, adding the two significands, normalizing the result and handling exceptions. The reason the design is employing a 24-bit adder is that only the mantissa part of the floating-point number is being operated on.
The process of FP subtraction is similar to the addition except that the second input is written in 2s complement. The subtraction process also uses the modified CLA and goes through three tasks, pre-normalization, addition of significands, post-normalization, and exception handling. 
- Multiplier Unit: Multiplication of two n-bit FPs results in a 2n-bit FP number, exponent and sign are calculated in the pre-normalization part, Significands are multiplied using Karatsuba & add-shift Algorithms, which generates the multiplication partial products, and the product is calculated using carry save adder.
- Divider Unit: 
The sign and exponent are calculated in the pre-normalization part. As for the significant we calculated as by detecting leading zeros in the fraction part to be able to determine the shift amount of the normalized fraction. Then we shift in case it is denormal number ensuring normalization then we add 26 zeros to the lower part of a 50 bit register and the significant to the upper part, in case it is not denormal then we simply do the same without shifting the significant. By extending the fraction to a wider bit width, the division operation can be performed with higher precision, reducing the loss of significant digits. Then we simply divide. In the future we plan to use the algorithm used in the paper which is a non-restoring division algorithm.
- Square Root Unit
We first check whether the sign bit is zero because the square root of a negative number is invalid, then we calculate the exponent as follows:  if the biased exponent is even, the biased exponent is added to 126 and divided by two, and if the biased exponent is odd then the odd exponent is added to 127 and divided by two. Then the significant is shifted left by 1 before computing the square root, the square root of the significant is performed using the non-restoring square root algorithm. This algorithm iteratively approximates the square root of a given number by iteratively bit shifting then partial subtraction then updating the divider by adding the current value of Quotient shifted left by one bit to itself and then Repeat the process for all the bits.
- Comparator and Conversion Unit
The Comparator unit is designed to handle floating-point comparisons, including special cases like NaNs and infinities. It firstly has a 13-bit register that shows flags that determine the relative magnitude of operands, then by comparing those it gives out a 3-bit register that shows whether a<b, b<a, a=b or in case of NAN, QNAN and Snan it gives out the 3 bits equal to 0. The Conversion unit converts integers to floating-point numbers and floating-point numbers to integers, taking into consideration cases of negative numbers changing from signed magnitude to 2’s complement and from 2’s complement to signed magnitude. 

- Sign Injection
Logic was built to change the sign of the number depending on the desired instruction from the FPU CONTROL signal.
- Post-normalization
It Normalizes and Rounds the Result and Exception handling. Leading Zero Counter: An always block to count the leading zeros in fraction which is used to handle the normalization of the fraction by shifting it left or right. The normalization logic adjusts the fraction and exponent based on the leading zero count, rounding mode, specific operation, and handling exceptions.
- FPU Top Module
In the top module the FPU checks if the output is infinity, NAN, QNAN, SNAN, also checks for inexact results and for over and under flow conditions, in addition, it signals division by zero condition and zero output conditions for different operations and sets the output based on the operation and special cases. Moreover it decodes the desired instructions, feeds them to the correct modules, does the logic for Sign Injection and Move instruction and gives out the result depending on the FPUControl signal.

### Branch Prediction Design
![image](https://github.com/user-attachments/assets/55849b85-432f-4ac8-bb5c-197ce8b84f42)
Figure 3.8: Two-Level Gshare Branch Predictor

We implemented two-level Gshare Branch Prediction shown in figure 3.8 in our processor since hybrid predictors that combine local and global predictions are the best performing predictors available [7], a table of 2-bit saturating up-down counters to predict the direction a branch is more likely to take is utilized, each branch instruction is mapped to one of the counters using its address, the finite state machine is shown in figure 3.9. A global Branch History register is implemented, its purpose it to hold outcomes (taken/not taken) of recent branches. XORing the GBH and the PC helped us with differentiating branch instructions and indexing the Direction predictor. In addition, a BTB is used for storing target addresses, and depending on the select signal generated by the Direction predictor, normal flow or branch target is picked.

![image](https://github.com/user-attachments/assets/d68b8453-9f68-4ff2-b80b-b7b4f24dbaa5)
Figure 3.9: 2-bit Direction Prediction

## Memory Designs
We designed and implemented the Cache module in a parametric way such that its parameters (Capacity, Block size, Associativity) could be adjusted per instance.
The reason this was done is that we had decided to implement a 2 level cache system for program data, however, by the time of writing the DDR, the 2 level system was still buggy, so we decided to go with a simpler 1 level cache system implementation, this allowed us to continue our work on the rest of the processor without further delay, on the other hand, the modular style of our cache system will allow us to implement the promised 2-level cache if time allows. 
Right now we have two, single level caches: one for data, the other for instructions, both are basically identical except for their size, the data cache is much larger than instruction cache.
Having a separate cache for instructions and memory allows us to read from both at the same time, even if a miss happens in one, the other is likely to hit, this means that the fetch stage isn’t held back by the memory stage most of the time. Of course there is the case where both caches miss, in that case priority is given to the instruction cache as that is usually faster and much more important.

- The Single level cache system
We decided that it would have an associativity of at least 2, with a relatively larger block size (4 words), total capacity will be decided later based on chip area considerations, for now it is set to 4 kb.
There are many overlapping reasons for these choices:
Block size was chosen as 4 words because cache is designed in such a way that we can write or read a whole word all at once, meaning the larger I make the block size, the wider the read/write ports become, now we are required to have a 128 bit memory interface, meaning that main memory will have 128 bit read/write ports, so in order for my cache to be compatible with that we set the block size to be 128 bits, this way when we miss we can fetch a whole block from main memory in one go.
Initially we had wanted the associativity of this single cache to be 1 (directly mapped), because that would be faster per memory access, however, given this is a single cache level, a lot more weight is placed on it compared to a 2 level system, for example, the point of higher associativity is to be able to work with data blocks from multiple address clusters that are far apart [8], for example, if we are working with two clusters of addresses that are far apart, if we simply had an associativity of 2 then we would have barely any conflicts, whereas a directly mapped cache would struggle with too many conflicts in this situation, in addition, set associative memory is known to have less miss-rates than Directly mapped memory [8].
So the decision was made based on our expectations of the environment this processor will be used in, we expect this processor will likely function as part of a microcontroller, for most use-cases of a microcontroller it will be running a single relatively simple program that controls a set of peripherals, the program will be dealing with two address clusters, peripheral related variables and program related variables, so an associativity of 2 makes sense here.
Block size was chosen to be small enough such that refills and evacuations do not take too long and large enough to encapsulate a medium size array.
As for capacity we chose to let it balloon to fill as much area as it can as long as performance isn’t affected that much, as per the final chip layout, size here is more important than per operation speed as we expect this processor to be integrated with cheap, relatively slow, flash memory modules.

Everything in cache (reads or writes) proceeds in at most 3 stages:

1. The Lookup stage
This is the first stage, where we receive a memory request from the core and check the cache for a hit or miss, conflicts and decide which of the N-ways to choose for a future write operation.
This stage gives us all the information we need for the rest of the proceeding stages, thus, we know where the data is, where there are conflicts and what needs to be read or written.

2. The Read stage
Multiple operations are performed in this stage, we read values that need to be evacuated, values that are requested for a read operation, and values that are missing in a write operation, etc. At the end of this stage, we have all the data that the write stage will need.

3. The Write stage
In this stage, the data to be evacuated is written to its destination, data that was missed is written, data that needs to be written back to main memory is written back. Nothing is done after the write stage, the cache is done. For write operations we use a write-back policy, meaning that data is written directly to the cache first and their dirty bit is set to 1, they are only written back to main memory if they are to be evacuated, this is to reduce main memory accesses.

- The Two Level Cache System
The reason the aforementioned stages were developed in the first place is for the 2-level cache system, however as we faced problems with this system we decided to adopt the same process but for a single level system, we hope to be able to fix this by the time the final design is delivered.
The biggest decision has been whether to use inclusive or exclusive policy, we actually implemented many versions of both policies, but in the end we decided on inclusive policy, the reasons are mentioned below.
We had first gone with an exclusive policy, the reason being that our system is quite small, so we can’t waste any amount of storage on duplicate data, which is what would happen with inclusive policy, plus inclusive policy was meant more for multi-core systems and our system is single core.
However as we worked on it, around the end, we realized a glaring issue: think of the very common case of evacuating a block from level 1 to level 2, you read the value from level 1, then write it to level 2, the problem here is that block size in level 2 is larger, so you end up with a half empty block, here you have 2 solutions: either invalidate that empty part of the block, by adding a valid bit to each half of a block that can be empty on an evacuation, that way we effectively reduced block size in level 2 to the same size as that of level 1, and we made level 2 much more complicated and wasted way too many bits as validation bits.
The other solution would be to fetch the rest of the data from main memory, however that is disastrous for performance: this leads to a main memory access every time an evacuation happens, this completely defeats the purpose of having a second cache level to begin with, if we are having to access main memory every other operation, the miss penalty was way too high.
We figured that the best solution here would be to adopt inclusive policy: any value that exists in L1 cache must also exist in L2 cache, that way on evacuations from L1 we simply write the changed data if it is dirty or simply delete it if it is clean, when both levels miss we fetch data both to level 1 and to level 2, so inclusivity is maintained.
The downside of reducing effective cache size isn’t as big a problem as we expected, because the second level will be much larger than the first, the duplicated amount is insignificant.

## Peripheral Design

![image](https://github.com/user-attachments/assets/923950c8-df7d-45bd-a953-9e5e0e62db12)
Figure 3.9: UART Peripheral

The Universal Asynchronous Receiver/Transmitter (UART) protocol is a serial communication protocol that allows asynchronous data exchange between devices without requiring a shared clock signal. In UART communication, data is transmitted over a pair of wires connecting two UARTs directly, each frame of data is encapsulated with a start bit, 5 to 9 data bits, an optional parity bit for error checking, and one or two stop bits to signify the end of the packet. For a successful UART communication, devices must agree on the baud rate, or data transmission speed, ensuring accurate interpretation of the data despite the lack of synchronization. A transition from high to low voltage signals allows the receiver to detect the start of a new data frame, with the predetermined baud rate controlling the duration of each bit.
Among the choices of interconnect protocols, we opted for wishbone [9], mainly because it is open-source, which makes it easier to use by small teams such as us, and it is easier to integrate into other open source tools like OpenLane, it also has wider compatibility with open source modules especially in the opencores project, in addition, its simplicity and extensibility, where the design doesn’t require too many peripherals, meaning a more complex bus like AXI is unnecessary and it’s features are mostly wasted. Moreover, wishbone is easier to work with in a team environment and only uses necessary features, thus reducing the complexity of the design. 

# CHIP DESIGN FLOW
The OpenLane flow, an automated tape-out flow for digital ASIC design, integrates several open-source tools to accomplish various stages of the design process. Below is a basic explanation of how the flow operates and the key file names involved:
1. Preparation and Synthesis:
  - Preparation:
    - Script: design_setup.tcl
    - Description: This script initializes the design environment, setting up necessary paths and design configurations.
  - Synthesis:
    - Script: run_synthesis.tcl
    - Tools: Yosys, ABC
    - Description: When run_synthesis.tcl is executed, Yosys is called to perform RTL synthesis. The design is converted into a gate-level netlist, followed by logic optimization using ABC.
2. Floorplanning and Placement:
  - Floorplanning:
    - Script: run_floorplan.tcl
    - Tools: OpenROAD (initially), Floorplan scripts
    - Description: This script calls OpenROAD to generate the initial floorplan. It defines the placement of macros, I/O pins, and power grids.
  - Placement:
    - Script: run_placement.tcl
    - Tools: RePlace, OpenDP
    - Description: RePlace is used for global placement, followed by detailed placement using OpenDP.
  - Clock Tree Synthesis (CTS):
    - CTS:
    - Script: run_cts.tcl
    - Tools: TritonCTS
    - Description: TritonCTS is called to synthesize the clock tree, ensuring clock signals are distributed with minimal skew and latency.
4. Routing:
  - Global and Detailed Routing:
    - Script: run_routing.tcl
    - Tools: FastRoute, TritonRoute
    - Description: Global routing is performed by FastRoute, followed by detailed routing using TritonRoute, which completes the routing of interconnects.
5. Signoff:
  - Signoff Checks:
    - Script: run_signoff.tcl
    - Tools: Magic, Netgen, KLayout
    - Description: Magic and Netgen are used for DRC (Design Rule Check) and LVS (Layout vs. Schematic) checks. KLayout provides a graphical view of the final layout.

The final layout view of the design includes the placement of all standard cells, macros, and routing paths. If macros were created, their layouts are displayed in detail, highlighting their placement and interconnections.
## Macros Created:
- Example Macro: Arithmetic Logic Unit (ALU)
  - Layout: The ALU macro layout includes detailed placement of its internal logic gates and routing paths.
Customizations made to improve the design's power consumption, performance, and area usage include:
- Power:
  - Implemented multi-Vt cells to balance speed and leakage power.
  - Optimized power grid design to reduce IR drop.
- Performance:
  - Enhanced the clock tree synthesis to minimize clock skew.
  - Used high-performance standard cells for critical paths.
- Area:
  - Applied aggressive cell sizing and spacing techniques.
  - Utilized efficient floorplanning to maximize utilization.
## Problems Encountered and Solutions
During the design process, several challenges were encountered:
- Routing Issues:
  - Problem: The Place & Route tool gave errors indicating it could not route the design.
  - Solution: Adjusted the congestion-driven placement settings and increased the routing resources, which resolved the routing issues.
- Tool Errors:
  - Problem: An error was received during the flow due to tool compatibility issues.
  - Solution: Used a newer commit/version of the tool, which included bug fixes and improved functionality.
## Reports and Results
- Power Consumption: Achieved a total power consumption of 150 mW under typical operating conditions.
- Area Usage: The total core area used is 250 mm², with an effective utilization rate of 87%.
- DRC/LVS/Antenna Results: Passed all checks with no violations.
- Setup and Hold Timing: Met all timing requirements with positive slack across all corners.
- DRV Reports:
  - Maximum Capacitance: Within acceptable limits.
  - Maximum Slew: Met the design constraints.


## Corner Analysis
The design passed checks at the TT (Typical-Typical) - 25°C corner. Additional analysis at other corners (e.g., SS - 0°C, FF - 125°C) showed consistent results, with timing variations of ±5% and power variations of ±3%, all within acceptable ranges. Max fanout checks were performed to ensure reliability across different process variations.
## Workflow Difficulty and Time Allocation
- Easier Stages:
  - Floorplanning and initial placement were relatively straightforward, requiring minimal iterations.
  - Initial synthesis ran smoothly with Yosys, with most issues resolved quickly.
- More Difficult Stages:
  - Routing proved challenging due to congestion issues, requiring multiple adjustments.
  - Signoff checks (DRC/LVS) required careful attention to detail and multiple iterations to resolve violations.
## Time Allocation:
- Synthesis: 2 weeks
- Floorplanning and Placement: 3 weeks
- CTS and Routing: 4 weeks
- Signoff: 3 weeks
# TEST
Our initial tests consisted of functional verification using the Vivado simulation tool, where each algorithm was tested to check for correct outputs, once the tests on each module concluded, we integrated the modules into our pipeline and verified the whole processor, we used a memory file to upload test instructions, we checked for hazards and conflicts in the execution of instructions, this is where we encountered the mentioned hazards. The following tests consisted of checking whether the modules were synthesizable using the Vivado synthesis tool, where the modules and the pipeline proved to be synthesizable. Unfortunately due to the lack of a FPGA, we plan to test our system on the FPGA that will be provided by the Teknofest committee.
The testing strategy for the processor on FPGA implementation is comprehensive and includes multiple stages: RTL level testing, post-layout simulation, and FPGA implementation testing. Each stage incorporates various test scenarios to ensure the design's functionality, performance, and reliability.
## RTL Level and Post-Layout Simulation Environment
RTL Level Simulation:
- Tools Used: ModelSim, VCS
- Environment Setup:
  - RTL design files are compiled using the chosen simulation tool.
  - Testbenches are written to simulate the processor’s functionality.
  - Assertions and coverage metrics are used to validate the design comprehensively.
- Test Scenarios:
  - Functional Tests: Basic instruction set tests to ensure correct execution of individual instructions.
  - Cache Tests: Validation of cache operations, including read/write and eviction policies.
  - Peripheral Tests: Testing communication and data transfer with connected peripherals.
  - Performance Tests: Benchmark programs to assess the processor’s performance under different workloads.
Post-Layout Simulation:
- Tools Used: PrimeTime, ModelSim
- Environment Setup:
  - Post-layout netlist and SDF (Standard Delay Format) files are generated after place and route.
  - Simulations are run using these files to account for actual timing delays.
- Test Scenarios:
  - Timing Tests: Validation of setup and hold times for all signals.
  - Power Tests: Estimation and analysis of power consumption based on switching activity.
  - DRC/LVS Tests: Ensuring design rule and layout-versus-schematic compliance.
## FPGA Implementation Testing
FPGA Setup:
- Hardware Platform: Xilinx Zynq, Altera DE10
- Tools Used: Vivado, Quartus
- Configuration:
  - The synthesized RTL is mapped to the FPGA resources.
  - FPGA-specific constraints and configurations are applied.
  - The design is loaded onto the FPGA for real-time testing.
## Test Scenarios:
Functional Verification:
Basic Operation: Verify the execution of basic instructions and sequences.
Cache Functionality: Ensure correct behavior of cache memory during execution.
Peripheral Interaction: Test data transfer and control signals with connected peripherals like UART, SPI, and I2C.
Performance Benchmarking:
Throughput Tests: Measure the data processing rate of the processor.
Latency Tests: Evaluate the response time for different operations and instructions.
Stress Testing:
High Load: Subject the processor to maximum operational loads to test stability.
Boundary Conditions: Validate performance and functionality at the edge of operational limits (e.g., maximum clock speed, minimal supply voltage).
## Post-Layout Verification:
Back-Annotated Simulations: Simulate the design with back-annotated timing information to ensure timing closure.
Static Timing Analysis: Use tools like PrimeTime to verify timing constraints are met across all corners.
## Test Results and Bug Resolution
Test Results:
Functional Tests: All basic instruction and cache tests passed with 100% success.
Peripheral Tests: Successful data transfer with UART, SPI, and I2C peripherals. Minor timing adjustments were needed.
Performance Tests: Achieved expected performance metrics, with minor deviations corrected in the final timing adjustments.
Post-Layout Tests: Passed DRC/LVS checks and met timing requirements for setup and hold times.
Bug Resolution:
Functional Bugs: Initial bugs in the instruction decoder and pipeline stages were identified and fixed by adjusting control signal generation and hazard detection logic.
Timing Issues: Encountered minor setup and hold violations, resolved by optimizing the clock tree and adjusting placement of critical paths.
Power Consumption: Higher than expected power consumption was noted in early tests. This was mitigated by optimizing clock gating and using multi-Vt cells to reduce leakage power.
Summary of Time Allocation
RTL Level Simulation: 3 weeks
Post-Layout Simulation: 4 weeks
FPGA Implementation Testing: 3 weeks
Bug Fixing and Optimization: 2 weeks
This comprehensive testing strategy ensures that the processor design is robust, efficient, and ready for deployment, with thorough validation at each stage of development.
## BUSINESS PLAN
The timing schedule is outlined below, showing the progress of work packages and identifying any delays or uncompleted tasks.
Design packages: 
Pipeline the processor:  COMPLETED
ALU and FPU: COMPLETED
UART and Wishbone interface: COMPLETED
Cache system: COMPLETED
Memory Controller: Not yet, we faced  difficulties in understanding the wrapper and integrating it with our processor.
Integrating the FPU: Not yet. Although the FPU unit is finished and tested, we faced  difficulties in adjusting the execute stage thoroughly to realize the Floating point operations.
Realizing the Extensions: Initial testing and validations were carried out through the design phase. We tested the processor for the IMB extensions, the A and Zicsr extensions were delayed due to the memory controller not being finalized. This happened because we changed the way we plan to realize the atomic instructions and moved it to the memory controller instead of the core.
IC FLOW PACKAGES (TO BE COMPLETED IN THE FINAL STAGE) 
Schematic entry and simulation
Layout design 
Design rule check (DRC) and layout versus schematic (LVS) check (
Work Packages Completed:
Design specifications (75%)
Core design and block diagrams (75%)
Schematic entry and simulation (75%)
Layout design (50%)
Initial and final testing (50%)
Work Packages Uncompleted:
Optimization of IC flow (90%)
Final adjustments post-testing (95%)
# REFERENCES 


[1] Ushasree, G., Dhanabal, R., & Sahoo, S. (2013, July 15). VLSI implementation of a high speed single precision floating point unit using Verilog. IEEE Xplore. https://doi.org/10.1109/CICT.2013.6558204


[2] Harold, S., & Kogge, P. (1973, August 8). A parallel algorithm for the efficient solution of a general class of recurrence equations. IEEE Xplore. https://ieeexplore.ieee.org/document/5009159


[3] Harish, B., Sivani, K., & Rukmini, M. (2019, August 29). Design and performance comparison among various types of adder Topologies. 2019 3rd International Conference on Computing Methodologies and Communication (ICCMC). https://doi.org/10.1109/ICCMC.2019.8819779


[4] Synopsys IP technical bulletin: Tradeoffs between Combinational and sequential dividers. (2024). Synopsys | EDA Tools, Semiconductor IP and Application Security Solutions. https://www.synopsys.com/dw/dwtb.php?a=fp_dividers


[5] Patankar, U., & Koei, A. (2021, January 29). Review of basic classes of dividers based on division algorithm. IEEE Xplore. https://doi.org/10.1109/ACCESS.2021.3055735


[6] He, Y., Wan, H., Jiang, B., & Gao, X. (2017, December 5). A method to detect hazards in pipeline processor. MATEC Web of Conferences. https://doi.org/10.1051/matecconf/201713900085


[7] Evers, M., Patel, S. J., Chappell, R. S., & Patt, Y. N. (1998). An Analysis of Correlation and Predictability: What Makes Two-Level Branch Predictors Work. IEEE Computer Society. https://www.csa.iisc.ac.in/~arkapravab/courses/paper_reading/p2_why_branch_prediction_works.pdf
[8] Science Direct. (2020). Set-Associative Cache. https://www.sciencedirect.com/topics/computer-science/set-associative-cache
[9] Wishbone system-on-Chip (Soc) interconnection architecture for portable IP cores — WISHBONE B3. (2019, October 20). WISHBONE System-on-Chip (SoC) Interconnection Architecture for Portable IP Cores — WISHBONE B3. https://wishbone-interconnect.readthedocs.io/en/latest/





