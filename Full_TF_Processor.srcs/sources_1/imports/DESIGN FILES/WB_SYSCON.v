module WB_SYSCON(
    input clk_i, rst_i,
    output CLK_O, RST_O
    );
    assign CLK_O = clk_i;
    assign RST_O = rst_i;
endmodule
