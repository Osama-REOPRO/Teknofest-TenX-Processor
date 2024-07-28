 
module comparator_unit(cmp_op,opa, opb, unordered, altb, blta, aeqb, inf, zero, cmp_result);
input       [4:0]cmp_op;
input	    [31:0] opa, opb;
output		unordered;
output		altb, blta, aeqb;
output		inf, zero;
output      [31:0]cmp_result;
////////////////////////////////////////////////////////////////////////
//
// Local Wire
//
 
 wire [31:0] max,min,LT,LE,EQ;
 
 
 
reg		altb, blta, aeqb;
 
wire		signa, signb;
wire	[7:0]	expa, expb;
wire	[22:0]	fracta, fractb;
 
wire		expa_ff, expb_ff, fracta_00, fractb_00;
wire		qnan_a, snan_a, qnan_b, snan_b, opa_inf, opb_inf, inf;
wire		qnan, snan, opa_zero, opb_zero;
 
wire 		exp_eq, exp_gt, exp_lt;
wire 		fract_eq, fract_gt, fract_lt;
wire		all_zero;
 
////////////////////////////////////////////////////////////////////////
//
// Aliases
//
 
assign  signa = opa[31];
assign  signb = opb[31];
assign   expa = opa[30:23];
assign   expb = opb[30:23];
assign fracta = opa[22:0];
assign fractb = opb[22:0];
 
////////////////////////////////////////////////////////////////////////
//
// Exception Logic
//
 
assign expa_ff = &expa;
assign expb_ff = &expb;
 
assign fracta_00 = !(|fracta);
assign fractb_00 = !(|fractb);
 
assign qnan_a =  fracta[22];
assign snan_a = !fracta[22] & |fracta[21:0];
assign qnan_b =  fractb[22];
assign snan_b = !fractb[22] & |fractb[21:0];
 
assign opa_inf = (expa_ff & fracta_00);
assign opb_inf = (expb_ff & fractb_00);
assign inf  = opa_inf | opb_inf;
 
assign qnan = (expa_ff & qnan_a) | (expb_ff & qnan_b);
assign snan = (expa_ff & snan_a) | (expb_ff & snan_b);
assign unordered = qnan | snan;
 
assign opa_zero = !(|expa) & fracta_00;
assign opb_zero = !(|expb) & fractb_00;
assign zero = opa_zero;
 
 
////////////////////////////////////////////////////////////////////////
//
// Comparison Logic
//
 
assign exp_eq = expa == expb;
assign exp_gt = expa  > expb;
assign exp_lt = expa  < expb;
 
assign fract_eq = fracta == fractb;
assign fract_gt = fracta  > fractb;
assign fract_lt = fracta  < fractb;
 
assign all_zero = opa_zero & opb_zero;
 
always @( qnan or snan or opa_inf or opb_inf or signa or signb or exp_eq or exp_gt or
	exp_lt or fract_eq or fract_gt or fract_lt or all_zero)
 
	casex( {qnan, snan, opa_inf, opb_inf, signa, signb, exp_eq, exp_gt, exp_lt, fract_eq, fract_gt, fract_lt, all_zero})
	   //13'b??_??_??_???_???_?: {altb, blta, aeqb} = 3'b000;
 
	   13'b1?_??_??_???_???_?: {altb, blta, aeqb} = 3'b000;	// qnan
           13'b?1_??_??_???_???_?: {altb, blta, aeqb} = 3'b000;	// snan
 
           13'b00_11_00_???_???_?: {altb, blta, aeqb} = 3'b001;	// both op INF comparisson
           13'b00_11_01_???_???_?: {altb, blta, aeqb} = 3'b100;
           13'b00_11_10_???_???_?: {altb, blta, aeqb} = 3'b010;
           13'b00_11_11_???_???_?: {altb, blta, aeqb} = 3'b001;
 
           13'b00_10_00_???_???_?: {altb, blta, aeqb} = 3'b100;	// opa INF comparisson
           13'b00_10_01_???_???_?: {altb, blta, aeqb} = 3'b100;
           13'b00_10_10_???_???_?: {altb, blta, aeqb} = 3'b010;
           13'b00_10_11_???_???_?: {altb, blta, aeqb} = 3'b010;
 
           13'b00_01_00_???_???_?: {altb, blta, aeqb} = 3'b010;	// opb INF comparisson
           13'b00_01_01_???_???_?: {altb, blta, aeqb} = 3'b100;
           13'b00_01_10_???_???_?: {altb, blta, aeqb} = 3'b010;
           13'b00_01_11_???_???_?: {altb, blta, aeqb} = 3'b100;
 
           13'b00_00_10_???_???_0: {altb, blta, aeqb} = 3'b010;	//compare base on sign
           13'b00_00_01_???_???_0: {altb, blta, aeqb} = 3'b100;	//compare base on sign
 
           13'b00_00_??_???_???_1: {altb, blta, aeqb} = 3'b001;	//compare base on sign both are zero
 
           13'b00_00_00_010_???_?: {altb, blta, aeqb} = 3'b100;	// cmp exp, equal sign
           13'b00_00_00_001_???_?: {altb, blta, aeqb} = 3'b010;
           13'b00_00_11_010_???_?: {altb, blta, aeqb} = 3'b010;
           13'b00_00_11_001_???_?: {altb, blta, aeqb} = 3'b100;
 
           13'b00_00_00_100_010_?: {altb, blta, aeqb} = 3'b100;	// compare fractions, equal sign, equal exp
           13'b00_00_00_100_001_?: {altb, blta, aeqb} = 3'b010;
           13'b00_00_11_100_010_?: {altb, blta, aeqb} = 3'b010;
           13'b00_00_11_100_001_?: {altb, blta, aeqb} = 3'b100;
 
           13'b00_00_00_100_100_?: {altb, blta, aeqb} = 3'b001;
           13'b00_00_11_100_100_?: {altb, blta, aeqb} = 3'b001;
 
	   default: {altb, blta, aeqb} = 3'bxxx;
	endcase
    assign max = (cmp_op==01101 && blta) ? opa  : opb ;
                        
    assign min=  (cmp_op==01100 && altb) ? opa  : opb  ;
                        
    assign LE =(cmp_op==01011 && altb || aeqb) ? 32'b1 : 32'b0 ;
                        
    assign LT =(cmp_op==01010 && altb) ? 32'b1 : 32'b0; 
     
                        
    assign EQ =(cmp_op==01001 && aeqb) ? 32'b1 : 32'b0; //EQ
    
    assign cmp_result = cmp_op==01101? max :
                        cmp_op==01100? min : 
                        cmp_op==01011? LE  :
                        cmp_op==01010? LT  :
                        cmp_op==01001? EQ  :
                        32'b0; 
    
endmodule

