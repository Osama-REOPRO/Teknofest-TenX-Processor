`include "control_signals.vh"

module ALU_Decoder(
    input [3:0] ALUOp,
    input [2:0] funct3,
    input [4:0] funct5,
    input [6:0] funct7,
    output [5:0] ALUControl
    );
   /*
    
    
    : CSRRW // RD = 0(CSR) & CSR = RS1 (IF RD=X0 -> CANCEL read operation)
    : CSRRS // RD = 0(CSR) & CSR = CSR | RS1  (IF Rs=X0 -> cancel write op)
    : CSRRC // RD = 0(CSR) & CSR = CSR & ~RS1  (IF Rs=X0 -> cancel write op)
    : CSRRWI // imm var (IF RD=X0 -> CANCEL read operation)
    : CSRRSI // imm var (if imm == 0 -> cancel write op )
    : CSRRCI // imm var (if imm == 0 -> cancel write op ) 
    
    */
    assign ALUControl = (ALUOp == `ALUOP_ITYPE) ?
                             (funct3 == 3'b000) ? `ALU_ADD : // ADDI -> ADD
                             (funct3 == 3'b010) ? `ALU_SLT: // SLTI
                             (funct3 == 3'b011) ? `ALU_SLTU : // SLTIU
                             (funct3 == 3'b100) ? `ALU_XOR : // XORI
                             (funct3 == 3'b110) ? `ALU_OR : // ORI
                             (funct3 == 3'b111) ? `ALU_AND: // ANDI
                             (funct3 == 3'b101) ? // shift rights
                                ((funct7 == 7'b0000000) ? `ALU_SRL : // SRLI
                                (funct7 == 7'b0100000) ? `ALU_SRA : // SRAI
                                (funct7 == 7'b0110100) ? `ALU_REV8 : // rev8
                                (funct7 == 7'b0110000) ? `ALU_ROR  : // RORI
                                (funct7 == 7'b0100100) ? `ALU_BEXT: // bext
                                `ALU_INVALID) : //default
                             (funct3 == 3'b001) ?
                                (funct7 == 7'b0110000 ) ? 
                                   ((funct5 == 5'b00000) ? `ALU_CLZ : //CLZ
                                    (funct5 == 5'b00001) ? `ALU_CTZ: // CTZ
                                    (funct5 == 5'b00010) ? `ALU_CPOP : //CPOP
                                    (funct5 == 5'b00100) ? `ALU_SEXTB : // sext.b
                                    (funct5 == 5'b00101) ? `ALU_SEXTH: // sext.h
                                    `ALU_INVALID) : //default 
                                 (funct7 == 7'b0010100) ? 
                                    (funct5 == 5'b00111) ? `ALU_ORCB :// orc.b
                                    /*(funct5 == 5'b00101) ? */ `ALU_BSET : // bseti TODO
                                (funct7 == 7'b0100100) ?  `ALU_BCLR:// bclr
                                (funct7 == 7'b0110100) ? `ALU_BINV : // binv
                                (funct7 == 7'b0000000) ? `ALU_SLL : // SLL
                                `ALU_INVALID : 
                            `ALU_INVALID :
                        (ALUOp == `ALUOP_BRANCH) ? //Branch
                             (funct3 == 3'b000) ? `ALU_SUB : // BEQ - > SUB
                             (funct3 == 3'b001) ? `ALU_BNE : // BNE
                             (funct3 == 3'b100) ? `ALU_BLT : // BLT
                             (funct3 == 3'b101) ? `ALU_SLT : // BGE -> SLT
                             (funct3 == 3'b110) ? `ALU_BLTU : // BLTU 
                             (funct3 == 3'b111) ? `ALU_SLTU : // BGEU -> SLTU
                             `ALU_INVALID : // Default
                        (ALUOp == `ALUOP_RTYPE) ? // R-type
                            (funct7 == 7'b0000000) ?
                               ((funct3 == 3'b000) ? `ALU_ADD: // ADD
                                (funct3 == 3'b001) ? `ALU_SLL : // SLL
                                (funct3 == 3'b010) ? `ALU_SLT : // SLT
                                (funct3 == 3'b011) ? `ALU_SLTU : // SLTU
                                (funct3 == 3'b100) ? `ALU_XOR : // XOR
                                (funct3 == 3'b101) ? `ALU_SRL : // SRL
                                (funct3 == 3'b110) ? `ALU_OR : // OR
                                (funct3 == 3'b111) ? `ALU_AND : // AND
                                `ALU_INVALID) :
                            (funct7 == 7'b0000001) ?
                               ((funct3 == 3'b000) ? `ALU_MUL : // MUL
                                (funct3 == 3'b001) ? `ALU_MULH : // MULH
                                (funct3 == 3'b010) ? `ALU_MULH: //MULHSU -> MULH
                                (funct3 == 3'b011) ? `ALU_MULH : //MULHU -> MULH
                                (funct3 == 3'b100) ? `ALU_DIV : // DIV
                                (funct3 == 3'b101) ? `ALU_DIV: // DIVU -> DIV
                                (funct3 == 3'b110) ? `ALU_REM : // REM
                                (funct3 == 3'b111) ? `ALU_REM : // REMU -> REM
                                `ALU_INVALID) : // Default          
                            (funct7 == 7'b0100000) ?                
                               ((funct3 == 3'b000) ? `ALU_SUB : // SUB
                                (funct3 == 3'b101) ? `ALU_SRA : // SRA
                                (funct3 == 3'b100) ? `ALU_XNOR : // xnor
                                (funct3 == 3'b110) ? `ALU_ORN : //orn
                                (funct3 == 3'b111) ? `ALU_ANDN : //ANDN
                                `ALU_INVALID): // Default
                            (funct7 == 7'b0000101) ?                
                               ((funct3 == 3'b001) ? `ALU_CLMUL : // clmul
                                (funct3 == 3'b011) ? `ALU_CLMULH : // clmulh
                                (funct3 == 3'b010) ? `ALU_CLMULR : // clmulr
                                (funct3 == 3'b110) ? `ALU_MAX : // max
                                (funct3 == 3'b111) ? `ALU_MAXU : // maxu
                                (funct3 == 3'b100) ? `ALU_MIN : // min
                                (funct3 == 3'b101) ? `ALU_MINU : // minu
                                `ALU_INVALID): // Default
                           (funct7 == 7'b0110000) ?                
                               ((funct3 == 3'b001) ? `ALU_ROL : //rol
                                (funct3 == 3'b101) ? `ALU_ROR : //ror
                                `ALU_INVALID): // Default
                           (funct7 == 7'b0100100) ?                
                               ((funct3 == 3'b001) ? `ALU_BCLR : // bclr
                                (funct3 == 3'b101) ? `ALU_BEXT : // bext
                                `ALU_INVALID): // Default
                           (funct7 == 7'b0010000) ?                
                               ((funct3 == 3'b010) ? `ALU_SH1ADD : //sh1add
                                (funct3 == 3'b100) ? `ALU_SH2ADD : //sh2add
                                (funct3 == 3'b110) ? `ALU_SH3ADD : //sh3add
                                `ALU_INVALID): // Default
                           (funct7 == 7'b0110100) ? `ALU_BINV : // binv
                           (funct7 == 7'b0010100) ? `ALU_BSET : // bset
                           (funct7 == 7'b0000100) ? `ALU_ZEXTH : // zext.h
                            `ALU_INVALID : // Default
                         (ALUOp == `ALUOP_LOAD_STORE) ? `ALU_ADD : // ADD for Load and store
                         (ALUOp == `ALUOP_LUI) ? `ALU_RETURN_B : // LUI (imm << 12)
                         (ALUOp == `ALUOP_AUIPC) ? `ALU_AUIPC : // AUIPC 
                         (ALUOp == `ALUOP_JUMPS) ? `ALU_JUMPS : // Jal and JALR
                         (ALUOp == `ALUOP_ATOMIC & funct3 == 3'b010) ? `ALU_RETURN_A :// ATOMIC
                         (ALUOp == `ALUOP_CSR) ?
                            (funct3 == 3'b001) ? `ALU_RETURN_B: // CSRRW -> LUI
                            (funct3 == 3'b010) ? `ALU_OR : // CSRRS -> OR
                            (funct3 == 3'b011) ? `ALU_NAND : // CSRRC (NAND)
                            (funct3 == 3'b101) ? `ALU_RETURN_B : // CSRRWI -> LUI
                            (funct3 == 3'b110) ? `ALU_OR : // CSRRSI -> OR
                            (funct3 == 3'b111) ? `ALU_NAND : // CSRRCI (NAND)
                            `ALU_INVALID:
                         `ALU_INVALID; // default at the beginning   
endmodule