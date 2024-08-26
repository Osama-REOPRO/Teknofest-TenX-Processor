`include "exceptions_codes.vh"

module exception_handler(
    input [31:0] address_i,
    input [2:0] wordsize_i,
    input is_load_i, is_store_amo_i, is_cntrl_instr_i,
    output is_error_o,
    output [3:0] mcause_code_o

);
   wire mem_half_addr_misalign, mem_word_addr_misalign, mem_misalign, div_by_four;
   wire instruction_misalign, load_misalign, store_misalign;
    
   assign mem_half_addr_misalign = wordsize_i[0] & address_i[0];
   assign not_div_by_four = (&address_i[1:0]);
   assign mem_word_addr_misalign = wordsize_i[1] & not_div_by_four; 
   
   assign mem_misalign = (mem_half_addr_misalign|mem_word_addr_misalign);
  
   assign instruction_misalign = is_cntrl_instr_i & not_div_by_four;
   assign load_misalign = is_load_i & mem_misalign;
   assign store_amo_misalign = is_store_amo_i & mem_misalign;

   
   assign is_error_o = (instruction_misalign|mem_misalign);
   assign mcause_code_o = instruction_misalign ? `instr_addr_misalign :
                          load_misalign ? `load_addr_misalign :
                          store_misalign ? `store_amo_addr_misalign :
                          4'bx;
    
endmodule
