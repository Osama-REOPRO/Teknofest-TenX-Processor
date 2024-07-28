module orc_b (
    input [31:0] A,
    output [31:0] Result
);
    wire [7:0] byte0, byte1, byte2, byte3;
    
    // Perform the ORC.B operation on each byte
    assign byte0 = (A[7:0] != 8'b0) ? 8'hFF : 8'h00;
    assign byte1 = (A[15:8] != 8'b0) ? 8'hFF : 8'h00;
    assign byte2 = (A[23:16] != 8'b0) ? 8'hFF : 8'h00;
    assign byte3 = (A[31:24] != 8'b0) ? 8'hFF : 8'h00;

    // Combine the results into the final output
    assign Result = {byte3, byte2, byte1, byte0};
endmodule
