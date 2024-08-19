module carryless_multiplier (
    input [31:0] A,
    input [31:0] B,
    input clmulr,          // Control signal: 0 for CLMUL, 1 for CLMULR
    output [63:0] product
);

    wire [31:0] A_rev, B_rev;       // Reversed versions of A and B
    wire [31:0] A_eff, B_eff;       // Effective A and B used for computation
    wire [63:0] partial_products [31:0];
    wire [63:0] shifted_partial_products [31:0];

    // Bit-reverse function
    function [31:0] reverse_bits;
        input [31:0] in;
        integer j;
        begin
            for (j = 0; j < 32; j = j + 1) begin
                reverse_bits[j] = in[31-j];
            end
        end
    endfunction

    // Reverse A and B if clmulr is set
    assign A_rev = reverse_bits(A);
    assign B_rev = reverse_bits(B);
    assign A_eff = clmulr ? A_rev : A;
    assign B_eff = clmulr ? B_rev : B;

    genvar i;
    generate
        // Generate partial products
        for (i = 0; i < 32; i = i + 1) begin : partial_products_gen
            assign partial_products[i] = B_eff[i] ? A_eff : 32'd0;
            assign shifted_partial_products[i] = {partial_products[i], {i{1'b0}}};
        end
    endgenerate

    // XOR all the shifted partial products to get the carry-less product
    wire [63:0] product_intermediate = shifted_partial_products[0] ^ shifted_partial_products[1] ^ shifted_partial_products[2] ^ shifted_partial_products[3] ^
                                       shifted_partial_products[4] ^ shifted_partial_products[5] ^ shifted_partial_products[6] ^ shifted_partial_products[7] ^
                                       shifted_partial_products[8] ^ shifted_partial_products[9] ^ shifted_partial_products[10] ^ shifted_partial_products[11] ^
                                       shifted_partial_products[12] ^ shifted_partial_products[13] ^ shifted_partial_products[14] ^ shifted_partial_products[15] ^
                                       shifted_partial_products[16] ^ shifted_partial_products[17] ^ shifted_partial_products[18] ^ shifted_partial_products[19] ^
                                       shifted_partial_products[20] ^ shifted_partial_products[21] ^ shifted_partial_products[22] ^ shifted_partial_products[23] ^
                                       shifted_partial_products[24] ^ shifted_partial_products[25] ^ shifted_partial_products[26] ^ shifted_partial_products[27] ^
                                       shifted_partial_products[28] ^ shifted_partial_products[29] ^ shifted_partial_products[30] ^ shifted_partial_products[31];

    // Reverse the output if clmulr is set
    assign product = clmulr ? {reverse_bits(product_intermediate[63:32]), reverse_bits(product_intermediate[31:0])} : product_intermediate;

endmodule