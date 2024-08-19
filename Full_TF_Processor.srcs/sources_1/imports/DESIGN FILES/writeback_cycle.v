module writeback_cycle(

    input mem_read_w_i,
    input [31:0] execute_result_w_i, read_data_w_i,

    output [31:0] result_w_o
);

// Declaration of Module
Mux result_mux (    
                .a(execute_result_w_i),
                .b(read_data_w_i),
                .s(mem_read_w_i),
                .c(result_w_o));
endmodule