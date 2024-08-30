`include "exceptions_codes.vh";
`include "csr_addresses.vh";

/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
this_stage_done (NULL bcz i always take one cycle) -> this flags indicates that the stage has done its job  
next_ready_i -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o = NULL && next_ready_i -> this flag indicates that the stage is ready to propagate its values
prev_ready_i (NULL) -> this flag indicates that the stage is ready to work on its data
*/


module decode_cycle(
    
        // Declaring I/O
        input clk, rst, flush, register_write_w, int_rd_w, is_csr_w_i, is_exp_i,
        input [3:0] mcause_code_i,
        input [4:0] rd_w,
        input [11:0] csr_address_w_i,
        input [31:0] instruction_d, pc_d, pc_plus_4_d, result_w, csr_value_w_i,
        input next_ready_i,
        output reg this_ready_o,
        input prev_ready_i,
        output reg this_valid_o,
        output register_write_e,BSrcE,MemWriteE,JtypeE,
        mem_read_E,BranchE, F_instruction_E, int_rd_e, is_csr_e_o,
        output [5:0] ALUControlE,
        output [4:0] FPUControlE,
        output [3:0] atomic_op_e_o,
        output [31:0] RS1_E, RS2_E, RS3_E, Imm_Ext_E,csr_value_e_o,
        output [4:0] forwarded_RS1_E, forwarded_RS2_E, RD_E, // For Forwarding
        output [31:0] PCE, PCPlus4E,
        output [2:0] funct3_E,
        output [11:0] csr_address_e_o,
        
        output reg exp_ill_instr_o
        
    );
    // Declare Interim Wires
    wire RegWriteD,BSrcD,MemWriteD,mem_read_D,BranchD,JtypeD, F_instruction_D, int_RD_D;
    wire [2:0] ImmSrcD;
    wire [5:0] ALUControlD;
    wire [4:0] FPUControlD;
    wire [3:0] atomic_op_d, mcause_code_d;
    wire [31:0] RS1_int, RS2_int, RS1_fp, RS2_fp, RS1_D, RS2_D, RS3_D, Imm_Ext_D, csr_value_d, int_writeback_result,
    csr_write_value, csr_read_address,csr_write_address;
    wire is_rs1_int, write_to_int_rf, is_csr_d, is_error_d;
    // Declaration of Interim Register
    reg RegWriteD_r,BSrcD_r,MemWriteD_r,mem_read_D_r,BranchD_r,JtypeD_r, F_instructionD_r,
     int_RD_D_r, is_csr_d_r;
    reg [5:0] ALUControlD_r;
    reg [4:0] FPUControlD_r;
    reg [3:0] atomic_op_d_r;
    reg [31:0] RS1_D_r, RS2_D_r, RS3_D_r, Imm_Ext_D_r, csr_value_e_r;
    reg [4:0] RD_D_r, forwarded_RS1_D_r, forwarded_RS2_D_r;
    reg [31:0] pc_d_r, pc_plus_4_d_r;
    reg [2:0] funct3_D_r;
    reg [11:0] csr_address_e_r;
    
    
    
    // Initiate the modules
    // Control Unit
    Control_Unit_Top control (
                            .Op(instruction_d[6:0]),
                            .RegWrite(RegWriteD),
                            .ImmSrc(ImmSrcD),
                            .BSrc(BSrcD),
                            .MemWrite(MemWriteD),
                            .Jtype(JtypeD),
                            .mem_read(mem_read_D),
                            .Branch(BranchD),
                            .funct3(instruction_d[14:12]),
                            .funct7(instruction_d[31:25]),
                            .funct5(instruction_d[24:20]),
                            .ALUControl(ALUControlD),
                            .f_instruction(F_instruction_D),
                            .FPUControl(FPUControlD),
                            .is_rs1_int(is_rs1_int),
                            .is_rd_int(int_RD_D),
                            .atomic_op(atomic_op_d),
                            .is_csr_o(is_csr_d)
                            );
                            
    assign RS1_D = is_rs1_int ? 
                        is_csr_d ? csr_value_d : 
                        RS1_int
                    : RS1_fp;
    assign RS2_D = F_instruction_D ? RS2_fp : 
                   is_csr_d ? RS1_int : // i need rs1 to be stored in rs2 bcz it can be swapped with immds
                   RS2_int; 
    assign write_to_int_rf = int_rd_w & register_write_w;
    assign write_to_fp_rf = ~int_rd_w & register_write_w;
    assign int_writeback_result = is_csr_w_i ? csr_value_w_i : result_w;
    assign csr_write_value = is_exp_i ? {27'b0, mcause_code_i}: 
                             write_to_fp_rf ? csr_value_w_i: 
                             result_w;
    assign csr_read_address = is_exp_i ? `mtvec_address : 
                             F_instruction_D ? `fcsr_address :
                             instruction_d[31:20];
    assign csr_write_address = is_exp_i ? `mcause_address : 
                               write_to_fp_rf ? `fcsr_address :
                               csr_address_w_i;
     wire exp_ill_instr_d;
     assign exp_ill_instr_d = F_instruction_D ? &FPUControlD : &ALUControlD;
    // Register File
    Integer_RF I_rf (
                        .clk(clk),
                        .rst(rst),
                        .WE3(write_to_int_rf),
                        .WD3(int_writeback_result),
                        .A1(instruction_d[19:15]),
                        .A2(instruction_d[24:20]),
                        .A3(rd_w),
                        .RS1(RS1_int),
                        .RS2(RS2_int)
                        );
                        
    // Floating Register File
    Floating_RF F_rf (
                        .clk(clk),
                        .rst(rst),
                        .WE4(write_to_fp_rf),
                        .WD4(result_w),
                        .A1(instruction_d[19:15]),
                        .A2(instruction_d[24:20]),
                        .A3(instruction_d[31:27]),
                        .A4(rd_w),
                        .RS1(RS1_fp),
                        .RS2(RS2_fp),
                        .RS3(RS3_D)
                        );
    
    // CSR Register File
    CSR_RF csr_rf (
                        .clk(clk),
                        .rst(rst),
                        .A1(csr_read_address), 
                        .RS1(csr_value_d),
                        
                        .WE2(is_csr_w_i | is_exp_i | write_to_fp_rf), 
                        .A2(csr_write_address),
                        .WD2(csr_write_value),
                        
                        .WEE3(is_exp_i), 
                        .WDE3(pc_d_r), // RS1 value I RF at writeback
                        .AE3(`mepc_address) // CSR value
                        
                        );
                        
   
    
    
    // Sign Extension
    Sign_Extend_Immediate extension (
                        .In(instruction_d),
                        .Imm_Ext(Imm_Ext_D),
                        .ImmSrc(ImmSrcD)
                        );
    reg flushing;
    // Declaring Register Logic
    always @(posedge flush) begin
        if(exp_ill_instr_o) begin
            exp_ill_instr_o <= exp_ill_instr_d;
            csr_value_e_r <= csr_value_d;
        end else begin
            exp_ill_instr_o <= 1'b0;
            csr_value_e_r <= 1'b0;
        end
        flushing <= 1'b1;
        
        reset_signals();
    end

    always @(posedge clk or negedge rst) begin
        if(flushing) flushing <= 1'b0;
        else if(!rst) begin
            csr_value_e_r <= 0;
            exp_ill_instr_o <= 0;
            reset_signals();
        end
        //decode is dones in a single cycle so i direcly propagate values.
        else if (prev_ready_i && this_ready_o) begin 
            RegWriteD_r <= RegWriteD;
            BSrcD_r <= BSrcD;
            MemWriteD_r <= MemWriteD;
            mem_read_D_r <= mem_read_D;
            BranchD_r <= BranchD;
            JtypeD_r <= JtypeD; 
            ALUControlD_r <= ALUControlD;
            RS1_D_r <= RS1_D; 
            RS2_D_r <= RS2_D; 
            RS3_D_r <= RS3_D;
            Imm_Ext_D_r <= Imm_Ext_D;
            csr_value_e_r <= csr_value_d;
            csr_address_e_r <= instruction_d[31:20];
            RD_D_r <= instruction_d[11:7];
            pc_d_r <= pc_d; 
            pc_plus_4_d_r <= pc_plus_4_d;
            forwarded_RS1_D_r <= instruction_d[19:15];
            forwarded_RS2_D_r <= instruction_d[24:20];
            funct3_D_r <= instruction_d[14:12];
            FPUControlD_r <= FPUControlD;
            atomic_op_d_r <= atomic_op_d;
            F_instructionD_r <= F_instruction_D;
            int_RD_D_r <= int_RD_D;
            is_csr_d_r <= is_csr_d;
            this_valid_o <= 1'b1;
            
            exp_ill_instr_o <= exp_ill_instr_d;
        end else this_valid_o <= 1'b0;
        this_ready_o <= next_ready_i;
    end

    // Output asssign statements
    assign register_write_e = RegWriteD_r;
    assign BSrcE = BSrcD_r;
    assign MemWriteE = MemWriteD_r;
    assign mem_read_E = mem_read_D_r;
    assign BranchE = BranchD_r;
    assign JtypeE = JtypeD_r; //CAUSED Jtype TO ACT CORRECTLY IN THE WAVEFORM, ALSO MAKES US ONLY FETCH TWO INSTRUCTIONS
    assign ALUControlE = ALUControlD_r;
    assign forwarded_RS1_E = forwarded_RS1_D_r;
    assign forwarded_RS2_E = forwarded_RS2_D_r;
    assign RS3_E = RS3_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RD_E = RD_D_r;
    assign PCE = pc_d_r;
    assign PCPlus4E = pc_plus_4_d_r;
    assign RS1_E = RS1_D_r;
    assign RS2_E = RS2_D_r;
    assign funct3_E = funct3_D_r;
    assign FPUControlE = FPUControlD_r;
    assign atomic_op_e_o = atomic_op_d_r; 
    assign F_instruction_E = F_instructionD_r;
    assign int_rd_e = int_RD_D_r;
    assign csr_address_e_o = csr_address_e_r;
    assign csr_value_e_o = csr_value_e_r;
    assign is_csr_e_o = is_csr_d_r;
    
    task reset_signals;
        begin
             {      
            RegWriteD_r,
            BSrcD_r,
            MemWriteD_r,
            mem_read_D_r,
            BranchD_r,
            JtypeD_r,    
            ALUControlD_r,
            RS1_D_r,
            RS2_D_r,
            RS3_D_r,
            Imm_Ext_D_r,
            RD_D_r,
            pc_d_r,
            pc_plus_4_d_r,
            forwarded_RS1_D_r,
            forwarded_RS2_D_r,
            funct3_D_r,
            F_instructionD_r,
            int_RD_D_r,
            FPUControlD_r,
            this_valid_o,
            atomic_op_d_r,
            csr_address_e_r,
            is_csr_d_r
        } <= 0;
        this_ready_o <= 1'b1;
        end
    endtask
    
    

endmodule
