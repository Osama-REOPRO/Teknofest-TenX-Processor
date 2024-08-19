module writeback_cycle(

    input mem_read_w,
    input [31:0] Execute_ResultW, ReadDataW,

    output [31:0] result_w_i
);

// Declaration of Module
Mux result_mux (    
                .a(Execute_ResultW),
                .b(ReadDataW),
                .s(mem_read_w|AT),
                .c(result_w_i));
endmodule