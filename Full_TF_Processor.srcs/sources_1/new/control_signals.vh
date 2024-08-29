`define ALU_ADD    6'b000000
`define ALU_SUB    6'b000001
`define ALU_AND    6'b000010
`define ALU_OR     6'b000011
`define ALU_XOR    6'b000100
`define ALU_SLL    6'b000101
`define ALU_SRL    6'b000110
`define ALU_SRA    6'b000111
`define ALU_SLT    6'b001000
`define ALU_SLTU   6'b001001
`define ALU_MUL    6'b001010
`define ALU_MULH   6'b001011
//`define ALU_MULHU  6'b001011
//`define ALU_MULHSU 6'b001011
`define ALU_DIV    6'b001100
//`define ALU_DIVU   6'b001100
`define ALU_REM    6'b001101
//`define ALU_REMU   6'b001101
`define ALU_RETURN_B 6'b001110 //for LUI
`define ALU_AUIPC  6'b001111
`define ALU_JUMPS    6'b010000
//`define ALU_JALR   6'b010000

// Branch instructions (negatively enabled)
`define ALU_BNE    6'b010001
`define ALU_BLT    6'b010010
`define ALU_BLTU   6'b010011

`define ALU_CLZ    6'b010100
`define ALU_CPOP   6'b010101
`define ALU_CTZ    6'b010110
`define ALU_ORCB   6'b010111
`define ALU_REV8   6'b011000
//`define ALU_RORI   6'b011001
`define ALU_ROR    6'b011001
`define ALU_BCLR   6'b011010
//`define ALU_BCLRI  6'b011010
`define ALU_BEXT   6'b011011
//`define ALU_BEXTI  6'b011011
`define ALU_BINV   6'b011100
//`define ALU_BINVI  6'b011100
`define ALU_BSET   6'b011101
//`define ALU_BSETI  6'b011101
`define ALU_SEXTB  6'b011110
`define ALU_SEXTH  6'b011111
`define ALU_ANDN   6'b100000
`define ALU_CLMUL  6'b100001
`define ALU_CLMULH 6'b100010
`define ALU_CLMULR 6'b100011
`define ALU_MAX    6'b100100
`define ALU_MAXU   6'b100101
`define ALU_MIN    6'b100110
`define ALU_MINU   6'b100111
`define ALU_ORN    6'b101000
`define ALU_ROL    6'b101001
`define ALU_SH1ADD 6'b101010
`define ALU_SH2ADD 6'b101011
`define ALU_SH3ADD 6'b101100
`define ALU_XNOR   6'b101101
`define ALU_ZEXTH  6'b101110
`define ALU_RETURN_A 6'b110100
`define ALU_NAND   6'b110101
`define ALU_INVALID 6'b111111


`define ALUOP_BRANCH 4'b0001
`define ALUOP_ITYPE 4'b0001
`define ALUOP_RTYPE 4'b0010
`define ALUOP_LOAD_STORE 4'b0011
`define ALUOP_LUI 4'b0100
`define ALUOP_AUIPC 4'b0101
`define ALUOP_JUMPS 4'b0110
`define ALUOP_ATOMIC 4'b0111
`define ALUOP_CSR 4'b1000

`define LOAD_OP     7'b0000011
`define F_LOAD_OP   7'b0000111
`define F_STORE_OP  7'b0100111
`define IMM_OP 7'b0010011 // Immediate operations excluding loads
`define RTYPE_OP 7'b0110011
`define LUI_OP 7'b0110111
`define AUIPC_OP 7'b0010111
`define JALR_OP 7'b1100111
`define JTYPE_OP 7'b1101111 // THAT IS JAL, since JAL is the only Jtype insturction in I
`define BRANCH_OP 7'b1100011
`define STORE_OP 7'b0100011
`define CSR_OP 7'b1110011


//// F
`define FPU_ADD        5'b00000
`define FPU_SUB        5'b00001
`define FPU_MUL        5'b00010
`define FPU_DIV        5'b00011
`define FPU_SQRT       5'b00100
`define FPU_FMADD      5'b00101
`define FPU_FMSUB      5'b00110
`define FPU_FNMSUB     5'b00111
`define FPU_FNMADD     5'b01000
`define FPU_CMP        5'b01001 //WE DIFFERENTIATE USING RND/FUNCT3
`define FPU_MIN_MAX    5'b01010 //WE DIFFERENTIATE USING RND/FUNCT3
`define FPU_FSGNJ      5'b01011 //WE DIFFERENTIATE USING RND/FUNCT3
`define FPU_CLASS      5'b10100
`define FPU_RETURN_A   5'b10101

// Conversion operations
`define FPU_CVT_I2F    5'b10110 // Int (signed) to Float
`define FPU_CVT_F2I    5'b10111 // Int (unsigned) to Float
`define FPU_CVT_I2F_U  5'b11000 // Float to Int (signed)
`define FPU_CVT_F2I_U  5'b11001 // Float to Int (unsigned)

`define FPU_INVALID 5'b11111
