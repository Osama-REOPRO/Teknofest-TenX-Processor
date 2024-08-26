
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
    01110:(CVT.W.S, CVT.WU.S) FROM FLOAT TO INT to be seperated -> // TODO RS2 IS IMPORTATN
    01111: (CVT.S.W, CVT.S.WU) FROM INT TO FLIAT -> // TODO RS2 IS IMPORTATN
    10000: fsgnj TODO
    10001: fsgnjn TODO
    10010: fsgnjx TODO
    10011: CLASS
    10100: (MV.X.W) FROM FLOAT TO INT, (MV.W.X) FROM INT TO FLOAT
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
                            (funct5 == 5'b00000) ? 5'b00000 : //ADD
                            (funct5 == 5'b00001) ? 5'b00001 : //SUB
                            (funct5 == 5'b00010) ? 5'b00010 : //MUL
                            (funct5 == 5'b00011) ? 5'b00011 : //DIV
                            (funct5 == 5'b01010) ? 5'bxxxxx : //SQRT
                            (funct5 == 5'b10100) ?
                               ((funct3 == 3'b010) ? 5'b01001 : //EQ
                                (funct3 == 3'b001) ? 5'b01010 : //LT
                                (funct3 == 3'b000) ? 5'b01011 : //LE
                                5'b11111) : //Default
                            (funct5 == 5'b00101) ?
                               ((funct3 == 3'b000) ? 5'b01100 : //MIN
                                (funct3 == 3'b001) ? 5'b01101 : //MAX
                                5'b11111): // Default
                            (funct5 == 5'b11000) ? 5'b01110 : //CVT.W.S //TODO RS2 IS IMPORTATN
                            (funct5 == 5'b11010) ? 5'b01111 ://CVT.S.W 
                            (funct5 == 5'b11100) ? 
                                (
                                    (funct3 == 3'b000) ? 5'b10100 : //MVT.X.W -> RETURN NUMBER
                                    (funct3 == 3'b001) ? 5'b10011 : 
                                5'b11111): 
                            (funct5 == 5'b11110 & funct3 == 3'b000) ? 5'b10100 : //MVT.W.x  -> RETURN NUMBER 
                            5'b11111 : //DEFAULT
                        r4typeop == 2'b00 ? 5'b01000 : //FNMADD
                        r4typeop == 2'b01 ? 5'b00110 : //FMSUB
                        r4typeop == 2'b10 ? 5'b00111 : //FNMSUB
                        r4typeop == 2'b11 ? 5'b01000 : //FNMADD
                    5'b11111; //Default

endmodule