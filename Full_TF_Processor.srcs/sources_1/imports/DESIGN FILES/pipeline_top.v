`define PC_START_ADRS 32'h80000000
`define EXECUTE_CYCLES_COUNT 2'b11
`include "atomic_ops.vh"
module Pipeline_top(

    input clk, 
    input rst,
	// instruction mem operations -> fetch stage
	output 			mem_instr_we_o,
	output [31:0]  mem_instr_adrs_o,
	output [31:0]  mem_instr_wdata_o,
	output [1:0]   mem_instr_wsize_o,// 0 > byte, 1 > half, 2 > word
	output 			mem_instr_req_o,
	input  			mem_instr_done_i,
	input  [31:0]	mem_instr_rdata_i,
	// data mem operations -> memory cycle
	output 			mem_data_we_o,
	output [31:0]  mem_data_adrs_o,
	output [31:0]  mem_data_wdata_o,
	output [1:0]   mem_data_wsize_o, // 0 > byte, 1 > half, 2 > word
	output 			mem_data_req_o,
	input  			mem_data_done_i,
	input  [31:0]	mem_data_rdata_i,
	output [3:0]   mem_data_atomic_operation_o,
	
	input [1:0] exp_access_faults_i
);
   //useless
   assign mem_instr_we_o = 1'b0;
   assign mem_instr_wdata_o = 32'b0;
   assign mem_instr_wsize_o = 2'b10; 
    
	// translate pipeline signals into memory signals
	// and vice versa
	// could do sign extension here
//	core_memory_interface cmi(
//		.clk_i(clk), .rst_i(rst_H),
//		// core signals
//			// todo
//		// external signals
//		// instruction mem operations
//		.mem_instr_we_o(mem_instr_we_o),
//		.mem_instr_adrs_o(mem_instr_adrs_o),
//		.mem_instr_wdata_o(mem_instr_wdata_o),
//		.mem_instr_wsize_o(mem_instr_wsize_o),
//		.mem_instr_req_o(mem_instr_req_o),
//		.mem_instr_done_i(mem_instr_done_i),
//		.mem_instr_rdata_i(mem_instr_rdata_i),
//		// data mem operations
//		.mem_data_we_o(mem_data_we_o),
//		.mem_data_adrs_o(mem_data_adrs_o),
//		.mem_data_wdata_o(mem_data_wdata_o),
//		.mem_data_wsize_o(mem_data_wsize_o),
//		.mem_data_req_o(mem_data_req_o),
//		.mem_data_done_i(mem_data_done_i),
//		.mem_data_rdata_i(mem_data_rdata_i)
//	);
  
  
    // Declaration of Interim Wires
    wire flush_F,flush_D, flush_E, flush_M;

    wire pc_src_e, register_write_w, register_write_e, register_write_m, int_rd_e, int_rd_m, int_rd_w, JtypeE, F_instruction_E;
    wire BSrcE, MemWriteE, mem_read_E, BranchE, MemWriteM, mem_read_M, mem_read_w;
    wire [5:0] ALUControlE;
    wire [4:0] FPUControlE;
    wire [3:0] atomic_op_e, atomic_op_m;
    wire [4:0] RD_E, RD_M, rd_w;
    wire [31:0] pc_target_e, instruction_d, pc_d, pc_plus_4_d, result_w, RS1_E, RS2_E, 
    RS3_E, Imm_Ext_E, PCE, PCPlus4E, PCPlus4M, WriteDataM, Execute_ResultM;
    wire [31:0] PCPlus4W, Execute_ResultW, ReadDataW;
    wire [4:0] forwarded_RS1_E, forwarded_RS2_E;
    wire [1:0] ForwardBE, ForwardAE;
    wire [2:0] funct3_E, WordSize_M;
    
    wire [11:0] csr_address_e, csr_address_m,csr_address_w;
    wire [31:0] csr_value_e, csr_value_m, csr_value_w;
    
    wire is_csr_e, is_csr_m, is_csr_w;
    
    // Coordination flags
    wire execute_ready, memory_ready, fetch_ready, decode_ready;
    wire decode_valid, execute_valid;

    //Exception wires
    wire exp_ld_mis, exp_st_mis, exp_instr_addr_mis, exp_ill_instr, is_exception;
    //exp_instr_acc_fault, exp_st_acc_fault, exp_ld_acc_fault,;
    wire [3:0] mcause_code;
    


    // Module Initiation
    // Fetch Stage
    fetch_cycle fetch_stage 
   //#(.PC_START_ADRS(`PC_START_ADRS))
    (
                        .clk_i(clk), 
                        .rst_i(rst), 
                        .flush_i(flush_F),
                        //.prev_ready_i(), //No prev stage to wait for
                        .this_ready_o(fetch_ready),
                        .next_ready_i(decode_ready),
                        .mem_instr_done_i(mem_instr_done_i),
                        .mem_instr_adrs_o(mem_instr_adrs_o),
                        .mem_instr_req_o(mem_instr_req_o),
                        .mem_instr_rdata_i(mem_instr_rdata_i),
                        .pc_src_e_i(pc_src_e), 
                        .pc_target_e_i(pc_target_e), 
                        .instruction_d_o(instruction_d), 
                        .pc_d_o(pc_d), 
                        .pc_plus_4_d_o(pc_plus_4_d),
                        .is_exp_i(is_exception),
                        .pc_error_i(csr_value_e)
                        //.exp_instr_acc_fault_i(exp_access_faults_i),
                        //.exp_instr_acc_fault_o(exp_instr_acc_fault)
                );

    // Decode Stage
    decode_cycle decode_stage (
                        .clk(clk), 
                        .rst(rst), 
                        .prev_ready_i(fetch_ready),
                        .this_valid_o(decode_valid),
                        .this_ready_o(decode_ready),
                        .next_ready_i(execute_ready),
                        .flush(flush_D),
                        .instruction_d(instruction_d), 
                        .pc_d(pc_d), 
                        .pc_plus_4_d(pc_plus_4_d), 
                        .register_write_w(register_write_w), 
                        .int_rd_e(int_rd_e),
                        .rd_w(rd_w),
                        .is_csr_w_i(is_csr_w),
                        .is_csr_e_o(is_csr_e),
                        .csr_address_e_o(csr_address_e),
                        .csr_value_e_o(csr_value_e), 
                        .csr_address_w_i(csr_address_w),
                        .csr_value_w_i(csr_value_w),
                        .result_w(result_w),
                        .int_rd_w(int_rd_w),
                        .register_write_e(register_write_e), 
                        .BSrcE(BSrcE), 
                        .JtypeE(JtypeE),
                        .MemWriteE(MemWriteE), 
                        .mem_read_E(mem_read_E),
                        .BranchE(BranchE),  
                        .ALUControlE(ALUControlE), 
                        .FPUControlE(FPUControlE),
                        .RS1_E(RS1_E), 
                        .RS2_E(RS2_E),
                        .RS3_E(RS3_E),
                        .Imm_Ext_E(Imm_Ext_E), 
                        .RD_E(RD_E), 
                        .PCE(PCE), 
                        .PCPlus4E(PCPlus4E),
                        .forwarded_RS1_E(forwarded_RS1_E),
                        .forwarded_RS2_E(forwarded_RS2_E),
                        .funct3_E(funct3_E),
                        .F_instruction_E(F_instruction_E),
                        .atomic_op_e_o(atomic_op_e),
                        
                        .exp_ill_instr_o(exp_ill_instr),
                        .is_exp_i(is_exception),
                        .mcause_code_i(mcause_code)
                    );

    // Execute Stage
    execute_cycle execute_stage 
    //#(.STAGE_CYCLE_REQ(`EXECUTE_CYCLES_COUNT))
    (
                        .clk(clk), 
                        .rst(rst),
                        .flush(flush_E),
                        //.prev_ready_i(decode_ready),
                        .prev_valid_i(decode_valid),
                        .this_valid_o(execute_valid),
                        .this_ready_o(execute_ready),
                        .next_ready_i(memory_ready),
                        .register_write_e(register_write_e), 
                        .int_rd_e(int_rd_e),
                        .csr_value_e_i(csr_value_e),
                        .csr_address_e_i(csr_address_e),
                        .csr_value_m_o(csr_value_m), 
                        .csr_address_m_o(csr_address_m),
                        .BSrcE(BSrcE),
                        .MemWriteE(MemWriteE), 
                        .mem_read_E(mem_read_E), 
                        .BranchE(BranchE), 
                        .ALUControlE(ALUControlE), 
                        .FPUControlE(FPUControlE),
                        .RS1_E(RS1_E), 
                        .RS2_E(RS2_E), 
                        .RS3_E(RS3_E),
                        .Imm_Ext_E(Imm_Ext_E), 
                        .RD_E(RD_E), 
                        .PCE(PCE), 
                        .is_csr_e_i(is_csr_e),
                        .is_csr_m_o(is_csr_m),
                        .JtypeE(JtypeE),
                        .PCPlus4E(PCPlus4E), 
                        .pc_src_e(pc_src_e), 
                        .pc_target_e(pc_target_e), 
                        .register_write_m(register_write_m),
                        .int_rd_m(int_rd_m),
                        .MemWriteM(MemWriteM), 
                        .mem_read_M(mem_read_M), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M), 
                        .WriteDataM(WriteDataM), 
                        .Execute_ResultM(Execute_ResultM),
                        .result_w(result_w),
                        .ForwardA_E(ForwardAE),
                        .ForwardB_E(ForwardBE),
                        .funct3_E(funct3_E),
                        .WordSize_M(WordSize_M),
                        .F_instruction_E(F_instruction_E),
                        .atomic_op_e_i(atomic_op_e),
                        .atomic_op_m_o(atomic_op_m),
                        
                        .exp_ld_mis_o(exp_ld_mis),
                        .exp_st_mis_o(exp_st_mis),
                        .exp_instr_addr_mis_o(exp_instr_addr_mis)
                    );
    
    // Memory Stage
    memory_cycle memory_stage(
                        .clk(clk), 
                        .rst(rst),
                        .flush(flush_M),
                        .mem_data_atomic_operation_o(mem_data_atomic_operation_o),
                        .atomic_op_m_i(atomic_op_m),
                        //.prev_ready_i(execute_ready),
                        .prev_valid_i(execute_valid),
                     	 .this_ready_o(memory_ready),
                     	//.next_ready_i(),// NO next state to wait for
                        .register_write_m(register_write_m),
                        .int_rd_m(int_rd_m),
                        .MemWriteM(MemWriteM), 
                        .mem_read_M(mem_read_M), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M), 
                        .WriteDataM(WriteDataM),  
                        .is_csr_m_i(is_csr_m),
                        .is_csr_w_o(is_csr_w),
                        .Execute_ResultM(Execute_ResultM), 
                        .register_write_w(register_write_w), 
                        .int_rd_w(int_rd_w),
                        .csr_address_m_i(csr_address_m),
                        .csr_address_w_o(csr_address_w),
                        .csr_value_m_i(csr_value_m),
                        .csr_value_w_o(csr_value_w),
                        .mem_read_w(mem_read_w), 
                        .rd_w(rd_w), 
                        .PCPlus4W(PCPlus4W), 
                        .Execute_ResultW(Execute_ResultW), 
                        .ReadDataW(ReadDataW),
                     	.WordSize_M(WordSize_M),
                     	.mem_data_done_i(mem_data_done_i),
                     	.mem_data_we_o(mem_data_we_o),
                     	.mem_data_adrs_o(mem_data_adrs_o),
                     	.mem_data_wdata_o(mem_data_wdata_o),
                     	.mem_data_wsize_o(mem_data_wsize_o),
                     	.mem_data_req_o(mem_data_req_o),
                     	.mem_data_rdata_i(mem_data_rdata_i)
                     	
//                     	.exp_ld_acc_fault_o(exp_ld_acc_fault), //TODO
//                     	.exp_st_acc_fault_o(exp_st_acc_fault) //TODO
                    );

    // Write Back Stage
    writeback_cycle writeback_stage (
                        //.register_write_w(register_write_w),
                        //.int_rd_w(int_rd_w),
                        .mem_read_w_i(mem_read_w),
                        //.PCPlus4W(PCPlus4W), 
                        .execute_result_w_i(Execute_ResultW), 
                        .read_data_w_i(ReadDataW), 
                        .result_w_o(result_w)
                    );

    // Hazard Unit
    hazard_unit hazard_block (
                        .rst(rst), 
                        .pc_src_e(pc_src_e),
                        .register_write_m(register_write_m), 
                        .register_write_w(register_write_w), 
                        .RD_M(RD_M), 
                        .rd_w(rd_w), 
                        .Rs1_E(forwarded_RS1_E), 
                        .Rs2_E(forwarded_RS2_E), 
                        .ForwardAE(ForwardAE), 
                        .ForwardBE(ForwardBE),
                        .flush_F(flush_F), 
                        .flush_D(flush_D), 
                        .flush_E(flush_E), 
                        .flush_M(flush_M),
                        
                        
                        .exp_ld_mis_i(exp_ld_mis), 
                        .exp_st_mis_i(exp_st_mis),
                        .exp_instr_addr_mis_i(exp_instr_addr_mis),
                        //.exp_instr_acc_fault_i(exp_instr_acc_fault), 
                        //.exp_st_acc_fault_i(exp_st_acc_fault),
                        //.exp_ld_acc_fault_i(exp_ld_acc_fault),
                        .exp_ill_instr_i(exp_ill_instr),
                        .is_exception_o(is_exception),
                        
                        .exp_access_faults_i(exp_access_faults_i),
                        
                        .mcause_code_o(mcause_code)
                        );
                        
                        
//    Memory_Controller mem_controller(
//        .clk(clk), //1
//        .rst(rst), //1
//        .mem_data_we(), // 1
//        .mem_data_wstrb(), //MAX:32 (4/16), MIN:4 (1/4) 16*4
//        .mem_intr_addr(), // 32
//        .mem_data_addr(), // 32
//        .read_mem_instr(), // 32
//        .read_mem_data(),// 32
//        .write_mem_data(), // 32
//        .mem_data_req(), // 1
//        .mem_intr_req() ,// 1
//        .mem_data_done(), //1
//        .mem_intr_done() //1
//       );   
                        
                        
endmodule
