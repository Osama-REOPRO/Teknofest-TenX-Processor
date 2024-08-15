module writeback_cycle(register_write_w,int_rd_w,mem_read_W, PCPlus4W, Execute_ResultW, ReadDataW, result_w);

// Declaration of IOs
input register_write_w,int_rd_w; //useless
input [31:0] PCPlus4W; // useless
input mem_read_W; 
input [31:0] Execute_ResultW, ReadDataW;

output [31:0] result_w;

// Declaration of Module
Mux_2_by_1 result_mux (    
                .a_i(Execute_ResultW),
                .b_i(ReadDataW),
                .s_i(mem_read_W),
                .c_o(result_w));
endmodule