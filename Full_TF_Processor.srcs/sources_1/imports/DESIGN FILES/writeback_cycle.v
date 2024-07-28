module writeback_cycle(RegWriteW,int_RD_W,ResultSrcW, PCPlus4W, Execute_ResultW, ReadDataW, ResultW);

// Declaration of IOs
input RegWriteW,int_RD_W; //useless
input [31:0] PCPlus4W; // useless
input ResultSrcW; 
input [31:0] Execute_ResultW, ReadDataW;

output [31:0] ResultW;

// Declaration of Module
Mux result_mux (    
                .a(Execute_ResultW),
                .b(ReadDataW),
                .s(ResultSrcW),
                .c(ResultW));
endmodule