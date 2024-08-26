module writeback_cycle(

    input mem_read_w_i,
    input [31:0] execute_result_w_i, read_data_w_i,

    output [31:0] result_w_o
);

// Declaration of Module
Mux_2_by_1 result_mux (    
                .a_i(execute_result_w_i),
                .b_i(read_data_w_i),
                .s_i(mem_read_w_i),
                .c_o(result_w_o));
endmodule