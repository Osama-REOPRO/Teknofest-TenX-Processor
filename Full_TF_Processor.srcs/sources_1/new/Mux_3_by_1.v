module Mux_3_by_1 (
    input [31:0] a_i,b_i,c_i,
    input [1:0] s_i,
    output [31:0] d_o
    );

    assign d_o = (s_i == 2'b00) ? a_i :(s_i == 2'b01) ? b_i : (s_i == 2'b10) ? c_i : 32'h0;
    
endmodule