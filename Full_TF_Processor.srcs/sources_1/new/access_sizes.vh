`define byte_access 0
`define word_access 1
`define block_access 2
`define block_lower_access 3

`define N_access 4

/*
* Note: internal and external here are sizes
* 				that is: internal block size and external block size
* 				this doesn't meant an internal access as in the access is happening internally,
* 				no, all accesses are coming from the outside, the difference is in size only, 
* 				one is sized by the lower level (external size), the other is sized by internal
* 				block size (internal)
*/