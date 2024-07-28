module  divider_unit(
  
input clk,
input	[49:0]	opa,
input	[23:0]	opb,
output	[49:0]	quo, 
output [49:0] rem
);
 
reg	[49:0]	quo, rem, quo1, remainder;
 
always @(posedge clk)
	quo1 <= #1 opa / opb;
 
always @(posedge clk)
	quo <= #1 quo1;
 
always @(posedge clk)
	remainder <= #1 opa % opb;
 
always @(posedge clk)
	rem <= #1 remainder;
 
endmodule




