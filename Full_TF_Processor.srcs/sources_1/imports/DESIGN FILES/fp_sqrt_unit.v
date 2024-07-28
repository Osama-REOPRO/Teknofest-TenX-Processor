module norm_and_sqrt_unit(clk, exp_in, fract_in, exp_out, fract_out, rem);
    input clk;
    input   [7:0] exp_in;
    input   [23:0] fract_in;
    output  [7:0] exp_out;
    output  [23:0] fract_out; 
    output  [24:0] rem;
    
    
    wire expa_norm = (|exp_in);

    reg [23:0] fract_result;
    reg [7:0] exp_new;
    reg [11:0] sq_final;

    
    reg signed [24:0] remainder;
    reg [23:0] D , A;
    reg [11:0] quotient;
    integer i , k, l ,j, f,count;
    
    reg [31:0] square_1;

    always @(posedge clk) begin

        exp_new = exp_in - (126 + expa_norm);
        exp_new = (exp_new+exp_new[0])>>2 ; //divide by 4 (add one if the exponent is odd);
        exp_new = exp_new + (126 + expa_norm) ;
        
        
        // MANTISSA
        fract_result = fract_in;
        fract_result = fract_result<<1; // multiplying by 2
        remainder = { 1'b0, fract_result};
        A = 24'b0;
        quotient = 12'b0;
        
        D = 24'b0;
        for (k=24; k>0 ; k=k-1) begin
            j=k-1;
            if (remainder[j] == 1'b1)
                k=0;
        end
        if (j[0] == 0) begin
            A[j] = 1;
            f=(j+2)/2 ;
        end else begin
            A[j-1] = 1;
            f=(j+1)/2;  
        end
       for (count = 12 ; count > 0; count=count-1) begin
            if (remainder >= 0) begin
                D=remainder;
                remainder= remainder-A ;
            end else begin
                remainder = D;
                remainder= remainder-A ;
            end
            if (remainder >=0) 
                quotient[count-1] = 1;
            else
                quotient[count-1] = 0;
            if (12 - count>= f-1)
                count = 0;
            A = A >> 2;
            for (i=0 ; i<=23 ; i=i+1) begin
                k=i ;
                if (A[k]==1)
                    i=24;
            end
            for (l=0; l<=12-count ; l=l+1)
                A[l+k+2]= quotient[11-12+count+l];
        end
          
       sq_final = quotient >> (12-f);
   end
    //end
    assign exp_out = exp_new;
    assign square = square_1;
    assign fract_out = {sq_final, 11'b0};
    assign rem = remainder;
endmodule