
module hazard_unit(rst, PCSrcE, RegWriteM, RegWriteW, RD_M, RD_W, Rs1_E, Rs2_E, ForwardAE, ForwardBE,
                    flush_F,flush_D, flush_E, flush_M);

    // Declaration of I/Os
    input rst, RegWriteM, RegWriteW, PCSrcE;
    input [4:0] RD_M, RD_W, Rs1_E, Rs2_E;
    output [1:0] ForwardAE, ForwardBE;
    output flush_F,flush_D, flush_E, flush_M;
    
    
    
    assign ForwardAE = rst ? 2'b00 :
                       (RegWriteM & (RD_M != 5'h00) & (RD_M == Rs1_E)) ? 2'b10 :
                       (RegWriteW & (RD_W != 5'h00) & (RD_W == Rs1_E)) ? 2'b01 :
                        2'b00;
                       
    assign ForwardBE = rst ? 2'b00 :
                       (RegWriteM & (RD_M != 5'h00) & (RD_M == Rs2_E)) ? 2'b10 :
                       (RegWriteW & (RD_W != 5'h00) & (RD_W == Rs2_E)) ? 2'b01 : 
                       2'b00;
    assign flush_F = PCSrcE;
    assign flush_D = PCSrcE; 
    assign flush_E = 1'b0; 
    assign flush_M = 1'b0;  


endmodule