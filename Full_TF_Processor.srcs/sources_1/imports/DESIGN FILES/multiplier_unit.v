module multiplier_unit (input clk, input [23:0]multiplicand, input [23:0]multiplier, output [47:0] prod);

    reg   [11:0] x0, x1, y0, y1;
    reg  [23:0] z0, z1, z2;
    reg  [11:0] sum_x0x1, sum_y0y1;
     function  [23:0] multip(
        input  [11:0] multiplican,
        input  [11:0] multiplie
    );
        
        integer i;
        reg  [23:0] temp_A;
        reg   [11:0] temp_B;
        reg [23:0] sum;
        
        begin
            
            temp_A = {12'b0, multiplican}; // initialize temp_a with a and pad with 0s
        temp_B = multiplie; // initialize temp_b with b
        sum = 24'b0; // initialize sum with 0
        
        for (i = 0; i < 12; i = i + 1) begin
            if (temp_B[i] == 1'b1) begin
                sum = sum + (temp_A << i); // add shifted temp_a to sum
            end
        end
        
        multip = sum; // assign sum to product
    end
       
    endfunction
    always @(posedge clk) begin
        // Split the numbers
        x0 = multiplicand[11:0];
        x1 = multiplicand[23:12];
        y0 = multiplier[11:0];
        y1 = multiplier[23:12];
        
        // Sum of parts
        sum_x0x1 = x0 + x1;
        sum_y0y1 = y0 + y1;

        // Perform Booth's Multiplication on parts
        z0 = multip(x0, y0); // x0 * y0
        z2 = multip(x1, y1); // x1 * y1
        z1 = multip(sum_x0x1, sum_y0y1); // (x0 + x1) * (y0 + y1)
         
        // Combine the results using Karatsuba's method
    end
    assign  product = (z2 << 24) + ((z1 - z2 - z0) << 12) + z0;
endmodule
