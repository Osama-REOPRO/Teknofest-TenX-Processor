module ALU_Top(
    input [31:0] A, B,
    input [5:0] ALUControl,
    input [31:0] PC,
    output Carry, OverFlow, Zero, Negative,
    output [31:0] Result
);

    wire clmulr;
    wire [63:0] BoothProduct;
    wire [31:0] SRA_Result;
    wire [31:0] SLT_Result;
    wire [31:0] SLTU_Result;
    wire [31:0] SLL_Result;
    wire [31:0] SRL_Result;
    wire [31:0] KS_Sum;
    wire KS_Cout;
    wire [31:0] div_quotient;
    wire [31:0] div_remainder;
    
    wire [63:0] CarrylessProduct;
    wire [5:0] leading_zero_count;
    wire [5:0] trailing_zero_count;
    wire [5:0] pop_count;
    wire [31:0] Max_Result;
    wire [31:0] MaxU_Result;
    wire [31:0] Min_Result;
    wire [31:0] MinU_Result;
    wire [31:0] OrcB_Result;
    wire [31:0] REV8_Result;
    wire [31:0] BCLR_Result;
    wire [31:0] BCLRI_Result;
    wire [31:0] BEXT_Result;
    wire [31:0] BEXTI_Result;
    wire [31:0] BINV_Result;
    wire [31:0] BINVI_Result;
    wire [31:0] BSET_Result;
    wire [31:0] SEXTB_Result;
    wire [31:0] SEXTH_Result;
    wire [31:0] SH1ADD_Result;
    wire [31:0] SH2ADD_Result;
    wire [31:0] SH3ADD_Result;
    wire [31:0] XNOR_Result;
    
    
    // Kogge-Stone Adder for Addition and Subtraction
    Kogge_Stone_Adder_32bit ksa (
        .c0(1'b0),
        .in_A(~ALUControl[0]? B : ~B + 1'b1),
        .in_B(A),
        .sum_out(KS_Sum),
        .C_out(KS_Cout)
    );
    
    orc_b orc_b_inst (
    .A(A),
    .Result(OrcB_Result)
    );
   
   wire [63:0] CarrylessProduct_rev; 
   barrel_shift_32bit_rotate barrel_shift (
        .in(CarrylessProduct[31:0]),
        .ctrl(B[4:0]),
        .direction(1'b1), // Rotate right
        .out(CarrylessProduct_rev)
    );
    

    // Instantiate the ZeroCounter32 module
    LeadingZeroCounter32 l_zero_counter (
        .data_in(A),
        .zero_count(leading_zero_count)
    );
    
    // Instantiate the ZeroCounter32 module
    TrailingZeroCounter32 t_zero_counter (
        .data_in(A),
        .zero_count(trailing_zero_count)
    );
    
    // Instantiate the CountPopulation32 module
    CountPopulation32 cpop (
        .data_in(A),
        .pop_count(pop_count)
    );
    
    // Non-Restoring Division
    non_restoring_div32 div (
        .Divs(B),
        .Divdnd(A),
        .quotient(div_quotient),
        .remainder(div_remainder)
    );
                          
    // Instantiate the Booth multiplier
    radix4_booth_multiplier booth_mul (
        .multiplicand(A),
        .multiplier(B),
        .product(BoothProduct)
    );
    
    assign clmulr = (&ALUControl[1:0]) ? 1 : 0;
    // Instantiate the carryless multiplier
    carryless_multiplier carryless_mul (
        .A(A),
        .B(B),
        .clmulr(clmulr),
        .product(CarrylessProduct)
    );
    
    // Shift operations
    assign SLL_Result = A << B[4:0];
    assign SRL_Result = A >> B[4:0];
    assign SRA_Result = $signed(A) >>> B[4:0];
    // SLT and SLTU operations
    assign SLT_Result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0;
    assign SLTU_Result = (A < B) ? 32'd1 : 32'd0;
    assign Max_Result = ($signed(A) > $signed(B)) ? A : B;
    assign MaxU_Result = (A > B) ? A : B;
    assign Min_Result = ($signed(A) < $signed(B)) ? A : B;
    assign MinU_Result = (A < B) ? A : B;
    assign BCLR_Result = A & ~(1 << (B[4:0] & 5'b11111));
    assign BEXT_Result = (A >> (B[4:0] & 5'b11111)) & 1;
    assign BINV_Result = A ^ (1 << (B[4:0] & 5'b11111));
    assign BSET_Result = A | (1 << (B[4:0] & 5'b11111));
    assign SEXTB_Result = {{24{A[7]}}, A[7:0]};
    assign SEXTH_Result = {{16{A[15]}}, A[15:0]};
    assign SH1ADD_Result = B + (A << 1);
    assign SH2ADD_Result = B + (A << 2);
    assign SH3ADD_Result = B + (A << 3);
    assign XNOR_Result = ~ (A ^ B);
    
    
    
    // Result selection based on ALUControl
    assign Result = (ALUControl == `ALU_ADD || ALUControl == `ALU_SUB) ? KS_Sum : // ADD and SUB
                    (ALUControl == `ALU_AND) ? (A & B) :       // AND
                    (ALUControl == `ALU_OR) ? (A | B) :       // OR
                    (ALUControl == `ALU_XOR) ? (A ^ B) :       // XOR
                    (ALUControl == `ALU_SLT) ? SLT_Result :    // SLT
                    (ALUControl == `ALU_SLTU) ? SLTU_Result :   // SLTU
                    (ALUControl == `ALU_SLL) ? SLL_Result :    // SLL
                    (ALUControl == `ALU_SRL) ? SRL_Result :    // SRL
                    (ALUControl == `ALU_SRA) ? SRA_Result :    // SRA
                    (ALUControl == `ALU_MUL) ? BoothProduct[31:0] : // MUL
                    (ALUControl == `ALU_MULH) ? BoothProduct[63:32] : // MUL, MULHSU, MULHU
                    (ALUControl == `ALU_DIV) ? div_quotient :  // div divu
                    (ALUControl == `ALU_REM) ? div_remainder :  // rem remu
                    (ALUControl == `ALU_RETURN_B) ? B : //LUI
                    (ALUControl == `ALU_AUIPC) ? PC + B : // AUIPC 
                    (ALUControl == `ALU_JUMPS) ? PC + 4 : // JAL AND JALR
                    (ALUControl == `ALU_BNE) ? ~(|KS_Sum): //{32{Sum == 0}} : // BNE (neg enabled)
                    (ALUControl == `ALU_BLT) ? ~SLT_Result : // BLT (neg enabled)
                    (ALUControl == `ALU_BLTU) ? ~SLTU_Result : // BLTU (neg enabled)
                    (ALUControl == `ALU_CLZ) ? leading_zero_count : // CLZ
                    (ALUControl == `ALU_CPOP) ? pop_count : // CPOP
                    (ALUControl == `ALU_CTZ) ? trailing_zero_count : // CTZ
                    (ALUControl == `ALU_ORCB) ? OrcB_Result : // ORC.B
                    (ALUControl == `ALU_REV8) ? {A[7:0], A[15:8], A[23:16], A[31:24]} : // REV8
                    (ALUControl == `ALU_ROR) ? (A << B) | (A >> (32 - B)) : // RORI
                    (ALUControl == `ALU_BCLR) ? BCLR_Result : // BCLR
                    (ALUControl == `ALU_BEXT) ? BEXT_Result : // BEXT
                    (ALUControl == `ALU_BINV) ? BINV_Result : // BINV
                    (ALUControl == `ALU_BSET) ? BSET_Result : // BSET
                    (ALUControl == `ALU_SEXTB) ? SEXTB_Result : // SEXT.B
                    (ALUControl == `ALU_SEXTH) ? SEXTH_Result : // SEXT.H
                    (ALUControl == `ALU_ANDN) ? A & ~B : // ANDN
                    (ALUControl == `ALU_CLMUL) ? CarrylessProduct[31:0] : // CLMUL
                    (ALUControl == `ALU_CLMULH) ? CarrylessProduct[63:32] : // CLMULH
                    (ALUControl == `ALU_CLMULR) ? CarrylessProduct[31:0] : // CLMULR
                    (ALUControl == `ALU_MAX) ? Max_Result : // MAX
                    (ALUControl == `ALU_MAXU) ? MaxU_Result : // MAXU
                    (ALUControl == `ALU_MIN) ? Min_Result : // MIN
                    (ALUControl == `ALU_MINU) ? MinU_Result: // MINU
                    (ALUControl == `ALU_ORN) ? A | ~B : // ORN
                    (ALUControl == `ALU_ROL) ? (A << B) | (A >> (32 - B)) : // ROL
                    (ALUControl == `ALU_ROR) ? (A >> B) | (A << (32 - B)) : // ROR
                    (ALUControl == `ALU_BCLR) ? BCLR_Result : // BCLR
                    (ALUControl == `ALU_BEXT) ? BEXT_Result : // BEXT
                    (ALUControl == `ALU_BINV) ? BINV_Result : // BINV
                    (ALUControl == `ALU_BSET) ? BSET_Result : // BSET
                    (ALUControl == `ALU_SH1ADD) ? SH1ADD_Result : // SH1ADD
                    (ALUControl == `ALU_SH2ADD) ? SH2ADD_Result : // SH2ADD
                    (ALUControl == `ALU_SH3ADD) ? SH3ADD_Result : // SH3ADD
                    (ALUControl == `ALU_XNOR) ? XNOR_Result : // XNOR
                    (ALUControl == `ALU_ZEXTH) ? { {16{1'b0}}, A[15:0]} : //    ZEXT.H
                    (ALUControl == `ALU_RETURN_A) ? A :
                    (ALUControl == `ALU_NAND) ? (A & (~B) ) :
                    32'bx;  // DEFAULT

    // Overflow detection for addition and subtraction
    assign OverFlow = ((A[31] & B[31] & ~KS_Sum[31]) | (~A[31] & ~B[31] & KS_Sum[31]));
    
    // Carry detection for addition
    assign Carry = ((~ALUControl[1]) & KS_Cout);

    // Zero flag
    assign Zero = (Result === 32'h0);// Use this to account for when result is zero (when it is not braching)

    // Negative flag
    assign Negative = Result[31];

endmodule