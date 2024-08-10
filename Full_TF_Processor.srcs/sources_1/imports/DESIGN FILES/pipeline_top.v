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
	input  [31:0]	mem_data_rdata_i
);
   //useless
   assign mem_instr_we_o = 1'b0;
   assign mem_instr_wdata_o = 32'b0;
   assign mem_instr_wsize_o = 2'b10;
   
   // For now
   assign mem_data_we_o 	= 1'b0;
	assign mem_data_adrs_o 	= 32'b0;
	assign mem_data_wdata_o = 32'b0;
	assign mem_data_wsize_o = 2'b0;
	assign mem_data_req_o 	= 1'b0;
    
    
    
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

    wire PCSrcE, RegWriteW, RegWriteE, RegWriteM, int_RD_E, int_RD_M, int_RD_W, JtypeE, F_instruction_E;
    wire BSrcE, MemWriteE, ResultSrcE, BranchE, MemWriteM, ResultSrcM, ResultSrcW, mem_op_M;
    wire [5:0] ALUControlE;
    wire [4:0] FPUControlE;
    wire [4:0] RD_E, RD_M, RDW;
    wire [31:0] PCTargetE, InstrD, PCD, PCPlus4D, ResultW, RD1_E, RD2_E, Imm_Ext_E, PCE, PCPlus4E, PCPlus4M, WriteDataM, Execute_ResultM;
    wire [31:0] PCPlus4W, Execute_ResultW, ReadDataW;
    wire [4:0] RS1_E, RS2_E;
    wire [1:0] ForwardBE, ForwardAE;
    wire [2:0] funct3_E, WordSize_M;
//    wire reservation_valid;
//    reg reservation_set;

    // Module Initiation
    // Fetch Stage
    fetch_cycle Fetch (
                        .clk(clk), 
                        .rst(rst), 
                        .flush(flush_F),
                        .mem_instr_adrs_o(mem_instr_adrs_o),
                        .mem_instr_req_o(mem_instr_req_o),
                        .mem_instr_done_i(mem_instr_done_i),
                        .mem_instr_rdata_i(mem_instr_rdata_i),
                        .PCSrcE(PCSrcE), 
                        .PCTargetE(PCTargetE), 
                        .InstrD(InstrD), 
                        .PCD(PCD), 
                        .PCPlus4D(PCPlus4D)
                    );

    // Decode Stage
    decode_cycle Decode (
                        .clk(clk), 
                        .rst(rst), 
                        .flush(flush_D),
                        .InstrD(InstrD), 
                        .PCD(PCD), 
                        .PCPlus4D(PCPlus4D), 
                        .RegWriteW(RegWriteW), 
                        .int_RD_E(int_RD_E),
                        .RDW(RDW), 
                        .ResultW(ResultW),
                        .int_RD_W(int_RD_W),
                        .RegWriteE(RegWriteE), 
                        .BSrcE(BSrcE), 
                        .JtypeE(JtypeE),
                        .MemWriteE(MemWriteE), 
                        .ResultSrcE(ResultSrcE),
                        .BranchE(BranchE),  
                        .ALUControlE(ALUControlE), 
                        .FPUControlE(FPUControlE),
                        .RD1_E(RD1_E), 
                        .RD2_E(RD2_E), 
                        .Imm_Ext_E(Imm_Ext_E), 
                        .RD_E(RD_E), 
                        .PCE(PCE), 
                        .PCPlus4E(PCPlus4E),
                        .RS1_E(RS1_E),
                        .RS2_E(RS2_E),
                        .funct3_E(funct3_E),
                        .F_instruction_E(F_instruction_E)
                    );

    // Execute Stage
    execute_cycle Execute (
                        .clk(clk), 
                        .rst(rst),
                        .flush(flush_E),
                        .RegWriteE(RegWriteE), 
                        .int_RD_E(int_RD_E),
                        .BSrcE(BSrcE),
                        .MemWriteE(MemWriteE), 
                        .ResultSrcE(ResultSrcE), 
                        .BranchE(BranchE), 
                        .ALUControlE(ALUControlE), 
                        .FPUControlE(FPUControlE),
                        .RD1_E(RD1_E), 
                        .RD2_E(RD2_E), 
                        .Imm_Ext_E(Imm_Ext_E), 
                        .RD_E(RD_E), 
                        .PCE(PCE), 
                        .JtypeE(JtypeE),
                        .PCPlus4E(PCPlus4E), 
                        .PCSrcE(PCSrcE), 
                        .PCTargetE(PCTargetE), 
                        .RegWriteM(RegWriteM),
                        .int_RD_M(int_RD_M),
                        .MemWriteM(MemWriteM), 
                        .ResultSrcM(ResultSrcM), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M), 
                        .WriteDataM(WriteDataM), 
                        .Execute_ResultM(Execute_ResultM),
                        .ResultW(ResultW),
                        .ForwardA_E(ForwardAE),
                        .ForwardB_E(ForwardBE),
                        .funct3_E(funct3_E),
                        .WordSize_M(WordSize_M),
                        .F_instruction_E(F_instruction_E),
                        .mem_op_M(mem_op_M)
                    );
    
    // Memory Stage
    memory_cycle Memory (
                        .clk(clk), 
                        .rst(rst),
                        .flush(flush_M),
                        .RegWriteM(RegWriteM),
                        .int_RD_M(int_RD_M),
                        .MemWriteM(MemWriteM), 
                        .ResultSrcM(ResultSrcM), 
                        .RD_M(RD_M), 
                        .PCPlus4M(PCPlus4M), 
                        .WriteDataM(WriteDataM), 
                        .Execute_ResultM(Execute_ResultM), 
                        .RegWriteW(RegWriteW), 
                        .int_RD_W(int_RD_W),
                        .ResultSrcW(ResultSrcW), 
                        .RD_W(RDW), 
                        .PCPlus4W(PCPlus4W), 
                        .Execute_ResultW(Execute_ResultW), 
                        .ReadDataW(ReadDataW),
                     	.WordSize_M(WordSize_M)
                    );

    // Write Back Stage
    writeback_cycle WriteBack (
                        .RegWriteW(RegWriteW),
                        .int_RD_W(int_RD_W),
                        .ResultSrcW(ResultSrcW), 
                        .PCPlus4W(PCPlus4W), 
                        .Execute_ResultW(Execute_ResultW), 
                        .ReadDataW(ReadDataW), 
                        .ResultW(ResultW)
                    );

    // Hazard Unit
    hazard_unit Forwarding_block (
                        .rst(rst), 
                        .PCSrcE(PCSrcE),
                        .RegWriteM(RegWriteM), 
                        .RegWriteW(RegWriteW), 
                        .RD_M(RD_M), 
                        .RD_W(RDW), 
                        .Rs1_E(RS1_E), 
                        .Rs2_E(RS2_E), 
                        .ForwardAE(ForwardAE), 
                        .ForwardBE(ForwardBE),
                        .flush_F(flush_F), 
                        .flush_D(flush_D), 
                        .flush_E(flush_E), 
                        .flush_M(flush_M)
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
