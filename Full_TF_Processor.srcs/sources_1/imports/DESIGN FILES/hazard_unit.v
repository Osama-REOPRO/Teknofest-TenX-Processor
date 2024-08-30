`include "exceptions_codes.vh"
module hazard_unit(

        input rst_i, register_write_m_i, register_write_w_i, pc_src_e_i,
        
        input [4:0] rd_m_i, rd_w_i, rs1_e_i, rs2_e_i,
        output [1:0] forward_ae_o, forward_be_o,
        output flush_f_o,flush_d_o, flush_e_o, flush_m_o, is_exception_o,
        
        input exp_ld_mis_i, exp_st_mis_i,  exp_instr_addr_mis_i,
        //input exp_instr_acc_fault_i, exp_st_acc_fault_i, exp_ld_acc_fault_i,
        input [1:0] exp_access_faults_i,
        
        input exp_ill_instr_i,
        
        output [3:0] mcause_code_o
        
    );
    
    wire exp_instr_acc_fault, exp_st_acc_fault, exp_ld_acc_fault;
    assign exp_instr_acc_fault = ~rst_i ? 1'b0 :~exp_access_faults_i[1] & exp_access_faults_i[0];
    assign exp_st_acc_fault = ~rst_i ? 1'b0 :&exp_access_faults_i;
    assign exp_ld_acc_fault = ~rst_i ? 1'b0 :exp_access_faults_i[1] & ~exp_access_faults_i[0];
    
    
    
    assign forward_ae_o = ~rst_i ? 2'b00 :
                       (register_write_m_i & (rd_m_i != 5'h00) & (rd_m_i == rs1_e_i)) ? 2'b10 :
                       (register_write_w_i & (rd_w_i != 5'h00) & (rd_w_i == rs1_e_i)) ? 2'b01 :
                        2'b00;
                       
    assign forward_be_o = ~rst_i ? 2'b00 :
                       (register_write_m_i & (rd_m_i != 5'h00) & (rd_m_i == rs2_e_i)) ? 2'b10 :
                       (register_write_w_i & (rd_w_i != 5'h00) & (rd_w_i == rs2_e_i)) ? 2'b01 : 
                       2'b00;
//    assign flush_F = pc_src_e | 
//    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
//    exp_instr_acc_fault_i | exp_st_acc_fault_i | exp_ld_acc_fault_i;
//    assign flush_D = pc_src_e | 
//    exp_instr_addr_mis_i  | exp_st_acc_fault_i | exp_ld_acc_fault_i |
//    exp_ld_mis_i | exp_st_mis_i ; 
//    assign flush_E = exp_st_acc_fault_i | exp_ld_acc_fault_i; 
//    assign flush_M = 1'b0;  
        
        
        
        
   
   assign flush_f_o = pc_src_e_i | 
    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
    exp_instr_acc_fault | exp_st_acc_fault | exp_ld_acc_fault;
    assign flush_d_o = pc_src_e_i | 
    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
    exp_st_acc_fault | exp_ld_acc_fault;
    assign flush_e_o = exp_instr_addr_mis_i  | exp_st_acc_fault | exp_ld_acc_fault |
                     exp_ld_mis_i | exp_st_mis_i ; 
    assign flush_m_o = exp_st_acc_fault | exp_ld_acc_fault; 
   
   assign mcause_code_o = exp_ill_instr_i ? `illegal_instr :
                          exp_instr_addr_mis_i ? `instr_addr_misalign :
                          exp_ld_mis_i ? `load_addr_misalign :
                          exp_st_mis_i ? `store_amo_addr_misalign :
                          exp_instr_acc_fault ? `instr_access_fault:
                          exp_st_acc_fault ? `store_amo_access_fault:
                          exp_ld_acc_fault ? `load_access_fault:
                          4'bx;

    assign is_exception_o = ~rst_i ? 1'b0 : 
    exp_ill_instr_i | exp_instr_addr_mis_i | exp_ld_mis_i | exp_st_mis_i | 
    exp_instr_acc_fault | exp_st_acc_fault | exp_ld_acc_fault;


endmodule