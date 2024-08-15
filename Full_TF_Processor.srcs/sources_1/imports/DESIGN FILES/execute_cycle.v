/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
this_stage_done -> this flags indicates that the stage has done its job  
next_ready_i -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o = this_stage_done && next_ready_i -> this flag indicates that the stage is ready to propagate its values
prev_ready_i -> this flag indicates that the stage is ready to work on its data
*/

module execute_cycle
# (parameter STAGE_CYCLE_REQ = 2'b11)
(
    // Declaration I/Os
    input clk, rst, flush, JtypeE, register_write_e,
    BSrcE, MemWriteE,mem_read_E,BranchE, F_instruction_E, int_rd_e,
    input [5:0] ALUControlE,
    input [4:0] FPUControlE,
    input [31:0] RD1_E, RD2_E, RD3_E, Imm_Ext_E,
    input [4:0] RD_E,
    input [31:0] PCE, PCPlus4E,
    input [31:0] result_w,
    input [1:0] ForwardA_E, ForwardB_E,
    input [2:0] funct3_E,

    output pc_src_e, register_write_m, MemWriteM, mem_read_M, int_rd_m,
    output [4:0] RD_M,
    output [31:0] PCPlus4M, WriteDataM, Execute_ResultM,
    output [31:0] pc_target_e,

    output [2:0] WordSize_M,

    input next_ready_i,
    output reg this_ready_o,
    input prev_valid_i,
    output reg this_valid_o
);
    // Declaration of Interim Wires
    wire [31:0] Src_A, Src_B_interim, Src_B, pc_target_e_r;
    wire [31:0] ResultE;
    wire ZeroE;

    // Declaration of Register
    reg register_write_e_r, MemWriteE_r, mem_read_E_r ,pc_src_e_r, int_rd_e_r;
    reg [4:0] RD_E_r;
    reg [31:0] PCPlus4E_r, RD2_E_r, ResultE_r;
    reg [2:0] WordSize_E_r;
    reg [31:0] PCTarget_E_r;
    
    //Coordination wires
    reg processing,processing_done;
    reg [1:0] stage_cycle_counter; //3
    // Declaration of Modules
    
    // 3 by 1 Mux for Source A
    Mux_3_by_1 srca_mux (
                        .a_i(RD1_E),
                        .b_i(result_w),
                        .c_i(Execute_ResultM),
                        .s_i(ForwardA_E),
                        .d_o(Src_A)
                        );

    // 3 by 1 Mux for Source B
    Mux_3_by_1 srcb_mux (
                        .a_i(RD2_E),
                        .b_i(result_w),
                        .c_i(Execute_ResultM),
                        .s_i(ForwardB_E),
                        .d_o(Src_B_interim)
                        );
    // ALU Src Mux
    Mux_2_by_1 alu_src_mux (
            .a_i(Src_B_interim),
            .b_i(Imm_Ext_E),
            .s_i(BSrcE),
            .c_o(Src_B)
            );
    wire [31:0] FPU_Result = 0;
    wire [31:0] ALU_Result;
    
    
//    FPU_Top fpu
//    (
//        .clk(clk), 
//        .A(Src_A),
//        .B(Src_B),
//        .C(RD3_E),
//        .rmode(funct3_E),
//        .Result(FPU_Result),
//        .FPUControl(FPUControlE)
//    );
    
    // ALU Unit
    ALU_Top alu (
            .A(Src_A),
            .B(Src_B),
            .Result(ALU_Result),
            .ALUControl(ALUControlE),
            .PC(PCE),
            .OverFlow(),
            .Carry(),
            .Zero(ZeroE),
            .Negative()
            );
            
            
    assign ResultE = F_instruction_E ? FPU_Result : ALU_Result;
    
    
    // Adder
    PC_Adder branch_adder (
            .a_i( (JtypeE || BranchE) ? PCE: Src_A), // if Jtype (JAL) or branch, PC, else (JALR), RS1
            .b_i(Imm_Ext_E),
            .c_o(pc_target_e_r)
            );
    // Register Logic
    always @(posedge flush) begin
        {     
            register_write_e_r,
            MemWriteE_r, 
            mem_read_E_r,
            RD_E_r,
            PCPlus4E_r,
            RD2_E_r,
            ResultE_r,
            WordSize_E_r,
            PCTarget_E_r,
            pc_src_e_r,
            int_rd_e_r,
            stage_cycle_counter,
            processing_done,
            processing
        } <= 0;
        this_ready_o <= 1'b1;
    end
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            {     
                register_write_e_r,
                MemWriteE_r, 
                mem_read_E_r,
                RD_E_r,
                PCPlus4E_r,
                RD2_E_r,
                ResultE_r,
                WordSize_E_r,
                PCTarget_E_r,
                pc_src_e_r,
                int_rd_e_r,
                stage_cycle_counter,
                this_valid_o,
                processing
            } <= 0;
            this_ready_o <= 1'b1;
        end else if (processing) begin
            this_ready_o <= 1'b0;
            if(stage_cycle_counter < STAGE_CYCLE_REQ) begin //i.e. check if this_stage_done
                stage_cycle_counter <= stage_cycle_counter + 1;
            end
            else this_valid_o <= 1'b1;
        end
        if (this_valid_o && next_ready_i) begin
            register_write_e_r <= register_write_e; 
            MemWriteE_r <= MemWriteE; 
            mem_read_E_r <= mem_read_E;
            RD_E_r <= RD_E;
            PCPlus4E_r <= PCPlus4E; 
            RD2_E_r <= Src_B_interim; 
            ResultE_r <= ResultE;
            WordSize_E_r <= funct3_E;
            PCTarget_E_r <= pc_target_e_r;
            pc_src_e_r <= (ALUControlE === 6'b010000) || (ZeroE && BranchE); // If instructions is JAL, JALR or branch
            int_rd_e_r <= int_rd_e;
            this_ready_o <= 1'b1;
            this_valid_o <= 1'b1;
            stage_cycle_counter <= 2'b0;
            processing <=1'b0;
        end
        if (prev_valid_i) processing <= 1'b1;
        this_ready_o <= next_ready_i;
        
       
    end

    // Output Assignments
    //assign pc_src_e = (ALUControlE === 6'b010000) || (ZeroE && BranchE); //explicit check to avoid X values
    assign pc_src_e = pc_src_e_r;
    assign register_write_m = register_write_e_r;
    assign MemWriteM = MemWriteE_r;
    assign mem_read_M = mem_read_E_r;
    assign RD_M = RD_E_r;
    assign PCPlus4M = PCPlus4E_r;
    assign WriteDataM = RD2_E_r;
    assign Execute_ResultM = ResultE_r;
    assign pc_target_e = PCTarget_E_r;
    assign WordSize_M = WordSize_E_r;
    assign int_rd_m = int_rd_e_r;

endmodule


