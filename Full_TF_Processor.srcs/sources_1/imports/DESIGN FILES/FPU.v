module fpu( clk, rmode, fpu_op, opa, opb, out, inf, snan, qnan, ine, overflow, underflow, zero, div_by_zero);
    input		clk;
    input   [1:0]	rmode;
    input	[2:0]	fpu_op;
    input	[31:0]	opa, opb;
    output reg [31:0] out; // Output register
    output reg	inf, snan, qnan; // Output Registers for INF, SNAN and QNAN
    output reg	ine; // Output Registers for INE
    output reg  overflow, underflow; // Output registers for Overflow & Underflow
    output reg  zero;
    output reg  div_by_zero; // Divide by zero output register
    
    parameter	INF  = 31'h7f800000, // 0 11111111 00000000000000000000000
                QNAN = 31'h7fc00001, // 0 11111111 10000000000000000000001
                SNAN = 31'h7f800001; // 0 11111111 00000000000000000000001

    ////////////////////////////////////////////////////////////////////////
    //
    // Local Wires
    //
    reg	    [31:0]	opa_r, opb_r;		// Input operand registers
    //wire            signa, signb;		// alias to opX sign
    wire            sign_fasu;		// sign output
    wire	[26:0]	fracta, fractb;		// Fraction Outputs from EQU block
    wire	[7:0]	exp_fasu;		// Exponent output from EQU block
    reg	    [7:0]	exp_r;			// Exponent output (registerd)
    wire	[26:0]	fract_out_d;		// fraction output
    wire            co;			// carry output
    reg	    [27:0]	fract_out_q;		// fraction output (registerd)
    wire	[30:0]	out_d;			       // Intermediate final result output
    wire            overflow_d, underflow_d;        // Overflow/Underflow Indicators		
    reg	    [1:0]	rmode_r; // rounding mode register
    reg	    [2:0]	fpu_op_r; // register for fp opration
            
    wire		mul_inf, div_inf;
    wire		mul_00, div_00;
 
    ////////////////////////////////////////////////////////////////////////
    //
    // Input Registers
    //
     
    ////////////////////////////////////////////////////////////////////////
    //
    // Exceptions block
    //
    wire		inf_d, ind_d, qnan_d, snan_d, opa_nan, opb_nan;
    wire		opa_00, opb_00;
    wire		opa_inf, opb_inf;
    wire		opa_dn, opb_dn;
     
    except u0(	
            .clk(clk),
            .opa(opa_r), .opb(opb_r),
            .inf(inf_d), .ind(ind_d),
            .qnan(qnan_d), .snan(snan_d),
            .opa_nan(opa_nan), .opb_nan(opb_nan),
            .opa_00(opa_00), .opb_00(opb_00),
            .opa_inf(opa_inf), .opb_inf(opb_inf),
            .opa_dn(opa_dn), .opb_dn(opb_dn)
            );
     
    ////////////////////////////////////////////////////////////////////////
    //
    // Pre-Normalize block
    // - Adjusts the numbers to equal exponents and sorts them
    // (shiftS the exponent of the lesser number to match the bigger number. )
    // - determine result sign
    // (based on the operation and input signs)
    // - determine actual operation to perform (add or sub)
    // (Adjust the operation accordingly: e.g. adding one + and one - is basically sub.)
    //
     
    wire    nan_sign_d, result_zero_sign_d;
    reg		sign_fasu_r;
    wire	[7:0]	exp_mul;
    wire		sign_mul;
    reg		sign_mul_r;
    wire	[23:0]	fracta_mul, fractb_mul;
    wire		inf_mul;
    reg         inf_mul_r;
    wire	[1:0]	exp_ovf;
    reg	    [1:0]	exp_ovf_r;
    wire		sign_exe;
    reg         sign_exe_r;
    wire	[2:0]	underflow_fmul_d;
     
    pre_norm u1(
        .clk(clk),				// System Clock
        .rmode(rmode_r),			// Roundin Mode
        .add(!fpu_op_r[0]),			// Add/Sub Input
        .opa(opa_r),  .opb(opb_r),		// Registered OP Inputs
        .opa_nan(opa_nan),			// OpA is a NAN indicator
        .opb_nan(opb_nan),			// OpB is a NAN indicator
        .fracta_out(fracta),			// Equalized and sorted fraction
        .fractb_out(fractb),			// outputs (Registered)
        .exp_dn_out(exp_fasu),			// Selected exponent output (registered);
        .sign(sign_fasu),			// Encoded output Sign (registered)
        .nan_sign(nan_sign_d),			// Output Sign for NANs (registered)
        .result_zero_sign(result_zero_sign_d),	// Output Sign for zero result (registered)
        .fasu_op(fasu_op)			// Actual fasu operation output (registered)
        );
     
    pre_norm_fmul u2(
            .clk(clk),
            .fpu_op(fpu_op_r),
            .opa(opa_r),
            .opb(opb_r),
            .fracta(fracta_mul),
            .fractb(fractb_mul),
            .exp_out(exp_mul),	// FMUL exponent output (registered)
            .sign(sign_mul),	// FMUL sign output (registered)
            .sign_exe(sign_exe),	// FMUL exception sign output (registered)
            .inf(inf_mul),		// FMUL inf output (registered)
            .exp_ovf(exp_ovf),	// FMUL exponnent overflow output (registered)
            .underflow(underflow_fmul_d)
            );
     
     
    ////////////////////////////////////////////////////////////////////////
    //
    // Add/Sub
    //
     
    adder_unit u3(
        .add(fasu_op),			// Add/Sub
        .fracta(fracta),			// Fraction A input
        .fractb(fractb),			// Fraction B Input
        .sum(fract_out_d),		// SUM output
        .co(co_d) );			// Carry Output
     
    ////////////////////////////////////////////////////////////////////////
    //
    // Mul
    //
    wire	[47:0]	prod;
     
    multiplier_unit u5(.clk(clk), .multiplicand(fracta_mul), .multiplier(fractb_mul), .prod(prod));
     
    ////////////////////////////////////////////////////////////////////////
    //
    // Divide
    //
    wire	[49:0]	quo;
    wire	[49:0]	fdiv_opa;
    wire	[49:0]	div_remainder;
    wire		remainder_00;
    reg	[4:0]	div_opa_ldz_d, div_opa_ldz_r;
     
    always @(fracta_mul)
        casex(fracta_mul[22:0])
           23'b1??????????????????????: div_opa_ldz_d = 1;
           23'b01?????????????????????: div_opa_ldz_d = 2;
           23'b001????????????????????: div_opa_ldz_d = 3;
           23'b0001???????????????????: div_opa_ldz_d = 4;
           23'b00001??????????????????: div_opa_ldz_d = 5;
           23'b000001?????????????????: div_opa_ldz_d = 6;
           23'b0000001????????????????: div_opa_ldz_d = 7;
           23'b00000001???????????????: div_opa_ldz_d = 8;
           23'b000000001??????????????: div_opa_ldz_d = 9;
           23'b0000000001?????????????: div_opa_ldz_d = 10;
           23'b00000000001????????????: div_opa_ldz_d = 11;
           23'b000000000001???????????: div_opa_ldz_d = 12;
           23'b0000000000001??????????: div_opa_ldz_d = 13;
           23'b00000000000001?????????: div_opa_ldz_d = 14;
           23'b000000000000001????????: div_opa_ldz_d = 15;
           23'b0000000000000001???????: div_opa_ldz_d = 16;
           23'b00000000000000001??????: div_opa_ldz_d = 17;
           23'b000000000000000001?????: div_opa_ldz_d = 18;
           23'b0000000000000000001????: div_opa_ldz_d = 19;
           23'b00000000000000000001???: div_opa_ldz_d = 20;
           23'b000000000000000000001??: div_opa_ldz_d = 21;
           23'b0000000000000000000001?: div_opa_ldz_d = 22;
           23'b0000000000000000000000?: div_opa_ldz_d = 23;
        endcase
    
    assign fdiv_opa = !(|opa_r[30:23]) ? {(fracta_mul<<div_opa_ldz_d), 26'h0} : {fracta_mul, 26'h0};
    // 50 bit fraction: if exponent is all zeros ? shift leading zeros to the end, otherwise concatinate zeros to the end
     
    divider_unit u6(.clk(clk), .opa(fdiv_opa), .opb(fractb_mul), .quo(quo), .rem(div_remainder));
        
    ////////////////////////////////////////////////////////////////////////
    //
    // SQRT
    //
//    wire	[23:0]	sqrt_fract;
//    wire	[7:0]	sqrt_exp;
//    wire	[49:0]	sqrt_remainder;
//     norm_and_sqrt_unit u7 (
//                            .clk(clk), 
//                            .exp_in(opa[30:23]), 
//                            .fract_in(fracta) /*same as mul*/, 
//                            .exp_out(sqrt_exp), 
//                            .fract_out(sqrt_fract), 
//                            .rem(sqrt_remainder)
//                            );
     
     
    assign remainder_00 = !(|div_remainder); // | !(|sqrt_remainder);
     
    ////////////////////////////////////////////////////////////////////////
    //
    // Normalize Result
    //
    wire		    ine_d;
    reg	    [47:0]	fract_denorm;
    wire    [47:0]	fract_div;
    wire		    sign_d;
    reg		        sign;
    reg	    [30:0]	opa_r;
    reg	    [47:0]	fract_i2f;
    reg		        opas_r;
    wire		    f2i_out_sign;
     
    assign fract_div = (opb_dn ? quo[49:2] : {quo[26:0], 21'h0});
     
    // this block assigns result to fract_denorm 
    always @(fpu_op_r or fract_out_q or prod or fract_div or fract_i2f)
        case(fpu_op_r)
           0,1:	fract_denorm = {fract_out_q, 20'h0}; //add or sub
           2:	fract_denorm = prod; // mul
           3:	fract_denorm = fract_div; // div
           4,5:	fract_denorm = fract_i2f; // conversion
           6:   fract_denorm = {sqrt_fract, 24'h0}; //sqrt
        endcase
     
    assign sign_d = fpu_op_r[1] /*mul or div*/ ? sign_mul : sign_fasu; // TODO
          
    post_norm u4(
        .clk(clk),			// System Clock
        .fpu_op(fpu_op_r),		// Floating Point Operation
        .opas(opas_r),			// OPA Sign
        .sign(sign),			// Sign of the result
        .rmode(rmode_r),		// Rounding mode
        .fract_in(fract_denorm),	// Fraction Input
        .exp_ovf(exp_ovf_r),		// Exponent Overflow
        .exp_in(exp_r),			// Exponent Input
        .opa_dn(opa_dn),		// Operand A Denormalized
        .opb_dn(opb_dn),		// Operand A Denormalized
        .rem_00(remainder_00),		// Divide Remainder is zero
        .div_opa_ldz(div_opa_ldz_r),	// Divide opa leading zeros count
        .output_zero(mul_00 | div_00),	// Force output to Zero
        .out(out_d),			// Normalized output (un-registered)
        .ine(ine_d),			// Result Inexact output (un-registered)
        .overflow(overflow_d),		// Overflow output (un-registered)
        .underflow(underflow_d),	// Underflow output (un-registered)
        .f2i_out_sign(f2i_out_sign)	// F2I Output Sign
        );
     
    ////////////////////////////////////////////////////////////////////////
    //
    // FPU Outputs
    //
    reg		fasu_op_r;
    wire	[30:0]	out_fixed;
    wire		output_zero_fasu;
    wire		output_zero_fdiv;
    wire		output_zero_fmul;
    reg		    inf_mul2;
    wire		overflow_fasu;
    wire		overflow_fmul;
    wire		overflow_fdiv;
    wire		inf_fmul;
    wire		sign_mul_final;
    wire		out_d_00;
    wire		sign_div_final;
    wire		ine_mul, ine_mula, ine_div, ine_fasu, ine_sqrt;
    wire		underflow_fasu, underflow_fmul, underflow_fdiv, underflow_sqrt;
    wire		underflow_fmul1;
    reg	[2:0]	underflow_fmul_r;
    //reg		opa_nan_r;
     
     
     
    // Force pre-set values for non numerical output
    assign mul_inf = (fpu_op_r==3'b010) & (inf_mul_r | inf_mul2) & (rmode_r==2'h0);
    assign div_inf = (fpu_op_r==3'b011) & (opb_00 | opa_inf);
     
    assign mul_00 = (fpu_op_r==3'b010) & (opa_00 | opb_00);
    assign div_00 = (fpu_op_r==3'b011) & (opa_00 | opb_inf);
     
    assign out_fixed = (
                        (qnan_d | snan_d) | //qnan or snan
                        (ind_d & !fasu_op_r) | //indefinite addition (inf + inf)
                            ( (fpu_op_r == 3'b011) & opb_00 & opa_00) | // division where 0 / 0
                            ( (fpu_op_r == 3'b010)  & ( (opa_inf & opb_00) | (opb_inf & opa_00 ) ) ) | // mul where one number is infinite and the other is zero
                            ( (fpu_op_r == 3'b110) & opa[31]) //sqrt of a negative number
                        )  ? QNAN : INF;        
     
    assign out_d_00 = !(|out_d);
     
    assign sign_mul_final = (sign_exe_r & ((opa_00 & opb_inf) | (opb_00 & opa_inf))) ? !sign_mul_r : sign_mul_r;
    assign sign_div_final = (sign_exe_r & (opa_inf & opb_inf)) ? !sign_mul_r : sign_mul_r | (opa_00 & opb_00);
     
     
    // Exception Outputs
    assign ine_mula = ((inf_mul_r |  inf_mul2 | opa_inf | opb_inf) & (rmode_r==2'h1) & 
            !((opa_inf & opb_00) | (opb_inf & opa_00 )) & fpu_op_r[1]);
     
    assign ine_mul  = (ine_mula | ine_d | inf_fmul | out_d_00 | overflow_d | underflow_d) &
              !opa_00 & !opb_00 & !(snan_d | qnan_d | inf_d);
    assign ine_div  = (ine_d | overflow_d | underflow_d) & !(opb_00 | snan_d | qnan_d | inf_d);
    
    assign ine_fasu = (ine_d | overflow_d | underflow_d) & !(snan_d | qnan_d | inf_d);
    //assign ine_sqrt = ine_fasu; // 
     
     
    // ignore overflow if there are snan, qnan or inf errors 
    assign overflow_fasu = overflow_d & !(snan_d | qnan_d | inf_d);
    assign overflow_fmul = !inf_d & (inf_mul_r | inf_mul2 | overflow_d) & !(snan_d | qnan_d);
    assign overflow_fdiv = (overflow_d & !(opb_00 | inf_d | snan_d | qnan_d));
     
     
    assign underflow_fmul1 = underflow_fmul_r[0] |
                (underflow_fmul_r[1] & underflow_d ) |
                ((opa_dn | opb_dn) & out_d_00 & (prod!=0) & sign) |
                (underflow_fmul_r[2] & ((out_d[30:23]==0) | (out_d[22:0]==0)));
     
    assign underflow_fasu = underflow_d & !(inf_d | snan_d | qnan_d);
    assign underflow_fmul = underflow_fmul1 & !(snan_d | qnan_d | inf_mul_r);
    assign underflow_fdiv = underflow_fasu & !opb_00;
    //assign underflow_sqrt = 0; //TODO
   
     
    assign inf_fmul = (((inf_mul_r | inf_mul2) & (rmode_r==2'h0)) | opa_inf | opb_inf)
                      & 
                      !((opa_inf & opb_00) | (opb_inf & opa_00 )) & fpu_op_r==3'b010;
     
     
    assign output_zero_fasu = out_d_00 & !(inf_d | snan_d | qnan_d);
    assign output_zero_fdiv = (div_00 | (out_d_00 & !opb_00)) & !(opa_inf & opb_inf) &
                               !(opa_00 & opb_00) & !(qnan_d | snan_d);
    assign output_zero_fmul = (out_d_00 | opa_00 | opb_00) &
                              !(inf_mul_r | inf_mul2 | opa_inf | opb_inf | snan_d | qnan_d) &
                              !(opa_inf & opb_00) & !(opb_inf & opa_00);
     
     
    always @(posedge clk) begin
        opa_r <= opa;
        opb_r <= opb;
        rmode_r <= rmode;
        fpu_op_r <= fpu_op;
        sign_fasu_r <= sign_fasu;
        sign_mul_r <= sign_mul;
        sign_exe_r <= sign_exe;
        inf_mul_r <= inf_mul;
        exp_ovf_r <= exp_ovf;
        fract_out_q <= {co_d, fract_out_d};
        div_opa_ldz_r <= div_opa_ldz_d;
        case(fpu_op_r)
          0,1:	exp_r <= exp_fasu; // add and sub: exp_r = pre_norm (add) unit exponent 
          2,3:	exp_r <= exp_mul; // mul / div: exp_r = exp_mul
          4:	exp_r <= 0; // Int to float conversion: the exponent is just zero
          5:	exp_r <= opa_r[30:23]; // Float to int conversion: exponent is equal to opa exponent
          6:    exp_r <= sqrt_exp; // SQRT_EXP
        endcase
    opa_r <= opa_r[30:0]; 
    fract_i2f <= (fpu_op_r==5) ? // FLOAT TO ITN
                    (sign_d ?  1-{24'h00, (|opa_r[30:23]), opa_r[22:0]}-1 : 
                    {24'h0, (|opa_r[30:23]), opa_r[22:0]}) :
                 (sign_d ? 1 - {opa_r, 17'h01} : // INT TO FLOAT 
                 {opa_r, 17'h0});
    opas_r <= opa_r[31];
    sign <= (rmode_r==2'h3) ? !sign_d : sign_d;
    fasu_op_r <= fasu_op;
    inf_mul2 <= exp_mul == 8'hff;
    out[30:0] <= ( mul_inf | 
                   div_inf | 
                   snan_d | 
                   qnan_d | 
                   (inf_d & (fpu_op_r!=3'b011) & (fpu_op_r!=3'b101)))
                    & fpu_op_r!=3'b100 ? out_fixed : out_d;
        out[31] <=	((fpu_op_r==3'b101) & out_d_00) ? (f2i_out_sign & !(qnan_d | snan_d) ) :
                    ((fpu_op_r==3'b010) & !(snan_d | qnan_d)) ?	sign_mul_final :
                    ((fpu_op_r==3'b011) & !(snan_d | qnan_d)) ?	sign_div_final :
                    ((fpu_op_r==3'b110) & !(snan_d | qnan_d)) ? 1'b0 : 
                    (snan_d | qnan_d | ind_d) ?			nan_sign_d :
                    output_zero_fasu ?  result_zero_sign_d :
                    sign_fasu_r;
        ine <=	 (fpu_op_r[2] & !fpu_op_r[1])  ? ine_d : // if conversion and not SQRT
                 fpu_op_r[2]  ? ine_fasu : // else if sqrt
                 !fpu_op_r[1] ? ine_fasu : // else if fasu
                 fpu_op_r[0] ? ine_div  : // else if div
                 ine_mul; // else mul
        overflow <=	 fpu_op_r[2] ? 0 : // no overflow for 1xx (conversion or sqrt)
                    !fpu_op_r[1] ? overflow_fasu : // if 00x then fasu overflow
                    fpu_op_r[0] ? overflow_fdiv :  // if 011 then div overflow
                    overflow_fmul; // last sqrt overflow
        underflow_fmul_r <= underflow_fmul_d;
        underflow <=  (fpu_op_r[2] & !fpu_op_r[1]) ? 0 : // if conversion and not SQRT
                  fpu_op_r[2]  ? underflow_fasu :  // else if sqrt
                  !fpu_op_r[1] ? underflow_fasu : // else if fasu
                  fpu_op_r[0] ? underflow_fdiv :  // else if div
                  underflow_fmul;
                  
        snan <= snan_d;
        qnan <=	 (fpu_op_r[2] & !fpu_op_r[1]) ? 0 : // if conversion and not SQRT
                        (
                            snan_d | 
                            qnan_d | 
                            (ind_d & !fasu_op_r) |
                            (opa_00 & opb_00 & fpu_op_r==3'b011) |
                            (((opa_inf & opb_00) | (opb_inf & opa_00 )) & fpu_op_r==3'b010)
                       );
        inf <=	fpu_op_r[2] ? 0 :
        (!(qnan_d | snan_d) & (
                    ((&out_d[30:23]) & !(|out_d[22:0]) & !(opb_00 & fpu_op_r==3'b011)) |
                    (inf_d & !(ind_d & !fasu_op_r) & !fpu_op_r[1]) |
                    inf_fmul |
                    (!opa_00 & opb_00 & fpu_op_r==3'b011) |
                    (fpu_op_r==3'b011 & opa_inf & !opb_inf)
                      )
        );
        zero <=	fpu_op_r==3'b101 ?	out_d_00 & !(snan_d | qnan_d):
                fpu_op_r==3'b011 ?	output_zero_fdiv :
                fpu_op_r==3'b010 ?	output_zero_fmul :
                                    output_zero_fasu; //add and sqrt
        div_by_zero <= (!opa_nan & fpu_op_r==3'b011) & !opa_00 & !opa_inf & opb_00;
    end
endmodule
