module ALU_Top(
    input [31:0] A, B,
    input [5:0] ALUControl,
    input [31:0] PC,
    output Carry, OverFlow, Zero, Negative,
    output [31:0] Result
);
    wire [31:0] Sum;
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
    //wire [63:0] CarrylessProduct_rev;
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
        .in_A(ALUControl[0] == 1'b0 ? B : ~B + 1'b1),
        .in_B(A),
        .sum_out(KS_Sum),
        .C_out(KS_Cout)
    );
    
    orc_b orc_b_inst (
    .A(A),
    .Result(OrcB_Result)
    );
    
//   barrel_shift_32bit_rotate barrel_shift (
//        .in(CarrylessProduct[31:0]),
//        .ctrl(B[4:0]),
//        .direction(1'b1), // Rotate right
//        .out(CarrylessProduct_rev)
//    );
    

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
    
    carryless_multiplier carryless_mul (
        .A(A),
        .B(B),
        .product(CarrylessProduct)
    );
    
    assign Sum = KS_Sum;
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
    assign Result = (ALUControl == 6'b000000 || ALUControl == 6'b000001) ? Sum : // ADD and SUB
                    (ALUControl == 6'b000010) ? (A & B) :       // AND
                    (ALUControl == 6'b000011) ? (A | B) :       // OR
                    (ALUControl == 6'b000100) ? (A ^ B) :       // XOR
                    (ALUControl == 6'b001000) ? SLT_Result :    // SLT
                    (ALUControl == 6'b001001) ? SLTU_Result :   // SLTU
                    (ALUControl == 6'b000101) ? SLL_Result :    // SLL
                    (ALUControl == 6'b000110) ? SRL_Result :    // SRL
                    (ALUControl == 6'b000111) ? SRA_Result :    // SRA
                    (ALUControl == 6'b001010) ? BoothProduct[31:0] : // MUL
                    (ALUControl == 6'b001011) ? BoothProduct[63:32] : // MUL, MULHSU, MULHU
                    (ALUControl == 6'b001100) ? div_quotient :  // div divu
                    (ALUControl == 6'b001101) ? div_remainder :  // rem remu
                    (ALUControl == 6'b001110) ? B : //LUI
                    (ALUControl == 6'b001111) ? PC + B : // AUIPC 
                    (ALUControl == 6'b010000) ? PC + 4 : // JAL AND JALR
                    (ALUControl == 6'b010001) ? ~(|Sum): //{32{Sum == 0}} : // BNE (neg enabled)
                    (ALUControl == 6'b010010) ? ~SLT_Result : // BLT (neg enabled)
                    (ALUControl == 6'b010011) ? ~SLTU_Result : // BLTU (neg enabled)
                    (ALUControl == 6'b010100) ? leading_zero_count : // CLZ
                    (ALUControl == 6'b010101) ? pop_count : // CPOP
                    (ALUControl == 6'b010110) ? trailing_zero_count : // CTZ
                    (ALUControl == 6'b010111) ? OrcB_Result : // ORC.B
                    (ALUControl == 6'b011000) ? {A[7:0], A[15:8], A[23:16], A[31:24]} : // REV8
                    (ALUControl == 6'b011001) ? (A << B) | (A >> (32 - B)) : // RORI
                    (ALUControl == 6'b011010) ? BCLR_Result : // BCLR
                    (ALUControl == 6'b011011) ? BEXT_Result : // BEXT
                    (ALUControl == 6'b011100) ? BINV_Result : // BINV
                    (ALUControl == 6'b011101) ? BSET_Result : // BSET
                    (ALUControl == 6'b011110) ? SEXTB_Result : // SEXT.B
                    (ALUControl == 6'b011111) ? SEXTH_Result : // SEXT.H
                    (ALUControl == 6'b100000) ? A & ~B : // ANDN
                    (ALUControl == 6'b100001) ? CarrylessProduct[31:0] : // CLMUL
                    (ALUControl == 6'b100010) ? CarrylessProduct[63:32] : // CLMULH
                    (ALUControl == 6'b100011) ? CarrylessProduct[31:0] : // CLMULR !TODO
                    (ALUControl == 6'b100100) ? Max_Result : // MAX
                    (ALUControl == 6'b100101) ? MaxU_Result : // MAXU
                    (ALUControl == 6'b100110) ? Min_Result : // MIN
                    (ALUControl == 6'b100111) ? MinU_Result: // MINU
                    (ALUControl == 6'b101000) ? A | ~B : // ORN
                    (ALUControl == 6'b101001) ? (A << B) | (A >> (32 - B)) : // ROL
                    (ALUControl == 6'b101010) ? (A >> B) | (A << (32 - B)) : // ROR
                    (ALUControl == 6'b101011) ? BCLR_Result : // BCLR
                    (ALUControl == 6'b101100) ? BEXT_Result : // BEXT
                    (ALUControl == 6'b101101) ? BINV_Result : // BINV
                    (ALUControl == 6'b101110) ? BSET_Result : // BSET
                    (ALUControl == 6'b101111) ? SH1ADD_Result : // SH1ADD
                    (ALUControl == 6'b110000) ? SH2ADD_Result : // SH2ADD
                    (ALUControl == 6'b110001) ? SH3ADD_Result : // SH3ADD
                    (ALUControl == 6'b110010) ? XNOR_Result : // XNOR
                    (ALUControl == 6'b110011) ? { {16{1'b0}}, A[15:0]} : //    ZEXT.H
                    32'bx;  // DEFAULT

    // Overflow detection for addition and subtraction
    assign OverFlow = ((A[31] & B[31] & ~Sum[31]) | (~A[31] & ~B[31] & Sum[31]));
    
    // Carry detection for addition
    assign Carry = ((~ALUControl[1]) & KS_Cout);

    // Zero flag
    assign Zero = (Result === 32'h0);// Use this to account for when result is zero (when it is not braching)

    // Negative flag
    assign Negative = Result[31];

endmodule