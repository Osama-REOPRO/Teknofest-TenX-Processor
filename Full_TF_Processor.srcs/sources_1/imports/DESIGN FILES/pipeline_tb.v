`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.06.2024 14:44:08
// Design Name: 
// Module Name: pipeline_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pipeline_tb();
reg clk=0, rst_H;

//initial begin

//     //Load instructions into memory
//    Instruction_Memory.mem[0] = 32'h00500293; // addi t0, x0, 5
//    Instruction_Memory.mem[1] = 32'h00300313; // addi t1, x0, 3
//    Instruction_Memory.mem[2] = 32'h006283B3; // add t2, t0, t1
//    Instruction_Memory.mem[3] = 32'h00002403; // lw x8, 0(x0)
//    Instruction_Memory.mem[4] = 32'h00100493; // addi s1, x0, 1
//    Instruction_Memory.mem[5] = 32'h00940533; // add x10, s1, x9
//  end



always begin
    clk=~clk;
    #50;
end


initial begin
    //rst_H <= 1'b1;
    rst_H <= 1'b0;
    #200;
//    PCsrcE <= 1'b0;
    rst_H <= 1'b1;

    #5000;
    $finish;
end

initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0);
end

Pipeline_top uut(.clk(clk),.rst_H(rst_H));

endmodule
