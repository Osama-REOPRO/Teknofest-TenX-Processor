module FPU_top(
    input clk,
    input [31:0] A, B, C,
    input [4:0] FPUControl,
    output [31:0] Result,
    /*fcsr,*/
    /*OverFlow, Underflow, Inexact, Infinite, Qnan, Snan, Div_by_zero, Zero,*/
    input [2:0] rmode
    );
    
    wire [31:0] op_result;
    wire [2:0] fpu_op,fpu_op_2 ;
  ////////////////////////////////////////////////////////////////////////////////////////////// 
    assign fpu_op = (FPUControl == 5'b0)? 3'b0 : // ADD
                    (FPUControl == 5'b00001)? 3'b001 : // SUB
                    (FPUControl == 5'b00010 || FPUControl == 5'b00101 || FPUControl == 5'b01000
                     || FPUControl == 5'b00110 ||FPUControl == 5'b00111 )? 3'b010 : //MUL
                    (FPUControl == 5'b00011)? 3'b011 :
                    (FPUControl == 5'b01111)? 3'b100 :
                    (FPUControl == 5'b01110)? 3'b101 :
                    (FPUControl == 5'b00100)? 3'b110 : 
                    3'bxxx;
                    
    assign fpu_op_2 = (FPUControl == 5'b00101 ||FPUControl == 5'b01000 )? 3'b0 :
                      (FPUControl == 5'b00110 ||FPUControl == 5'b00111 )? 3'b001 :
                      3'bxxx;
                      
                      
    
    fpu fpu_1(
    .clk(clk),
    .rmode(rmode),
    .fpu_op(fpu_op),
    .opa(A),
    .opb(B),
    .out(op_result),
    .inf(Infinite),
    .snan(Snan),
    .qnan(Qnan), 
    .ine(Inexact), 
    .overflow(), 
    .underflow(), 
    .zero(Zero), 
    .div_by_zero(Div_by_zero)
    );
 ///////////////////////////////////////////////////////////////////////////////////////  
    wire [31:0] cmp_result;
  
     comparator_unit cmp(
        .cmp_op(FPUControl),
        .opa(A),
        .opb(B),
        .cmp_result(cmp_result),
        .unordered(),
        .zero(),
        .inf()
     );   
        
    //////////////////////////////////////////////////////////////////////////////////////    
        wire [32:0]fsgn;  
        
        assign fsgn = (FPUControl == 5'b10000)? {B[31],A[30:0]} : 
                      (FPUControl == 5'b10001)? {~B[31],A[30:0]} :
                       {B[31]^A[31],A[30:0]} ;  
    /////////////////////////////////////////////////////////////////////////////////////
    wire [31:0] op_result_4;
    fpu fpu_2(
        .clk(clk),
        .rmode(rmode),
        .fpu_op(fpu_op_2),
        .opa(op_result),
        .opb(C),
        .out(op_result_4),
        .inf(Infinite),
        .snan(Snan),
        .qnan(Qnan), 
        .ine(Inexact), 
        .overflow(), 
        .underflow(), 
        .zero(Zero), 
        .div_by_zero(Div_by_zero)
        );
        assign op_result_4[31] = (FPUControl == 5'b00101 || 
                                  FPUControl == 5'b00110)? 1'b0: 1'b1;
    
    assign Result = (FPUControl == 5'b0 || 
                     FPUControl == 5'b00001 || 
                     FPUControl == 5'b00010 || 
                     FPUControl == 5'b00011 || 
                     FPUControl == 5'b01111 || 
                     FPUControl == 5'b01110 || 
                     FPUControl == 5'b00100)? op_result :
                     
                    (FPUControl == 5'b00101 ||
                    FPUControl == 5'b01000 || 
                    FPUControl == 5'b00110 || 
                    FPUControl == 5'b00111) ? op_result_4 : 
                     
                    (FPUControl == 5'b10000 || FPUControl == 5'b10001) ? fsgn : 
                    (FPUControl == 5'b01101 || 
                    FPUControl == 5'b01100  || 
                    FPUControl == 5'b01011  || 
                    FPUControl == 5'b01010  || 
                    FPUControl == 5'b01001 )? cmp_result : 
                    A; //for MOVE; //32'bx; 
endmodule
