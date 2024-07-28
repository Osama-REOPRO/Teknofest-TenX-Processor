module non_restoring_div32(
    input wire [31:0] Divs,     // Divisor
    input wire [31:0] Divdnd,   // Dividend
    output reg [31:0] quotient,
    output reg [31:0] remainder
);

reg [31:0] M;    // Divisor register
reg [31:0] A;    // Partial remainder
reg [31:0] Q;    // Quotient register
integer i;       // Loop counter

always @(*) begin
    // Initialize variables
    M = Divs;
    A = 32'b0;
    Q = Divdnd;
    
    // Iterate 32 times to perform division
    for (i = 0; i < 32; i = i + 1) begin
        // Shift left A and Q combined
        A = {A[30:0], Q[31]};
        Q = {Q[30:0], 1'b0};

        // Subtract or add M based on the sign of A
        if (A[31] == 0) begin
            A = A - M;
        end else begin
            A = A + M;
        end

        // Update the LSB of Q based on the result of the operation
        if (A[31] == 0) begin
            Q[0] = 1'b1;
        end else begin
            Q[0] = 1'b0;
        end
    end
    
    // Final adjustment if A is negative
    if (A[31] == 1) begin
        A = A + M;
    end
    
    // Assign outputs
    quotient = Q;
    remainder = A;
end

endmodule