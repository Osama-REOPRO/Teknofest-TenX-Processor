module writeback_cycle(RegWriteW,int_RD_W,mem_read_W, PCPlus4W, Execute_ResultW, ReadDataW, ResultW);

// Declaration of IOs
input RegWriteW,int_RD_W; //useless
input [31:0] PCPlus4W; // useless
input mem_read_W; 
input [31:0] Execute_ResultW, ReadDataW;

output [31:0] ResultW;

// Declaration of Module
Mux result_mux (    
                .a(Execute_ResultW),
                .b(ReadDataW),
                .s(mem_read_W),
                .c(ResultW));
endmodule