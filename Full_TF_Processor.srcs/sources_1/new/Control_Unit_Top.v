`include "atomic_ops.vh"
`include "exceptions_codes.vh"
`include "control_signals.vh"

module Control_Unit_Top(
    
        input [6:0] Op,funct7,
        input [2:0] funct3,
        input [4:0] funct5,
        
        output is_csr_o, RegWrite,Jtype,BSrc,MemWrite,mem_read,Branch, //is_error_o,
        output [2:0] ImmSrc,
        output [5:0] ALUControl,
        output [4:0] FPUControl,
        output is_rs1_int,
        output is_rd_int,
        output f_instruction,
        output [3:0] atomic_op
        //output [3:0] mcause_code_o
    );
    
    wire [3:0] ALUOp;
    wire Load, JALR, ImmediateOP, Rtype, LUI, AUIPC, Itype, Utype, Store,is_csr_imm,f_load, f_store;
    
    assign Load = (Op === `LOAD_OP);
    assign f_load = (Op === `F_LOAD_OP);
    assign f_store = (Op === `F_STORE_OP);
    assign ImmediateOP = (Op === `IMM_OP); // Immediate operations excluding loads b0010011
    assign Rtype = (Op === `RTYPE_OP);
    assign LUI = (Op === `LUI_OP);
    assign AUIPC = (Op === `AUIPC_OP);
    assign Utype = (LUI || AUIPC);
    assign JALR = (Op === `JALR_OP);
    assign Itype = (ImmediateOP || Load || JALR );
    assign Jtype = (Op === `JTYPE_OP); // THAT IS JAL, since JAL is the only Jtype insturction in I
    assign Branch = (Op === `BRANCH_OP);
    assign Store = (Op === `STORE_OP);
    assign is_csr_o = (Op === `CSR_OP);
    assign is_csr_imm = is_csr_o && funct3[2];
    assign RegWrite = ~(Branch || Store);  // ALL instructios write to registers except B and S

    assign ImmSrc = Store | f_store ? 3'b001 : // S-type: Stores
                    Branch ? 3'b010 : // B-type: branches
                    Utype ? 3'b011 : // U-type: LUI/AUIPC
                    Jtype ? 3'b100 : // J-type: JAL
                    is_csr_imm ? 3'b101 : // CSR
                    3'b000; // Default - I-type (b0000011 and b0010011)


    assign BSrc = (Store | Utype | Itype | is_csr_imm); // 1 for immediate and 0 for register; 
    //J and branch is added to imm directly in execute, so we don't need to check for it
    
    wire [4:0] funct7_5;
    assign funct7_5  = funct7[6:2];
    
    assign atomic_op =  (Op === 7'b0101111)?  
                        (funct7_5 == 5'b00010)? `load_reserved_aop : // LR.W
                        (funct7_5 == 5'b00011)? `store_conditional_aop : // SC.W
                        (funct7_5 == 5'b00001)? `amo_swap_aop: // AMOSWAP.W
                        (funct7_5 == 5'b00000)? `amo_add_aop: // AMOADD.W
                        (funct7_5 == 5'b01100)? `amo_and_aop: // AMOAND.W
                        (funct7_5 == 5'b01010)? `amo_or_aop : // AMOOR.W
                        (funct7_5 == 5'b00100)? `amo_xor_aop : // AMOXOR.W
                        (funct7_5 == 5'b10100)? `amo_max_aop : // AMOMAX.W
                        (funct7_5 == 5'b10000)? `amo_min_aop : // AMOMIN.W
                            `no_aop
                        :`no_aop ;


    assign MemWrite = Store | |atomic_op; // Store

    assign mem_read = Load; // Load
    wire valid_load, valid_store;
    wire valid_f_load, valid_f_store;
    assign valid_f_load = f_load & (funct3 == 3'b010);
    assign valid_f_store = f_store & (funct3 == 3'b010);

    assign valid_load = Load & (&funct3[2:1] | &funct3[1:0]); //011 or 110 or 111 are forbidden 
    assign valid_store = Store & ~ (funct3[2] | &funct3[1:0]); //anything above 10  

    assign ALUOp = ImmediateOP ? `ALUOP_ITYPE: // I-type except loads and stores
                    Branch ? `ALUOP_BRANCH : // Branches
                    Rtype ? `ALUOP_RTYPE :  /*I AND M*/ 
                   (valid_load | valid_store | valid_f_load | valid_f_store ) ? `ALUOP_LOAD_STORE : // I, M and F
                   (LUI) ? `ALUOP_LUI :  
                   (AUIPC) ? `ALUOP_AUIPC :
                   (Jtype || JALR) ? `ALUOP_JUMPS:
                   (|atomic_op) ? `ALUOP_ATOMIC:
                   (is_csr_o) ? `ALUOP_CSR:
                   4'b0000;// Default -> change to x
   // ADD FMV.W.X, FCT.S.W
    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .funct5(funct5),
                            .ALUControl(ALUControl)
    );
    
    wire f_rd_int;
    FPU_Decoder FPU_Decoder(
                            .op(Op),    
                            .funct3(funct3),
                            .funct5(funct7[6:2]),
                            .rs2_funct5(funct5),
                            .FPUControl(FPUControl),
                            .is_rs1_int(is_rs1_int), 
                            .is_rd_int(f_rd_int),
                            .f_instruction(f_instruction)
    );
    
    assign is_rd_int = valid_f_load | valid_f_store ? 1'b0 : f_rd_int;
    
    // Exception handling
//   wire mem_half_addr_misalign, mem_word_addr_misalign, mem_misalign, div_by_four;
//   wire instruction_misalign, load_misalign, store_amo_misalign;
//   assign mem_half_addr_misalign = funct3[0] & address_i[0];
//   assign not_div_by_four = (&address_i[1:0]);
//   assign mem_word_addr_misalign = funct3[1] & not_div_by_four; 
   
//   assign mem_misalign = (mem_half_addr_misalign|mem_word_addr_misalign);
  
//   assign instruction_misalign =  (JALR|Jtype|Branch) & not_div_by_four;
//   assign load_misalign = Load & mem_misalign;
//   assign store_amo_misalign =  (MemWrite) & mem_misalign;

   
//   assign is_error_o = (instruction_misalign|mem_misalign);
//   assign mcause_code_o = ? `illegal_instr :
//                          instruction_misalign ? `instr_addr_misalign :
//                          load_misalign ? `load_addr_misalign :
//                          store_amo_misalign ? `store_amo_addr_misalign :
//                          4'bx;
//                          // I will get the remaining errors from fetch probably
//                          // instr_access_fault 
//                          //load_access_fault
//                          // store_access_fault
endmodule