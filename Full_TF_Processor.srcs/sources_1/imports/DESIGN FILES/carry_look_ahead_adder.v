//module MCLA_16bit( input [15:0] A, B, input C0, output [15:0] S, output final_G, final_P);
//    wire [3:0] temp_P;
//    wire [3:0] temp_notG;
//    wire [3:0] temp_G;
//    wire temp_L0;
//    wire [1:0] temp_L1;
//    wire [2:0] temp_L2;
//    wire [2:0] temp_L3;
//    wire CARRY4,CARRY8,CARRY12;
    
//    begin
//        MCLA_4bit MCLA0 (A[3:0], B[3:0], C0, S[3:0], temp_G[0], temp_P[0]);
//        not invertG0(temp_notG[0], temp_G[0]);
//        nand tempNand_L0 (temp_L0, temp_P[0], C0);
//        nand carry4Nand (CARRY4, temp_notG[0], temp_L0);
        
//        MCLA_4bit MCLA1 (A[7:4], B[7:4], CARRY4, S[7:4], temp_G[1], temp_P[1]);
//        not invertG1(temp_notG[1], temp_G[1]);
//        nand tempNand_L11 (temp_L1[0], temp_P[1], temp_G[0]);
//        nand tempNand_L12 (temp_L1[1], temp_P[1], temp_P[0],C0);
//        nand carry8Nand (CARRY8, temp_notG[1],temp_L1[0],temp_L1[1]);
        

//        MCLA_4bit MCLA2 (A[11:8], B[11:8], CARRY8, S[11:8], temp_G[2], temp_P[2]);
//        not invertG2(temp_notG[2],temp_G[2]);
//        nand tempNand_L21 (temp_L2[0], temp_P[2], temp_G[1]);
//        nand tempNand_L22 (temp_L2[1], temp_P[2], temp_P[1],temp_G[0]);
//        nand tempNand_L23 (temp_L2[2], temp_P[2], temp_P[1],temp_P[0],C0);
//        nand carry12Nand (CARRY12, temp_notG[2],temp_L2[0],temp_L2[1],temp_L2[2]);

//        MCLA_4bit MCLA3 (A[15:12], B[15:12], CARRY12, S[15:12], temp_G[3], temp_P[3]);
//        not invertG3(temp_notG[3], temp_G[3]);
//        and P_AND (final_P, temp_P[3], temp_P[2],temp_P[1],temp_P[0]);
//        nand tempNand_L31 (temp_L3[0], temp_P[3], temp_G[2]);
//        nand tempNand_L32 (temp_L3[1], temp_P[3], temp_P[2], temp_G[1]);
//        nand tempNand_L33 (temp_L3[2], temp_P[3], temp_P[2],temp_P[1],temp_G[0]);
//        nand G_NAND (final_G, temp_notG[3], temp_L3[0],temp_L3[1],temp_L3[2]);
        
//    end
//endmodule



//// MCLA_12bit - I custom added it to realize the 27 bit sum, similar to the 8-bit MCLA
//module MCLA_12bit( input [11:0] A, B, input C0, output [11:0] S /*, output Carry*/);
//    wire [1:0] temp_P;
//    wire [1:0] temp_notG;
//    wire [1:0] temp_G;
//    wire temp_L0;
//    wire [1:0] temp_L1;
//    wire CARRY4,CARRY8;
    
//    begin
//        MCLA_4bit MCLA0 (A[3:0], B[3:0], C0, S[3:0], temp_G[0], temp_P[0]);
//        not invertG0(temp_notG[0], temp_G[0]);
//        nand tempNand_L0 (temp_L0, temp_P[0], C0);
//        nand carry4Nand (CARRY4, temp_notG[0], temp_L0);
        
//        MCLA_4bit MCLA1 (A[7:4], B[7:4], CARRY4, S[7:4], temp_G[1], temp_P[1]);
//        not invertG1(temp_notG[1], temp_G[1]);
//        nand tempNand_L11 (temp_L1[0], temp_P[1], temp_G[0]);
//        nand tempNand_L12 (temp_L1[1], temp_P[1], temp_P[0],C0);
//        nand carry8Nand (CARRY8, temp_notG[1],temp_L1[0],temp_L1[1]);
        

//        MCLA_4bit MCLA2 (A[11:8], B[11:8], CARRY8, S[11:8]/*, temp_G[2], temp_P[2]*/);
//    end
//endmodule



//// MCLA_8bit - I custom added it to realize the 24 bit sum
//// Since MCLA_8bit is going to be used at the end of the adder, i dont need final g and p
//module MCLA_8bit( input [7:0] A, B, input C0, output [7:0] S);
//    wire /*[1:0]*/ temp_P, temp_notG, temp_G, temp_L1;
//    wire temp_L0;
//    wire CARRY4;
//    begin
//        MCLA_4bit MCLA0 (A[3:0], B[3:0], C0, S[3:0], temp_G, temp_P);
//        not invertG0(temp_notG, temp_G);
//        nand tempNand_L0 (temp_L0, temp_P, C0);
//        nand carry4Nand (CARRY4, temp_notG, temp_L0);
        
//        MCLA_4bit MCLA1 (A[7:4], B[7:4], CARRY4, S[7:4]/*, temp_G[1], temp_P[1]*/);
//        // Carry Compuation based on MCLA_16_BIT carry 8 COMPUTATION LOGIC - since the result is 24 bits,
//        // the add is 23 bits, the last bit will be consideres as the carry
//        // old code
////        not invertG1(temp_notG[1], temp_G[1]);
////        nand tempNand_L11 (temp_L1[0], temp_P[1], temp_G[0]);
////        nand tempNand_L12 (temp_L1[1], temp_P[1], temp_P[0],C0);
////        nand carry8Nand (Carry, temp_notG[1],temp_L1[0],temp_L1[1]);
        
//    end
//endmodule
//module MCLA_4bit( input [3:0] A, B, input C0, output [3:0] S, output final_G, final_P);
//    wire [3:0] temp_P;
//    wire [3:0] temp_notG;
//    wire [2:0] temp_G;
//    wire temp_L0;
//    wire [1:0] temp_L1;
//    wire [2:0] temp_L2;
//    wire [2:0] temp_L3;
//    wire CARRY1,CARRY2,CARRY3;
    
//    begin
//        MPFA mpfa0 (A[0], B[0], C0, S[0], temp_notG[0], temp_P[0]);
//        nand tempNand_L0 (temp_L0, temp_P[0], C0);
//        nand carry1Nand (CARRY1, temp_notG[0], temp_L0);
//        not invertG0(temp_G[0], temp_notG[0]);
        
//        MPFA mpfa1 (A[1], B[1], CARRY1, S[1], temp_notG[1], temp_P[1]);
//        nand tempNand_L11 (temp_L1[0], temp_P[1], temp_G[0]);
//        nand tempNand_L12 (temp_L1[1], temp_P[1], temp_P[0],C0);
//        nand carry2Nand (CARRY2, temp_notG[1],temp_L1[0],temp_L1[1]);
//        not invertG1(temp_G[1], temp_notG[1]);

//        MPFA mpfa2 (A[2], B[2], CARRY2, S[2], temp_notG[2], temp_P[2]);
//        nand tempNand_L21 (temp_L2[0], temp_P[2], temp_G[1]);
//        nand tempNand_L22 (temp_L2[1], temp_P[2], temp_P[1],temp_G[0]);
//        nand tempNand_L23 (temp_L2[2], temp_P[2], temp_P[1],temp_P[0],C0);
//        nand carry3Nand (CARRY3, temp_notG[2],temp_L2[0],temp_L2[1],temp_L2[2]);
//        not invertG2(temp_G[2],temp_notG[2]);

//        MPFA mpfa3 (A[3], B[3], CARRY3, S[3], temp_notG[3], temp_P[3]);
//        and P_AND (final_P, temp_P[3], temp_P[2],temp_P[1],temp_P[0]);
//        nand tempNand_L31 (temp_L3[0], temp_P[3], temp_G[2]);
//        nand tempNand_L32 (temp_L3[1], temp_P[3], temp_P[2], temp_G[1]);
//        nand tempNand_L33 (temp_L3[2], temp_P[3], temp_P[2],temp_P[1],temp_G[0]);
//        nand G_NAND (final_G, temp_notG[3], temp_L3[0],temp_L3[1],temp_L3[2]);
//    end
//endmodule

//module MPFA( input A, B, C, output S, notG, P);
//    begin
//        xor pxor(P, A,B); //pxor
//        xor sxor(S,C,P); //sxor
//        nand  GNand(notG,A,B); // GNand
//    end
//endmodule  
