`include "exceptions_codes.vh"
module hazard_unit(

        input rst, register_write_m, register_write_w, pc_src_e,
        
        input [4:0] RD_M, rd_w, Rs1_E, Rs2_E,
        output [1:0] ForwardAE, ForwardBE,
        output flush_F,flush_D, flush_E, flush_M, is_exception_o,
        
        input exp_ld_mis_i, exp_st_mis_i,  exp_instr_addr_mis_i,
        //input exp_instr_acc_fault_i, exp_st_acc_fault_i, exp_ld_acc_fault_i,
        input [1:0] exp_access_faults_i,
        
        input exp_ill_instr_i,
        
        output [3:0] mcause_code_o
        
    );
    
    wire exp_instr_acc_fault, exp_st_acc_fault, exp_ld_acc_fault;
    assign exp_instr_acc_fault = ~rst ? 1'b0 :~exp_access_faults_i[1] & exp_access_faults_i[0];
    assign exp_st_acc_fault = ~rst ? 1'b0 :&exp_access_faults_i;
    assign exp_ld_acc_fault = ~rst ? 1'b0 :exp_access_faults_i[1] & ~exp_access_faults_i[0];
    
    
    
    assign ForwardAE = ~rst ? 2'b00 :
                       (register_write_m & (RD_M != 5'h00) & (RD_M == Rs1_E)) ? 2'b10 :
                       (register_write_w & (rd_w != 5'h00) & (rd_w == Rs1_E)) ? 2'b01 :
                        2'b00;
                       
    assign ForwardBE = ~rst ? 2'b00 :
                       (register_write_m & (RD_M != 5'h00) & (RD_M == Rs2_E)) ? 2'b10 :
                       (register_write_w & (rd_w != 5'h00) & (rd_w == Rs2_E)) ? 2'b01 : 
                       2'b00;
//    assign flush_F = pc_src_e | 
//    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
//    exp_instr_acc_fault_i | exp_st_acc_fault_i | exp_ld_acc_fault_i;
//    assign flush_D = pc_src_e | 
//    exp_instr_addr_mis_i  | exp_st_acc_fault_i | exp_ld_acc_fault_i |
//    exp_ld_mis_i | exp_st_mis_i ; 
//    assign flush_E = exp_st_acc_fault_i | exp_ld_acc_fault_i; 
//    assign flush_M = 1'b0;  
        
        
        
        
   
   assign flush_F = pc_src_e | 
    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
    exp_instr_acc_fault | exp_st_acc_fault | exp_ld_acc_fault;
    assign flush_D = pc_src_e | 
    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
    exp_st_acc_fault | exp_ld_acc_fault;
    assign flush_E = exp_instr_addr_mis_i  | exp_st_acc_fault | exp_ld_acc_fault |
                     exp_ld_mis_i | exp_st_mis_i ; 
    assign flush_M = exp_st_acc_fault | exp_ld_acc_fault; 
   
   assign mcause_code_o = exp_ill_instr_i ? `illegal_instr :
                          exp_instr_addr_mis_i ? `instr_addr_misalign :
                          exp_ld_mis_i ? `load_addr_misalign :
                          exp_st_mis_i ? `store_amo_addr_misalign :
                          exp_instr_acc_fault ? `instr_access_fault:
                          exp_st_acc_fault ? `store_amo_access_fault:
                          exp_ld_acc_fault ? `load_access_fault:
                          4'bx;

    assign is_exception_o = ~rst ? 1'b0 : 
    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
    exp_instr_acc_fault | exp_st_acc_fault | exp_ld_acc_fault;


endmodule