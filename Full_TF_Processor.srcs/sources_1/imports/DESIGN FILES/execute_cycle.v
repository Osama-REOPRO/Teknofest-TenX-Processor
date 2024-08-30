/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
this_stage_done -> this flags indicates that the stage has done its job  
next_ready_i -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o = this_stage_done && next_ready_i -> this flag indicates that the stage is ready to propagate its values
prev_ready_i -> this flag indicates that the stage is ready to work on its data
*/

module execute_cycle
# (parameter STAGE_CYCLE_REQ = 2'b01)
(
    // Declaration I/Os
    input clk, rst, flush, JtypeE, register_write_e,
    BSrcE, MemWriteE,mem_read_E,BranchE, F_instruction_E, int_rd_e, is_csr_e_i,
    input [5:0] ALUControlE,
    input [4:0] FPUControlE,
    input [31:0] RS1_E, RS2_E, RS3_E, Imm_Ext_E,
    input [4:0] RD_E,
    input [31:0] PCE, PCPlus4E,result_w, csr_value_e_i, csr_address_e_i,
    input [1:0] ForwardA_E, ForwardB_E,
    input [2:0] funct3_E,

    output pc_src_e, register_write_m, MemWriteM, mem_read_M, int_rd_m, is_csr_m_o,
    output [4:0] RD_M,
    output [3:0] atomic_op_m_o,
    output [31:0] PCPlus4M, WriteDataM, Execute_ResultM, pc_target_e, csr_value_m_o, csr_address_m_o,
    
    output [2:0] WordSize_M,

    input [3:0] atomic_op_e_i,

    input next_ready_i,
    output reg this_ready_o,
    input prev_valid_i,
    output reg this_valid_o,
    
    output reg exp_ld_mis_o,
    output reg exp_st_mis_o,
    output reg exp_instr_addr_mis_o
     
);
    // Declaration of Interim Wires
    wire [31:0] Src_A, Src_B_interim, Src_B, pc_target_e_r;
    wire [31:0] ResultE;
    wire ZeroE;
    wire [4:0] fpu_flags_e;
    wire fpu_ready_e;
    reg fpu_valid_e;

    // Declaration of Register
    reg register_write_e_r, MemWriteE_r, mem_read_E_r ,pc_src_e_r, int_rd_e_r, is_csr_e_r;
    reg [4:0] RD_E_r;
    reg [3:0] atomic_op_e_r;
    reg [31:0] PCPlus4E_r, RS2_E_r, ResultE_r, PCTarget_E_r, csr_value_e_r;
    reg [11:0] csr_address_e_r;
    reg [2:0] WordSize_E_r;
    
    
    //Coordination wires
    reg stage_busy;
    reg processing_done; // = stage_cycle_counter < STAGE_CYCLE_REQ
    reg [1:0] stage_cycle_counter; //3
    // Declaration of Modules
    
    // 3 by 1 Mux for Forwarding Source A
    Mux_3_by_1 srca_mux (
                        .a_i(RS1_E),
                        .b_i(result_w),
                        .c_i(Execute_ResultM),
                        .s_i(ForwardA_E),
                        .d_o(Src_A)
                        );

    // 3 by 1 Mux for Forwarding Source B
    Mux_3_by_1 srcb_mux (
                        .a_i(RS2_E),
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
    wire [31:0] FPU_Result;
    wire [31:0] ALU_Result;
    
    
    FPU_top fpu
    (
        .clk_i(clk),
        .rst_i(rst), 
        .rs1_i(Src_A),
        .rs2_i(Src_B),
        .rs3_i(RS3_E),
        .fpu_control_i(FPUControlE),
        .fcsr_rmode_i(csr_value_e_i[7:5]),
        .isntr_rmode_i(funct3_E),
        .fpu_enable_i(F_instruction_E&fpu_valid_e),
        .fpu_result_o(FPU_Result),
        .fpu_flags_o(fpu_flags_e),
        .fpu_ready_o(fpu_ready_e)
    );
    
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
   
   
    wire mem_half_addr_misalign, mem_word_addr_misalign, mem_misalign, div_by_four;
    wire instruction_misalign, load_misalign, store_amo_misalign;
     wire jump_instr_e;
     assign jump_instr_e = ALUControlE === `ALU_JUMPS;
     assign mem_half_addr_misalign = funct3_E[0] & ResultE[0];
     assign not_div_by_four = (&ResultE[1:0]);
     assign mem_word_addr_misalign = funct3_E[1] & not_div_by_four;
     assign mem_misalign = (mem_half_addr_misalign|mem_word_addr_misalign);
   
     //assign exp_ld_mis_o = mem_read_E & mem_misalign;
     //assign exp_st_mis_o = MemWriteE & mem_misalign;
     //assign exp_instr_addr_mis_o = (jump_instr_e|BranchE) & not_div_by_four;
    
    
    // Adder
    PC_Adder branch_adder (
            .a_i( (JtypeE | BranchE) ? PCE: Src_A), // if Jtype (JAL) or branch, PC, else (JALR), RS1
            .b_i(Imm_Ext_E),
            .c_o(pc_target_e_r)
            );
    // Register Logic
    reg flushing;
    always @(posedge flush) begin
        exp_ld_mis_o <= mem_read_E & mem_misalign;
        exp_st_mis_o <= MemWriteE & mem_misalign;
        exp_instr_addr_mis_o <= (jump_instr_e|BranchE) & not_div_by_four;
        flushing <= 1'b1;
        reset_signals();
    end
    always @(posedge clk or negedge rst) begin
        if(flushing) flushing <= 1'b0;
        else if(!rst) begin 
            exp_ld_mis_o <= 0;
            exp_st_mis_o <= 0;
            exp_instr_addr_mis_o <= 0;
            reset_signals();
        end else begin
            if (processing_done &&  this_ready_o) begin                
                register_write_e_r <= register_write_e; 
                MemWriteE_r <= MemWriteE; 
                mem_read_E_r <= mem_read_E;
                RD_E_r <= RD_E;
                atomic_op_e_r <= atomic_op_e_i;
                csr_value_e_r <= F_instruction_E ? {csr_value_e_i[31:8], fpu_flags_e} : csr_value_e_i;
                csr_address_e_r <= csr_address_e_i;
                PCPlus4E_r <= PCPlus4E; 
                RS2_E_r <= Src_B_interim; 
                ResultE_r <= ResultE;
                WordSize_E_r <= funct3_E;
                PCTarget_E_r <= pc_target_e_r;
                pc_src_e_r <= (jump_instr_e) || (ZeroE && BranchE); // If instructions is JAL, JALR or branch
                int_rd_e_r <= int_rd_e;
                is_csr_e_r <= is_csr_e_i;
                
                this_ready_o <= 1'b1;
                this_valid_o <= 1'b1;
                stage_cycle_counter <= 2'b0;
                stage_busy <=1'b0;
                processing_done <= 1'b0;
            end else if (stage_busy) begin
                this_valid_o <= 1'b0;
                if(stage_cycle_counter < STAGE_CYCLE_REQ) begin
                    stage_cycle_counter <= stage_cycle_counter + 1;
                    this_ready_o <= 1'b0;
                end else if (fpu_ready_e) begin 
                    this_ready_o <= next_ready_i;
                    processing_done <= 1'b1;
                    fpu_valid_e <= 1'b0;
                end
            end else if (prev_valid_i) begin 
                stage_busy <= 1'b1;
                fpu_valid_e <= 1'b1;
            end
        end
    end

    // Output Assignments
    //assign pc_src_e = (ALUControlE === 6'b010000) || (ZeroE && BranchE); //explicit check to avoid X values
    assign pc_src_e = pc_src_e_r;
    assign register_write_m = register_write_e_r;
    assign MemWriteM = MemWriteE_r;
    assign mem_read_M = mem_read_E_r;
    assign RD_M = RD_E_r;
    assign atomic_op_m_o = atomic_op_e_r;
    assign PCPlus4M = PCPlus4E_r;
    assign WriteDataM = RS2_E_r;
    assign Execute_ResultM = ResultE_r;
    assign pc_target_e = PCTarget_E_r;
    assign WordSize_M = WordSize_E_r;
    assign int_rd_m = int_rd_e_r;
    assign csr_value_m_o = csr_value_e_r;
    assign csr_address_m_o = csr_address_e_r;
    assign is_csr_m_o = is_csr_e_r;
    
    task reset_signals;
        begin
            {     
                register_write_e_r,
                MemWriteE_r, 
                mem_read_E_r,
                RD_E_r,
                PCPlus4E_r,
                RS2_E_r,
                ResultE_r,
                WordSize_E_r,
                PCTarget_E_r,
                pc_src_e_r,
                int_rd_e_r,
                stage_cycle_counter,
                this_valid_o,
                stage_busy,
                atomic_op_e_r,
                csr_value_e_r,
                csr_address_e_r,
                is_csr_e_r,
                processing_done,
                fpu_valid_e
            } <= 0;
            this_ready_o <= 1'b1;
        end
    endtask

endmodule


