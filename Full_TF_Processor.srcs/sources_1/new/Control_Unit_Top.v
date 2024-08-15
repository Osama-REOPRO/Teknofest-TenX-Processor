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
        output f_instruction
    );
    
    wire [2:0] ALUOp;
    wire Load, JALR, ImmediateOP, Rtype, LUI, AUIPC, Itype, Utype, Store, Atomic;
    
    assign Load = (Op === 7'b0000011);
    assign ImmediateOP = (Op === 7'b0010011); // Immediate operations excluding loads b0010011
    assign Rtype = (Op === 7'b0110011); // b0110011
    assign LUI = (Op === 7'b0110111);
    assign AUIPC = (Op === 7'b0010111);
    assign Utype = (LUI || AUIPC);
    assign JALR = (Op === 7'b1100111);
    assign Itype = (ImmediateOP || Load || JALR );
    assign Jtype = (Op === 7'b1101111); // THAT IS JAL, since JAL is the only Jtype insturction in I
    assign Branch = (Op === 7'b1100011);
    assign Store = (Op === 7'b0100011);
    assign Atomic = (Op === 7'b0101111);
    
    assign RegWrite = ~(Branch || Store);  // ALL instructios write to registers except B and S

    assign ImmSrc = Store ? 3'b001 : // S-type: Stores
                    Branch ? 3'b010 : // B-type: branches
                    Utype ? 3'b011 : // U-type: LUI/AUIPC
                    Jtype ? 3'b100 : // J-type: JAL
                    3'b000; // Default - I-type (b0000011 and b0010011)


    assign BSrc = (Store | Utype | Itype ); // 1 for immediate and 0 for register

    assign MemWrite = Store; // Store

    assign mem_read = Load; // Load

    assign ALUOp = ImmediateOP ? 3'b000 : // I-type except loads and stores
                    Rtype ? 3'b010 :  /*I AND M*/ 
                    Branch ? 3'b001 : // Branches
                   (Load || Store) ? 3'b011 : // I, M and F
                   (LUI) ? 3'b100 :  
                   (AUIPC) ? 3'b101 :
                   (Jtype || JALR) ? 3'b110:
                   (Atomic) ? 3'b111:
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