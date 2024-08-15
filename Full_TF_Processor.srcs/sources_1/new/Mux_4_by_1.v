
module Mux_4_by_1 (a,b,c,d, s,e);
    input [31:0] a,b,c, d;
    input [1:0] s;
    output [31:0] e;

    assign e = (s == 2'b00) ? a :
               (s == 2'b01) ? b :
               (s == 2'b10) ? c : 
               (s == 2'b11) ? d : 
               32'h00000000;
    
endmodule