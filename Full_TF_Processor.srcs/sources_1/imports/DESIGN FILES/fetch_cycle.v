module fetch_cycle(
    // Declare input & outputs
        input clk, rst, flush,
        
        input mem_instr_done_i,
        input [31:0] mem_instr_rdata_i,
        output reg mem_instr_req_o,
        output reg [31:0] mem_instr_adrs_o,
        
        input PCSrcE,
        input [31:0] PCTargetE,
        output [31:0] InstrD,
        output [31:0] PCD, PCPlus4D
    );

    // Declaring interim wires
    wire [31:0] PC_F, PCF, PCPlus4F;
    //wire [31:0] InstrF;

    // Declaration of Register
    reg [31:0] InstrF_reg;
    reg [31:0] PCF_reg, PCPlus4F_reg;


    // Initiation of Modules
    // Declare PC Mux
    Mux PC_MUX (
                .a(PCPlus4F),
                .b(PCTargetE),
                .s(PCSrcE),
                .c(PC_F)
                );

    // Declare PC Counter
    PC_Module Program_Counter (
                .clk(clk),
                .rst(rst),
                .flush(flush),
                .PC(PCF),
                .PC_Next(PC_F)
                );

    // Communicaet with Instruction Memory through Memory Controller
//    Instruction_Memory IMEM (
//                .rst(rst),
//                .A(PCF),
//                .RD(InstrF)
//                );

    // Declare PC adder
    PC_Adder PC_adder (
                .a(PCF),
                .b(32'h00000004),
                .c(PCPlus4F)
                );

    // Fetch Cycle Register Logic
    always @(posedge flush) begin
        InstrF_reg <= 32'h00000000;
        PCF_reg <= 32'h00000000;
        PCPlus4F_reg <= 32'h00000000;
        mem_instr_req_o <= 1'b0;
    end
    always @(posedge clk or negedge rst) begin
        if(rst == 1'b0) begin
            InstrF_reg <= 32'h00000000;
            PCF_reg <= 32'h00000000;
            PCPlus4F_reg <= 32'h00000000;
        end else if (~mem_instr_done_i) begin
            mem_instr_req_o <= 1'b1;
            mem_instr_adrs_o <= PCF; // PC address
        end else begin // if mem_instr_done_i
            mem_instr_req_o <= 1'b0;
            InstrF_reg <= mem_instr_rdata_i; //InstrF;
            PCF_reg <= PCF;
            PCPlus4F_reg <= PCPlus4F;
        end
    end


    // Assigning Registers Value to the Output port
    assign  InstrD = InstrF_reg;
    assign  PCD = PCF_reg;
    assign  PCPlus4D = PCPlus4F_reg;


endmodule

module Mux (a,b,s,c);

    input [31:0]a,b;
    input s;
    output [31:0]c;

    assign c = (~s) ? a : b ;
    
endmodule

module Mux_3_by_1 (a,b,c,s,d);
    input [31:0] a,b,c;
    input [1:0] s;
    output [31:0] d;

    assign d = (s == 2'b00) ? a : (s == 2'b01) ? b : (s == 2'b10) ? c : 32'h00000000;
    
endmodule


module Mux_4_by_1 (a,b,c,d, s,e);
    input [31:0] a,b,c, d;
    input [1:0] s;
    output [31:0] e;

    assign e = (s == 2'b00) ? a :
               (s == 2'b01) ? b :
               (s == 2'b10) ? c : 
               (s == 2'b11) ? d : 
               32'h00000000;
    
endmodule

module PC_Module(clk,rst, flush, PC,PC_Next);
    input clk,rst, flush;
    input [31:0]PC_Next;
    output [31:0]PC;
    reg [31:0]PC;

//    always @(posedge clk or posedge flush)
//    begin
//        if(rst == 1'b0)
//            PC <= 32'h0;
//        else
//            PC <= PC_Next;
//    end
    always @(posedge flush) begin
        PC <= 32'h0;            
    end
    always @(posedge clk)
    begin
        if(rst == 1'b0)
            PC <= {32{1'b0}};
        else
            PC <= PC_Next;
    end
endmodule


module Instruction_Memory(rst,A,RD);

  input rst;
  input [31:0]A;
  output [31:0]RD;

  reg [31:0] mem [1023:0];
  
  assign RD = (rst == 1'b0) ? {32{1'b0}} : mem[A[31:2]];

  initial begin
    $readmemh("mem.mem",mem);
  end



//  initial begin
//    //mem[0] = 32'hFFC4A303;
//    //mem[1] = 32'h00832383;
//    // mem[0] = 32'h0064A423;
//    // mem[1] = 32'h00B62423;
//    //mem[0] = 32'h0062E233;
//    // mem[1] = 32'h00B62423;

//  end

endmodule


module PC_Adder (a,b,c);

    input [31:0]a,b;
    output [31:0]c;

    assign c = a + b;
    
endmodule