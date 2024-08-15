
module hazard_unit(rst, pc_src_e, register_write_m, register_write_w, RD_M, rd_w, Rs1_E, Rs2_E, ForwardAE, ForwardBE,
                    flush_F,flush_D, flush_E, flush_M);

    // Declaration of I/Os
    input rst, register_write_m, register_write_w, pc_src_e;
    input [4:0] RD_M, rd_w, Rs1_E, Rs2_E;
    output [1:0] ForwardAE, ForwardBE;
    output flush_F,flush_D, flush_E, flush_M;
    
    
    
    assign ForwardAE = rst ? 2'b00 :
                       (register_write_m & (RD_M != 5'h00) & (RD_M == Rs1_E)) ? 2'b10 :
                       (register_write_w & (rd_w != 5'h00) & (rd_w == Rs1_E)) ? 2'b01 :
                        2'b00;
                       
    assign ForwardBE = rst ? 2'b00 :
                       (register_write_m & (RD_M != 5'h00) & (RD_M == Rs2_E)) ? 2'b10 :
                       (register_write_w & (rd_w != 5'h00) & (rd_w == Rs2_E)) ? 2'b01 : 
                       2'b00;
    assign flush_F = pc_src_e;
    assign flush_D = pc_src_e; 
    assign flush_E = 1'b0; 
    assign flush_M = 1'b0;  


endmodule