module LeadingZeroCounter32 (
    input [31:0] data_in,
    output reg [5:0] zero_count
);
    integer i;
    reg counting;

    always @(*) begin
        zero_count = 0;
        counting = 1;
        // Count leading zeros
        for (i = 31; i >= 0 && counting; i = i - 1) begin
            if (data_in[i] == 1'b1)
                counting = 0;
            else
                zero_count = zero_count + 1;
        end
    end
endmodule
module TrailingZeroCounter32 (
    input [31:0] data_in,
    output reg [5:0] zero_count
);
    integer i;
    reg counting;

    always @(*) begin
        zero_count = 0;
        counting = 1;
        // Count trailing zeros
        for (i = 0; i < 32 && counting; i = i + 1) begin
            if (data_in[i] == 1'b1)
                counting = 0;
            else
                zero_count = zero_count + 1;
        end
    end
endmodule
