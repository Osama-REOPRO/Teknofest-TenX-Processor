module Mux_2_by_1 (

    input [31:0]a_i,b_i,
    input s_i,
    output [31:0]c_o
);
    assign c_o = (~s_i) ? a_i : b_i ;
    
endmodule