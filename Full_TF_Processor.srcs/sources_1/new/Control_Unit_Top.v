`include "atomic_ops.vh"

module Control_Unit_Top(
    
        input [6:0] Op,funct7,
        input [2:0] funct3,
        input [4:0] funct5,
        output RegWrite,Jtype,BSrc,MemWrite,mem_read,Branch,
        output [2:0] ImmSrc,
        
        output [5:0] ALUControl,
        output [4:0] FPUControl,
        output is_rs1_int,
        output is_rd_int,
        output f_instruction,
        output [3:0] atomic_op
    );
    
    wire [2:0] ALUOp;
    wire Load, JALR, ImmediateOP, Rtype, LUI, AUIPC, Itype, Utype, Store;
    
    assign Load = (Op === 7'b0000011);
    assign ImmediateOP = (Op === 7'b0010011); // Immediate operations excluding loads b0010011
    assign Rtype = (Op === 7'b0110011);
    assign LUI = (Op === 7'b0110111);
    assign AUIPC = (Op === 7'b0010111);
    assign Utype = (LUI || AUIPC);
    assign JALR = (Op === 7'b1100111);
    assign Itype = (ImmediateOP || Load || JALR );
    assign Jtype = (Op === 7'b1101111); // THAT IS JAL, since JAL is the only Jtype insturction in I
    assign Branch = (Op === 7'b1100011);
    assign Store = (Op === 7'b0100011);
    assign csr_instruction = (Op === 7'b1110011);
    assign RegWrite = ~(Branch || Store);  // ALL instructios write to registers except B and S

    assign ImmSrc = Store ? 3'b001 : // S-type: Stores
                    Branch ? 3'b010 : // B-type: branches
                    Utype ? 3'b011 : // U-type: LUI/AUIPC
                    Jtype ? 3'b100 : // J-type: JAL
                    3'b000; // Default - I-type (b0000011 and b0010011)


    assign BSrc = (Store | Utype | Itype ); // 1 for immediate and 0 for register

    assign MemWrite = Store; // Store

    assign mem_read = Load; // Load
    
    wire funct7_5 = funct7[6:2];
    assign atomic_op = (Op === 7'b0101111) ?  
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

    assign ALUOp = ImmediateOP ? 3'b000 : // I-type except loads and stores
                    Branch ? 3'b001 : // Branches
                    Rtype ? 3'b010 :  /*I AND M*/ 
                   (Load || Store) ? 3'b011 : // I, M and F
                   (LUI) ? 3'b100 :  
                   (AUIPC) ? 3'b101 :
                   (Jtype || JALR) ? 3'b110:
                   (atomic_op || csr_instruction) ? 3'b111:
                   3'b000; // Default  xxx results in xxx writedata
    
    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .funct5(funct5),
                            .ALUControl(ALUControl)
    );
    FPU_Decoder FPU_Decoder(
                            .op(Op),    
                            .funct3(funct3),
                            .funct5(funct7[6:2]),
                            .rs2_funct5(funct5),
                            .FPUControl(FPUControl),
                            .is_rs1_int(is_rs1_int), 
                            .is_rd_int(is_rd_int),
                            .f_instruction(f_instruction)
    );
endmodule