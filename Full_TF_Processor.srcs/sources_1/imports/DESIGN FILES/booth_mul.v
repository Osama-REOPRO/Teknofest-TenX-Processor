module radix4_booth_multiplier (
    input  wire [31:0] multiplicand,
    input  wire [31:0] multiplier,
    output reg  [63:0] product
);
    reg [63:0] mcand;   // Extended multiplicand
    reg [63:0] mplier;  // Extended multiplier
    reg [63:0] A, S, P; // Partial products and intermediate registers
    integer i;

    always @(*) begin
        mcand = {32'b0, multiplicand};   // Initialize extended multiplicand
        mplier = {multiplier, 1'b0};     // Initialize extended multiplier with an extra bit
        A = mcand;
        S = -mcand;
        P = 64'b0;                       // Initialize partial product
        
        // Main Radix-4 Booth's algorithm loop
        for (i = 0; i < 32; i = i + 2) begin
            case (mplier[2:0])
                3'b000, 3'b111: ; // No operation
                3'b001, 3'b010: P = P + (A << i);
                3'b011: P = P + ((A << 1) << i);
                3'b100: P = P + ((S << 1) << i);
                3'b101, 3'b110: P = P + (S << i);
            endcase
            mplier = mplier >> 2;  // Shift right by 2 bits for next iteration
        end

        product = P;  // Assign final product
    end
endmodule
