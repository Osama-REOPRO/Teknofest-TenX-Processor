module Integer_RF(clk, rst, WE3,WD3,A1,A2,A3,RS1,RS2);
    input clk,rst,WE3;
    input [4:0]A1,A2,A3;
    input [31:0]WD3;
    output [31:0]RS1,RS2;

    reg [31:0] Register [31:0];

    always @ (posedge clk) begin
        if(WE3)
            Register[A3] <= WD3;
    end

    assign RS1 = (rst==1'b0) ? 32'd0 : Register[A1];
    assign RS2 = (rst==1'b0) ? 32'd0 : Register[A2];

    genvar i;
    generate for (i = 0; i < 32; i = i + 1) 
        begin : init_loop
            initial begin
                Register[i] = 32'h0;
            end
        end
    endgenerate

endmodule


module Floating_RF(clk, rst, WE4,WD4,A1,A2,A3, A4, RS1,RS2, RS3);
    input clk,rst,WE4;
    input [4:0]A1, A2, A3, A4;
    input [31:0]WD4;
    output [31:0]RS1,RS2, RS3;

    reg [31:0] Register [31:0];

    always @ (posedge clk) begin
        if(WE4) Register[A4] <= WD4;
    end

    assign RS1 = (rst==1'b0) ? 32'd0 : Register[A1];
    assign RS2 = (rst==1'b0) ? 32'd0 : Register[A2];
    assign RS3 = (rst==1'b0) ? 32'd0 : Register[A3];

    genvar i;
    generate for (i = 0; i < 32; i = i + 1) 
        begin : init_loop
            initial begin
                Register[i] = 32'h0;
            end
        end
    endgenerate
    
    initial begin
        Register[1] = 32'b01000000010110011001100110011010; //3.4
        Register[2] = 32'b00111111100110011001100110011010; // 3.2
    end
    

endmodule




module CSR_RF(clk, rst, WE2,WD2,A1,A2,RS1);
    input clk,rst, WE2; //write enable for A2 i.e. rd
    input [11:0] A1,A2; //rs and rd
    input [31:0] WD2; // write data for A2 i.e. rd
    output [31:0] RS1; // read data of rs

    reg [31:0] Register [4069:0];

    always @ (posedge clk) begin
        if(WE2) Register[A2] <= WD2;
    end

    assign RS1 = (rst==1'b0) ? 32'd0 : Register[A1];
    
    genvar i;
    generate for (i = 0; i < 4069; i = i + 1) 
        begin : init_loop
            initial begin
                Register[i] = 32'h0;
            end
        end
    endgenerate

endmodule