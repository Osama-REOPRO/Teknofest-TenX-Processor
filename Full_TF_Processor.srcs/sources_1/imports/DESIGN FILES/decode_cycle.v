module decode_cycle(clk, rst, flush, InstrD, PCD, PCPlus4D, RegWriteW, RDW, ResultW, RegWriteE, BSrcE, MemWriteE, mem_read_E,
    BranchE,  ALUControlE, RD1_E, RD2_E, Imm_Ext_E, RD_E, JtypeE, PCE, PCPlus4E, RS1_E, RS2_E, funct3_E,
    FPUControlE, RD3_E, F_instruction_E, int_RD_E, int_RD_W
    );

    // Declaring I/O
    input clk, rst, flush, RegWriteW;
    input [4:0] RDW;
    input [31:0] InstrD, PCD, PCPlus4D, ResultW, int_RD_W;
    output RegWriteE,BSrcE,MemWriteE,JtypeE,mem_read_E,BranchE, F_instruction_E, int_RD_E;
    output [5:0] ALUControlE;
    output [4:0] FPUControlE;
    output [31:0] RD1_E, RD2_E, RD3_E, Imm_Ext_E;
    output [4:0] RS1_E, RS2_E, RD_E; // For Forwarding
    output [31:0] PCE, PCPlus4E;
    output [2:0] funct3_E;
    // Declare Interim Wires
    wire RegWriteD,BSrcD,MemWriteD,mem_read_D,BranchD,JtypeD, F_instruction_D, int_RD_D;
    wire [2:0] ImmSrcD;
    wire [5:0] ALUControlD;
    wire [4:0] FPUControlD;
    wire [31:0] RD1_int, RD2_int, RD1_fp, RD2_fp, RD1_D, RD2_D, RD3_D, Imm_Ext_D;
    wire is_rs1_int;
    wire write_to_int_rf;
    // Declaration of Interim Register
    reg RegWriteD_r,BSrcD_r,MemWriteD_r,mem_read_D_r,BranchD_r,JtypeD_r, F_instructionD_r, int_RD_D_r;
    reg [5:0] ALUControlD_r;
    reg [5:0] FPUControlD_r;
    reg [31:0] RD1_D_r, RD2_D_r, RD3_D_r, Imm_Ext_D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r, RS3_D_r;
    reg [31:0] PCD_r, PCPlus4D_r;
    reg [2:0] funct3_D_r;

    // Initiate the modules
    // Control Unit
    Control_Unit_Top control (
                            .Op(InstrD[6:0]),
                            .RegWrite(RegWriteD),
                            .ImmSrc(ImmSrcD),
                            .BSrc(BSrcD),
                            .MemWrite(MemWriteD),
                            .Jtype(JtypeD),
                            .mem_read(mem_read_D),
                            .Branch(BranchD),
                            .funct3(InstrD[14:12]),
                            .funct7(InstrD[31:25]),
                            .funct5(InstrD[24:20]),
                            .ALUControl(ALUControlD),
                            .f_instruction(F_instruction_D),
                            .FPUControl(FPUControlD),
                            .is_rs1_int(is_rs1_int),
                            .is_rd_int(int_RD_D)
                            );
                            
    assign RD1_D = is_rs1_int ? RD1_int : RD1_fp;
    assign RD2_D = F_instruction_D ? RD2_fp : RD2_int;
    assign write_to_int_rf = int_RD_W & RegWriteW;
    assign write_to_fp_rf = !int_RD_W & RegWriteW;

    // Register File
    Integer_RF I_rf (
                        .clk(clk),
                        .rst(rst),
                        .WE3(write_to_int_rf),
                        .WD3(ResultW),
                        .A1(InstrD[19:15]),
                        .A2(InstrD[24:20]),
                        .A3(RDW),
                        .RD1(RD1_int),
                        .RD2(RD2_int)
                        );
                        
    // Floating Register File
    Floating_RF F_rf (
                        .clk(clk),
                        .rst(rst),
                        .WE4(write_to_fp_rf),
                        .WD4(ResultW),
                        .A1(InstrD[19:15]),
                        .A2(InstrD[24:20]),
                        .A3(InstrD[31:27]),
                        .A4(RDW),
                        .RD1(RD1_fp),
                        .RD2(RD2_fp),
                        .RD3(RD3_D)
                        );
    
    // Sign Extension
    Sign_Extend_Immediate extension (
                        .In(InstrD),
                        .Imm_Ext(Imm_Ext_D),
                        .ImmSrc(ImmSrcD)
                        );

    // Declaring Register Logic
    always @(posedge flush) begin
        RegWriteD_r <= 1'b0;
        BSrcD_r <= 1'b0;
        MemWriteD_r <= 1'b0;
        mem_read_D_r <= 1'b0;
        BranchD_r <= 1'b0;
        JtypeD_r <= 1'b0;    
        ALUControlD_r <= 6'b0000000;
        RD1_D_r <= 32'h00000000; 
        RD2_D_r <= 32'h00000000; 
        RD3_D_r <= 32'h0;
        Imm_Ext_D_r <= 32'h00000000;
        RD_D_r <= 5'h00;
        PCD_r <= 32'h00000000; 
        PCPlus4D_r <= 32'h00000000;
        RS1_D_r <= 5'h00;
        RS2_D_r <= 5'h00;
        funct3_D_r <= 3'h0;
        F_instructionD_r <= 1'b0;
        int_RD_D_r <= 1'b0;
        FPUControlD_r <= 4'h0;
    end
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            RegWriteD_r <= 1'b0;
            BSrcD_r <= 1'b0;
            MemWriteD_r <= 1'b0;
            mem_read_D_r <= 1'b0;
            BranchD_r <= 1'b0;
            JtypeD_r <= 1'b0;    
            ALUControlD_r <= 6'b0000000;
            RD1_D_r <= 32'h00000000; 
            RD2_D_r <= 32'h00000000; 
            RD3_D_r <= 32'h0;
            Imm_Ext_D_r <= 32'h00000000;
            RD_D_r <= 5'h00;
            PCD_r <= 32'h00000000; 
            PCPlus4D_r <= 32'h00000000;
            RS1_D_r <= 5'h00;
            RS2_D_r <= 5'h00;
            funct3_D_r <= 3'h0;
            F_instructionD_r <= 1'b0;
            int_RD_D_r <= 1'b0;
            FPUControlD_r <= 4'h0;
        end else begin
            RegWriteD_r <= RegWriteD;
            BSrcD_r <= BSrcD;
            MemWriteD_r <= MemWriteD;
            mem_read_D_r <= mem_read_D;
            BranchD_r <= BranchD;
            JtypeD_r <= JtypeD; 
            ALUControlD_r <= ALUControlD;
            RD1_D_r <= RD1_D; 
            RD2_D_r <= RD2_D; 
            RD3_D_r <= RD3_D;
            Imm_Ext_D_r <= Imm_Ext_D;
            RD_D_r <= InstrD[11:7];
            PCD_r <= PCD; 
            PCPlus4D_r <= PCPlus4D;
            RS1_D_r <= InstrD[19:15];
            RS2_D_r <= InstrD[24:20];
            funct3_D_r <= InstrD[14:12];
            FPUControlD_r <= FPUControlD;
            F_instructionD_r <= F_instruction_D;
            int_RD_D_r <= int_RD_D;
        end
    end

    // Output asssign statements
    assign RegWriteE = RegWriteD_r;
    assign BSrcE = BSrcD_r;
    assign MemWriteE = MemWriteD_r;
    assign mem_read_E = mem_read_D_r;
    assign BranchE = BranchD_r;
    assign JtypeE = JtypeD_r; //CAUSED Jtype TO ACT CORRECTLY IN THE WAVEFORM, ALSO MAKES US ONLY FETCH TWO INSTRUCTIONS
    assign ALUControlE = ALUControlD_r;
    assign RD1_E = RD1_D_r;
    assign RD2_E = RD2_D_r;
    assign RD3_E = RD3_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RD_E = RD_D_r;
    assign PCE = PCD_r;
    assign PCPlus4E = PCPlus4D_r;
    assign RS1_E = RS1_D_r;
    assign RS2_E = RS2_D_r;
    assign funct3_E = funct3_D_r;
    assign FPUControlE = FPUControlD_r;
    assign F_instruction_E = F_instructionD_r;
    assign int_RD_E = int_RD_D_r;

endmodule

module Control_Unit_Top(Op,RegWrite,Jtype,ImmSrc,BSrc,MemWrite,mem_read,Branch,funct3,funct5,funct7,
                        ALUControl, FPUControl, is_rs1_int, is_rd_int, f_instruction);

    input [6:0] Op,funct7;
    input [2:0] funct3;
    input [4:0] funct5;
    output RegWrite,Jtype,BSrc,MemWrite,mem_read,Branch;
    output [2:0] ImmSrc;
    
    output [5:0] ALUControl;
    output [4:0] FPUControl;
    output is_rs1_int;
    output is_rd_int;
    output f_instruction;
    wire [2:0] ALUOp;

    ALU_Main_Decoder ALU_Main_Decoder(
                .Op(Op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .mem_read(mem_read),
                .Branch(Branch),
                .BSrc(BSrc),
                .ALUOp(ALUOp),
                .Jtype(Jtype)
    );
    
    ALU_Signal_Decoder ALU_Signal_Decoder(
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

module Sign_Extend_Immediate (In, ImmSrc, Imm_Ext);
    input [31:0] In;
    input [2:0] ImmSrc;
    output [31:0] Imm_Ext;

    assign Imm_Ext = (ImmSrc == 3'b000) ? {{20{In[31]}}, In[31:20]} : // I-type
                     (ImmSrc == 3'b001) ? {{20{In[31]}}, In[30:25], In[11:7]} : // S-type
                     (ImmSrc == 3'b010) ? {{19{In[31]}}, In[7], In[30:25], In[11:8], 1'b0} : // B-type
                     //LUI NEEDS NO OPERATION, CALCULATING THE IMMEDIATE ALLREADY SHIFTS IT BY 12
                     (ImmSrc == 3'b011) ? {In[31:12], 12'b0} : // U-type (LUI/AUIPC)
                     (ImmSrc == 3'b100) ? {{12{In[31]}}, In[19:12], In[20], In[30:21], 1'b0} : // J-type (JAL)
                     32'h00000000; // Default
endmodule


module ALU_Main_Decoder(Op, RegWrite, ImmSrc, BSrc, MemWrite, mem_read, Branch, ALUOp, Jtype);
    input [6:0] Op;
    output RegWrite, BSrc, MemWrite, mem_read, Branch, Jtype;
    output [2:0] ImmSrc, ALUOp;
    
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
    
    assign RegWrite = (~(Branch || Store));  // ALL instructios write to register except B and S

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
                   
endmodule

module ALU_Signal_Decoder(ALUOp, funct3, funct5, funct7, ALUControl);
    input [2:0] ALUOp;
    input [2:0] funct3;
    input [4:0] funct5;
    input [6:0] funct7;
    output [5:0] ALUControl;
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
    
    101111: 
    110000: 
    110001: 
    110010: 
    110011:    
    110100
    110101
    110110
    110111
    111000
    111001
    111010
    111011
    111100
    111101
    */
    assign ALUControl = (ALUOp == 3'b000) ?
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
                        (ALUOp == 3'b001) ? //Branch
                             (funct3 == 3'b000) ? 6'b000001 : // BEQ - > SUB
                             (funct3 == 3'b001) ? 6'b010001 : // BNE
                             (funct3 == 3'b100) ? 6'b010010 : // BLT
                             (funct3 == 3'b101) ? 6'b001000 : // BGE -> SLT
                             (funct3 == 3'b110) ? 6'b010011 : // BLTU 
                             (funct3 == 3'b111) ? 6'b001001 : // BGEU -> SLTU
                             6'bxxxxxx : // Default
                        (ALUOp == 3'b010) ? // R-type
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
                         (ALUOp == 3'b011) ? 6'b000000 : // ADD for Load
                         (ALUOp == 3'b100) ? 6'b001110 : // LUI (imm << 12)
                         (ALUOp == 3'b101) ? 6'b001111 : // AUIPC 
                         (ALUOp == 3'b110) ? 6'b010000 : // Jal and JALR
                         (ALUOp == 3'b111) ? // ATOMIC
                            (funct5 == 5'b00010)? 6'bx: // LR.W
                            (funct5 == 5'b00011)? 6'bx: // SC.W
                            (funct5 == 5'b00001)? 6'bx: // AMOSWAP.W
                            (funct5 == 5'b00000)? 6'bx: // AMOADD.W
                            (funct5 == 5'b01100)? 6'bx: // AMOAND.W
                            (funct5 == 5'b01010)? 6'bx: // AMOOR.W
                            (funct5 == 5'b00100)? 6'bx: // AMOXOR.W
                            (funct5 == 5'b10100)? 6'bx: // AMOMAX.W
                            (funct5 == 5'b10000)? 6'bx: // AMOMIN.W
                            6'bxxxxxx: // Default
                         6'bxxxxxx; // default at the beginning   
endmodule
module FPU_Decoder(funct3, op, funct5, rs2_funct5, FPUControl, f_instruction, is_rs1_int, is_rd_int);
    input [2:0] funct3; //This is either rm or a funct3
    input [6:0] op;
    input [4:0] funct5;
    input [4:0] rs2_funct5;
    output [4:0] FPUControl;
    output f_instruction, is_rs1_int, is_rd_int;
    
    wire int_rs, int_rd;
    wire r4typeop = op[3:2];
    wire r_i_type = op[4];

    // fmt [26-25] is always 00 since it is single-precision is specifed
    /*
    () means same instruction (), () means same control signal but difference is to be found later in execute
    00000: ADD
    00001: SUB
    00010: MUL
    00011: DIV
    00100: SQRT
    00101: FMADD
    00110: FMSUB
    00111: FNMSUB
    01000: FNMADD
    01001: EQ
    01010: LT
    01011: LE
    01100: MIN
    01101: MAX
    01110:(CVT.W.S, CVT.WU.S) FROM FLOAT TO INT to be seperated
    01111: (CVT.S.W, CVT.S.WU) FROM INT TO FLIAT
    10000: fsgnj
    10001: fsgnjn
    10010: fsgnjx
    10011: CLASS
    
    xxxxx: (MV.X.W)FROM FLOAT TO INT, (MV.W.X) FROM INT TO FLOAT
    
    */     
    
    assign int_rs = r_i_type & (funct5 == 5'b11010 || funct5 == 5'b11110);
    assign int_rd = r_i_type & (funct5 == 5'b11000 || funct5 == 5'b11100);
    
    assign f_instruction = (op[6:5] == 2'b10) ? 1'b1: 1'b0;
    assign is_rs1_int = (!f_instruction || int_rs);
    assign is_rd_int = (!f_instruction || int_rd);
    
    
    assign FPUControl = r_i_type ?
                            (funct5 == 5'b00000) ? 5'b00000 : //ADD
                            (funct5 == 5'b00001) ? 5'b00001 : //SUB
                            (funct5 == 5'b00010) ? 5'b00010 : //MUL
                            (funct5 == 5'b00011) ? 5'b00011 : //DIV
                            (funct5 == 5'b01010) ? 5'b00000 : //SQRT
                            (funct5 == 5'b10100) ?
                               ((funct3 == 3'b010) ? 5'b01001 : //EQ
                                (funct3 == 3'b001) ? 5'b01010 : //LT
                                (funct3 == 3'b000) ? 5'b01011 : //LE
                                5'bxxxxx) : //Default
                            (funct5 == 5'b00101) ?
                               ((funct3 == 3'b000) ? 5'b01100 : //MIN
                                (funct3 == 3'b001) ? 5'b01101 : //MAX
                                5'bxxxxx): // Default
                            (funct5 == 5'b11000) ? 5'b01110 : //CVT.W.S
                            (funct5 == 5'b11010) ? 5'b01111 ://CVT.S.W
                            (funct5 == 5'b11100) ? 5'bxxxxx : //MVT.X.W
                            (funct5 == 5'b11110) ? 5'bxxXXX : //MVT.W.x
                            5'bxxxxx : //DEFAULT
                        r4typeop == 2'b00 ? 5'b01000 : //FNMADD
                        r4typeop == 2'b01 ? 5'b00110 : //FMSUB
                        r4typeop == 2'b10 ? 5'b00111 : //FNMSUB
                        r4typeop == 2'b11 ? 5'b01000 : //FNMADD
                    5'bxxxxx; //Default

endmodule