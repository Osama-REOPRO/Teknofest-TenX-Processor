module except(	
 input clk, 
 input [31:0] opa, opb,
 output inf, ind, qnan, snan, opa_nan, opb_nan, opa_00, opb_00, opa_inf, opb_inf, opa_dn, opb_dn
 );
 
////////////////////////////////////////////////////////////////////////
//
// Local Wires and registers
//
 
wire	[7:0]	expa, expb;		// alias to opX exponent
wire	[22:0]	fracta, fractb;		// alias to opX fraction
reg		expa_ff, qnan_r_a, snan_r_a;
reg		expb_ff, qnan_r_b, snan_r_b;
reg		inf, ind, qnan, snan;	// Output registers
reg		opa_nan, opb_nan;
reg		expa_00, expb_00, fracta_00, fractb_00;
reg		opa_00, opb_00;
reg		opa_inf, opb_inf;
reg		opa_dn, opb_dn;
 
////////////////////////////////////////////////////////////////////////
//
// Aliases
//
 
assign   expa = opa[30:23];
assign   expb = opb[30:23];
assign fracta = opa[22:0];
assign fractb = opb[22:0];
 
////////////////////////////////////////////////////////////////////////
//
// Determine if any of the input operators is a INF or NAN or any other special number
//
// I HAVE REDUCED THE VARIABLES AND COMBINED SIMILAR ASSIGNMENTS
// I AM AFRAID USING DEPENDENT VAIABLES IS SLOWER, AND HENCE THE AUTHOR USED REDUNDANT VARIABLES
always @(posedge clk) begin
	expa_ff <= /*#1*/ &expa;
 	expb_ff <= /*#1*/ &expb;
    fracta_00 <= !(|fracta);
 	fractb_00 <= !(|fractb);
 	qnan_r_a <= fracta[22];
 	snan_r_a <= !fracta[22] & |fracta[21:0];
 	qnan_r_b <= fractb[22];
 	snan_r_b <= !fractb[22] & |fractb[21:0];
    opa_inf <= (expa_ff & fracta_00); // The mantissa/fraction of infinities is zeros
 	opb_inf <= (expb_ff & fractb_00); // The mantissa/fraction of infinities is zeros
 	ind  <= (opa_inf) & (opb_inf);  // indefinite
 	inf  <= (opa_inf) | (opb_inf); 
 	qnan <= (expa_ff & qnan_r_a) | (expb_ff & qnan_r_b);
 	snan <= (expa_ff & snan_r_a) | (expb_ff & snan_r_b);
 	opa_nan <= &expa & (|fracta[22:0]);
 	opb_nan <= &expb & (|fractb[22:0]);
 	expa_00 <= !(|expa);
 	expb_00 <= !(|expb);
 	opa_00 <= expa_00 & fracta_00;
 	opb_00 <= expb_00 & fractb_00;
 	opa_dn <= expa_00;
 	opb_dn <= expb_00;
    end
endmodule
