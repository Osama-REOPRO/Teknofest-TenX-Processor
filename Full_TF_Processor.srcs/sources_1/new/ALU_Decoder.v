
module ALU_Decoder(
    input [3:0] ALUOp,
    input [2:0] funct3,
    input [4:0] funct5,
    input [6:0] funct7,
    output [5:0] ALUControl
    );
    /*
    000000: ADD
    000001: SUB
    000010: AND
    000011: OR
    000100: XOR
    000101: SLL, SLLI
    000110: SRLL, SRLI
    000111: SRA
    001000: SLT
    001001: SLTU
    001010: MUL
    001011: MULH, MULHU , MULHSU
    001100: DIV, DIVU
    001101: REM, REMU
    001110: LUI (imm << 12)
    001111: AUIPC
    010000: JAL, JALR
    BRANCH INSTRUCTIONS ARE NEG ENABLED BCZ THEY ARE HIGH WHEN THEY RESULT IN ZERO
    010001: BNE
    010010: BLT
    010011: BLTU
    
    010100: CLZ
    010101: CPOP
    010110: CTZ
    010111: ORC.B
    011000: REV8
    011001: RORI, ROR
    011010: BCLR, BCLRI
    011011: BEXT, BEXTI
    011100: BINV, BINVI
    011101: BSET, BSETI
    011110: SEXT.B
    011111: SEXT.H
    100000: ANDN
    100001: CLMUL
    100010: CLMULH
    100011: CLMULR
    100100: MAX
    100101: MAXU
    100110: MIN
    100111: MINU
    101000: ORN
    101001: ROL
    101010: SH1ADD
    101011: SH2ADD
    101100: SH3ADD
    101101: XNOR
    101110: ZEXT.H
    110100: returns A
    110101: NAND for CSSRC(I)
    : CSRRW // RD = 0(CSR) & CSR = RS1 (IF RD=X0 -> CANCEL read operation)
    : CSRRS // RD = 0(CSR) & CSR = CSR | RS1  (IF Rs=X0 -> cancel write op)
    : CSRRC // RD = 0(CSR) & CSR = CSR & ~RS1  (IF Rs=X0 -> cancel write op)
    : CSRRWI // imm var (IF RD=X0 -> CANCEL read operation)
    : CSRRSI // imm var (if imm == 0 -> cancel write op )
    : CSRRCI // imm var (if imm == 0 -> cancel write op ) 
    
    */
    assign ALUControl = (ALUOp == 4'b0000) ?
                             (funct3 == 3'b000) ? 6'b000000 : // ADDI -> ADD
                             (funct3 == 3'b010) ? 6'b001000 : // SLTI
                             (funct3 == 3'b011) ? 6'b001001 : // SLTIU
                             (funct3 == 3'b100) ? 6'b000100 : // XORI
                             (funct3 == 3'b110) ? 6'b000011 : // ORI
                             (funct3 == 3'b111) ? 6'b000010 : // ANDI
                             (funct3 == 3'b101) ? // shift rights
                                ((funct7 == 7'b0000000) ? 6'b000110 : // SRLI
                                (funct7 == 7'b0100000) ? 6'b000111 : // SRAI
                                (funct7 == 7'b0110100) ? 6'b011000 : // rev8
                                (funct7 == 7'b0110000) ? 6'b011001 : // RORI
                                (funct7 == 7'b0100100) ? 6'b011011 : // bext
                                6'bxxxxxx) : //default
                             (funct3 == 3'b001) ?
                                (funct7 == 7'b0110000 ) ? 
                                   ((funct5 == 5'b00000) ? 6'b010100 : //CLZ
                                    (funct5 == 5'b00001) ? 6'b010110 : // CTZ
                                    (funct5 == 5'b00010) ? 6'b010101 : //CPOP
                                    (funct5 == 5'b00100) ? 6'b011110 : // sext.b
                                    (funct5 == 5'b00101) ? 6'b011111 : // sext.h
                                    6'bxxxxxx) : //default 
                                 (funct7 == 7'b0010100) ? 
                                    (funct5 == 5'b00111) ? 6'b010111 :// orc.b
                                     6'b011101 : // bseti
                                (funct7 == 7'b0100100) ?  6'b011010 :// bclr
                                (funct7 == 7'b0110100) ? 6'b011100 : // binv
                                6'b000101 : // SLL
                             6'bxxxxxx : // Default
                        (ALUOp == 4'b0001) ? //Branch
                             (funct3 == 3'b000) ? 6'b000001 : // BEQ - > SUB
                             (funct3 == 3'b001) ? 6'b010001 : // BNE
                             (funct3 == 3'b100) ? 6'b010010 : // BLT
                             (funct3 == 3'b101) ? 6'b001000 : // BGE -> SLT
                             (funct3 == 3'b110) ? 6'b010011 : // BLTU 
                             (funct3 == 3'b111) ? 6'b001001 : // BGEU -> SLTU
                             6'bxxxxxx : // Default
                        (ALUOp == 4'b0010) ? // R-type
                            (funct7 == 7'b0000000) ?
                               ((funct3 == 3'b000) ? 6'b000000 : // ADD
                                (funct3 == 3'b001) ? 6'b000101 : // SLL
                                (funct3 == 3'b010) ? 6'b001000 : // SLT
                                (funct3 == 3'b011) ? 6'b001001 : // SLTU
                                (funct3 == 3'b100) ? 6'b000100 : // XOR
                                (funct3 == 3'b101) ? 6'b000110 : // SRL
                                (funct3 == 3'b110) ? 6'b000011 : // OR
                                (funct3 == 3'b111) ? 6'b000010 : // AND
                                6'bxxxxxx) : // Default (this defeaults dont make sense btw)
                            (funct7 == 7'b0000001) ?
                               ((funct3 == 3'b000) ? 6'b001010 : // MUL
                                (funct3 == 3'b001) ? 6'b001011 : // MULH
                                (funct3 == 3'b010) ? 6'b001011 : //MULHSU -> MULH
                                (funct3 == 3'b011) ? 6'b001011 : //MULHU -> MULH
                                (funct3 == 3'b100) ? 6'b001100 : // DIV
                                (funct3 == 3'b101) ? 6'b001100 : // DIVU -> DIV
                                (funct3 == 3'b110) ? 6'b001101 : // REM
                                (funct3 == 3'b111) ? 6'b001101 : // REMU -> REM
                                6'bxxxxxx) : // Default          
                            (funct7 == 7'b0100000) ?                
                               ((funct3 == 3'b000) ? 6'b000001 : // SUB
                                (funct3 == 3'b101) ? 6'b000111 : // SRA
                                (funct3 == 3'b100) ? 6'b101101 : // xnor
                                (funct3 == 3'b110) ? 6'b101000 : //orn
                                (funct3 == 3'b111) ? 6'b100000 : //ANDN
                                6'bxxxxxx): // Default
                            (funct7 == 7'b0000101) ?                
                               ((funct3 == 3'b001) ? 6'b100001 : // clmul
                                (funct3 == 3'b011) ? 6'b100010 : // clmulh
                                (funct3 == 3'b010) ? 6'b100011 : // clmulr
                                (funct3 == 3'b110) ? 6'b100100 : // max
                                (funct3 == 3'b111) ? 6'b100101 : // maxu
                                (funct3 == 3'b100) ? 6'b100110 : // min
                                (funct3 == 3'b101) ? 6'b100111 : // minu
                                6'bxxxxxx): // Default
                           (funct7 == 7'b0110000) ?                
                               ((funct3 == 3'b001) ? 6'b101001 : //rol
                                (funct3 == 3'b101) ? 6'b011001 : //ror
                                6'bxxxxxx): // Default
                           (funct7 == 7'b0100100) ?                
                               ((funct3 == 3'b001) ? 6'b011010 : // bclr
                                (funct3 == 3'b101) ? 6'b011011 : // bext
                                6'bxxxxxx): // Default
                           (funct7 == 7'b0010000) ?                
                               ((funct3 == 3'b010) ? 6'b101010 : //sh1add
                                (funct3 == 3'b100) ? 6'b101011 : //sh2add
                                (funct3 == 3'b110) ? 6'b101100 : //sh3add
                                6'bxxxxxx): // Default
                           (funct7 == 7'b0110100) ? 6'b011100 : // binv
                           (funct7 == 7'b0010100) ? 6'b011101 : // bset
                           (funct7 == 7'b0000100) ? 6'b101110 : // zext.h
                            6'bxxxxxx : // Default
                         (ALUOp == 4'b0011) ? 6'b000000 : // ADD for Load
                         (ALUOp == 4'b0100) ? 6'b001110 : // LUI (imm << 12)
                         (ALUOp == 4'b0101) ? 6'b001111 : // AUIPC 
                         (ALUOp == 4'b0110) ? 6'b010000 : // Jal and JALR
                         (ALUOp == 4'b0111) ? 6'b110100 :// ATOMIC
                         (ALUOp == 4'b1000) ?
                            (funct3 == 3'b001) ? 6'b001110: // CSRRW -> LUI
                            (funct3 == 3'b010) ? 6'b000011 : // CSRRS -> OR
                            (funct3 == 3'b011) ? 6'b110101 : // CSRRC (NAND)
                            (funct3 == 3'b101) ? 6'b001110 : // CSRRWI -> LUI
                            (funct3 == 3'b110) ? 6'b000011 : // CSRRSI -> OR
                            (funct3 == 3'b111) ? 6'b110101 : // CSRRCI (NAND)
                            6'bxxxxxx: // Default
//                            (funct5 == 5'b00010)? 6'bx: // LR.W
//                            (funct5 == 5'b00011)? 6'bx: // SC.W
//                            (funct5 == 5'b00001)? 6'bx: // AMOSWAP.W
//                            (funct5 == 5'b00000)? 6'bx: // AMOADD.W
//                            (funct5 == 5'b01100)? 6'bx: // AMOAND.W
//                            (funct5 == 5'b01010)? 6'bx: // AMOOR.W
//                            (funct5 == 5'b00100)? 6'bx: // AMOXOR.W
//                            (funct5 == 5'b10100)? 6'bx: // AMOMAX.W
//                            (funct5 == 5'b10000)? 6'bx: // AMOMIN.W
//                            6'bxxxxxx: // Default
                         6'bxxxxxx; // default at the beginning   
endmodule