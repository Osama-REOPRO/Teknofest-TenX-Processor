module adder_unit( 
input add,
input [26:0] fracta , fractb, 
output [26:0] sum,
output co
);
   // MANTISAA IS ALWAYS NON-NEGATIVE
    wire [27:0] mantissaA28, mantissaB28;
    wire [27:0] sum28;
    wire CARRY16, temp_L0;
    wire /*[1:0]*/ temp_G, temp_notG, temp_P; //, temp_L1;
    begin
        
        assign mantissaA28 = {1'b0, fracta};
        assign mantissaB28 = { 1'b0 ,add ? fractb : ~fractb + 1};
        MCLA_16bit MCLA0 (mantissaA28[15:0], mantissaB28[15:0], 0, sum28[15:0], temp_G, temp_P);
        not invertG0(temp_notG, temp_G);
        nand tempNand_L0 (temp_L0, temp_P, 0);
        nand carry16Nand(CARRY16, temp_notG, temp_L0);
        
        //MCLA_8bit 
        MCLA_12bit MCLA1 (mantissaA28[27:16], mantissaB28[27:16], CARRY16, sum28[27:16] /*, carry*/);
        assign {co, sum} = sum28;
        // Evaluate carry - ( i dont need it) - do it anyways
//        not invertG1(temp_notG[1], temp_G[1]);
//        nand tempNand_L11 (temp_L1[0], temp_P[1], temp_G[0]);
//        nand tempNand_L12 (temp_L1[1], temp_P[1], temp_P[0],0);
//        nand carry24Nand (carry, temp_notG[1],temp_L1[0],temp_L1[1]);
        
        //Evaluate overflow (turns out i dont the carry)
        // assign overflow = (mantissaA[23] == mantissaB[23]) && (sum[23] != mantissaA[23]); 


    end
endmodule

