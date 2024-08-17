# To-do
- [x] make the core start at address 0x80000000
- [x] the cache controller is never done, why?
- [x] why aren't we getting read data?
- [x] read data is switching to 0 before it is read, why?
    - problem is in conflict resolver
---- it finally works!!!!
- [x] first instruction read correctly, second one read semi-correctly, why?
---- fetch cycle works correctly
- [x] cach never hits, even though it has the data, why?
    - never asserting set valid
- [x] read_needed_cache is behaving wrong and we are never entering cache read mode, instead we go writing instead!
    - we never get a read_op
---- cache functional
- [x] cache problem: done getting raised afterwards
    - problem I think is that the delayed operations that raise it are getting called multiple times
- [ ] cache written wrong value
    - I think when it doesn't hit it is following an older logic and writing from read data from main, but this is a write not a read, in this case we should write data combined between what we read and what we are writing

# Atomic
## Atomic instructions are different than normal memory operations
the main difference is that they are a read and write operation at the same time.
usually you either use the read input or the write output but not both, in this case we use both, we write data AND read data back.
in a swap operation for example we read from an address then write a value to that same address

## How the core should handle this
- it should fetch the address from src1 and the value from src2
- in the memory stage it should set address to rs1 and set write data to rs2
- when done write mem read data to rd

general algorithm:
	core side:
		set address to rs1
		set write data to rs2
	memory side:
		read mem address into rdata output
 		process data
		write the operation result to mem address
	core side:
		set rd to rdata

swap algorithm:
	core side:
		set address to rs1
		set write data to rs2
	memory side:
		read from address into read data output
		write to address from write data input
	core side:
		set rd to read data

add algorithm:
	core side:
		set address to rs1
		set write data to rs2
	memory side:
		read mem address into rdata output
		add data from wdata input to rdata
		write the operation result to mem address
	core side:
		set rd to rdata