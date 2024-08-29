
module FPU_Decoder(
    input [2:0] funct3, //This is either rm or a funct3
    input [6:0] op,
    input [4:0] funct5,
    input [4:0] rs2_funct5,
    output [4:0] FPUControl,
    output f_instruction, is_rs1_int, is_rd_int
    );
    wire int_rs, int_rd;
    wire r4typeop = op[3:2];
    wire r_i_type = op[4];

    // fmt [26-25] is always 00 since it is single-precision is specifed
    /*
    
    (CVT.W.S, CVT.WU.S) FROM FLOAT TO INT to be seperated -> // TODO RS2 IS IMPORTATN
    (CVT.S.W, CVT.S.WU) FROM INT TO FLIAT -> // TODO RS2 IS IMPORTATN
    
    (MV.X.W) FROM FLOAT TO INT, (MV.W.X) FROM INT TO FLOAT
    //flw and fs, are realized in ALU_decoder
    */     
    
    // CVT.S[U].W  FMV.W.X: TODO
    assign int_rs = r_i_type & (funct5 == 5'b11010 || funct5 == 5'b11110 ); 
    // CVT.W[U].S and (FMV.X.W and CLASS) and COMPARISONS //DONE
    assign int_rd = r_i_type & (funct5 == 5'b11000 || funct5 == 5'b11100 || funct5 == 5'b10100); 
    
    assign f_instruction = (op[6:5] == 2'b10) ? 1'b1: 1'b0;
    assign is_rs1_int = (!f_instruction || int_rs);
    assign is_rd_int = (!f_instruction || int_rd);
    
    
    assign FPUControl = r_i_type ?
                            (funct5 == 5'b00000) ? `FPU_ADD : //ADD
                            (funct5 == 5'b00001) ? `FPU_SUB : //SUB
                            (funct5 == 5'b00010) ? `FPU_MUL : //MUL
                            (funct5 == 5'b00011) ? `FPU_DIV : //DIV
                            (funct5 == 5'b01010) ? `FPU_SQRT : //SQRT
                            (funct5 == 5'b00100) ?
                                (funct3 == 3'b000) ? `FPU_FSGNJ : // J.S
                                (funct3 == 3'b001) ? `FPU_FSGNJ : // JN
                               ((funct3 == 3'b010) ? `FPU_FSGNJ : //JX
                                `FPU_INVALID) : //Default 
                            (funct5 == 5'b10100) ?
                                (funct3 == 3'b000) ? `FPU_CMP: //LE
                                (funct3 == 3'b001) ? `FPU_CMP: //LT
                               ((funct3 == 3'b010) ? `FPU_CMP : //EQ
                                `FPU_INVALID) : //Default
                            (funct5 == 5'b00101) ?
                               ((funct3 == 3'b000) ? `FPU_MIN_MAX: //MIN
                                (funct3 == 3'b001) ? `FPU_MIN_MAX: //MAX
                                `FPU_INVALID): // Default
                            (funct5 == 5'b11000) ?
                                 (rs2_funct5 == 5'b00000 ) ? `FPU_CVT_F2I_U : //CVT.W.S 
                                 (rs2_funct5 == 5'b00001 ) ? `FPU_CVT_F2I_U: //CVT.WU.S
                                 `FPU_INVALID:
                            (funct5 == 5'b11010) ?
                                 (rs2_funct5 == 5'b00000 ) ? `FPU_CVT_I2F : //CVT.W.S 
                                 (rs2_funct5 == 5'b00001 ) ? `FPU_CVT_I2F_U: //CVT.WU.S
                                 `FPU_INVALID:
                            (funct5 == 5'b11100) ? 
                                (
                                    (funct3 == 3'b000) ? `FPU_RETURN_A : //MVT.X.W 
                                    (funct3 == 3'b001) ? `FPU_CLASS : 
                                `FPU_INVALID
                                ): 
                            (funct5 == 5'b11110 & funct3 == 3'b000) ? `FPU_RETURN_A : //MVT.W.x
                            `FPU_INVALID : //DEFAULT
                        r4typeop == 2'b00 ? `FPU_FMADD: //FMADD
                        r4typeop == 2'b01 ? `FPU_FMSUB: //FMSUB
                        r4typeop == 2'b10 ? `FPU_FNMSUB: //FNMSUB
                        r4typeop == 2'b11 ? `FPU_FNMADD : //FNMADD
                    `FPU_INVALID; //Default

endmodule