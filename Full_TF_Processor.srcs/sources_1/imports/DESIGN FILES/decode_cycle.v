/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
this_stage_done (NULL bcz i always take one cycle) -> this flags indicates that the stage has done its job  
next_ready_i -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o = NULL && next_ready_i -> this flag indicates that the stage is ready to propagate its values
prev_ready_i (NULL) -> this flag indicates that the stage is ready to work on its data
*/


module decode_cycle(
    
        // Declaring I/O
        input clk, rst, flush, register_write_w, int_rd_w,
        input [4:0] rd_w,
        input [11:0] csr_address_w_i,
        input [31:0] instruction_d, pc_d, pc_plus_4_d, result_w, csr_value_w_i,
        input next_ready_i,
        output reg this_ready_o,
        input prev_ready_i,
        output reg this_valid_o,
        output register_write_e,BSrcE,MemWriteE,JtypeE,mem_read_E,BranchE, F_instruction_E, int_rd_e,
        output [5:0] ALUControlE,
        output [4:0] FPUControlE,
        output [3:0] atomic_op_e_o, csr_value_e_o,
        output [31:0] RS1_E, RS2_E, RS3_E, Imm_Ext_E,
        output [4:0] forwarded_RS1_E, forwarded_RS2_E, RD_E, // For Forwarding
        output [31:0] PCE, PCPlus4E,
        output [2:0] funct3_E,
        output [11:0] csr_address_e_o
        
    );
    // Declare Interim Wires
    wire RegWriteD,BSrcD,MemWriteD,mem_read_D,BranchD,JtypeD, F_instruction_D, int_RD_D, int_writeback_result;
    wire [2:0] ImmSrcD;
    wire [5:0] ALUControlD;
    wire [4:0] FPUControlD;
    wire [3:0] atomic_op_d;
    wire [31:0] RS1_int, RS2_int, RS1_fp, RS2_fp, RS1_D, RS2_D, RS3_D, Imm_Ext_D, csr_value_d;
    wire is_rs1_int;
    wire write_to_int_rf, is_csr_d;
    // Declaration of Interim Register
    reg RegWriteD_r,BSrcD_r,MemWriteD_r,mem_read_D_r,BranchD_r,JtypeD_r, F_instructionD_r, int_RD_D_r;
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
                   is_csr_d ? RS1_int : RS2_int; // i need rs1 to be stored in rs2 bcz it can be swapped with immds
    assign write_to_int_rf = int_rd_w & register_write_w;
    assign write_to_fp_rf = !int_rd_w & register_write_w;
    assign int_writeback_result = is_csr_w_i ? csr_value_w_i : result_w;

    // Register File
    Integer_RF I_rf (
                        .clk(clk),
                        .rst(rst),
                        .WE3(write_to_int_rf),
                        .WD3(writeback_result),
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
                        .WE2(is_csr_w_i), // new: to 
                        .WD2(result_w), // RS1 value I RF at writeback
                        .A1(instruction_d[31:20]), // CSR value
                        .A2(csr_address_w_i), // CSR address
                        .RS1(csr_value_d)
                        );
                        
   
    
    
    // Sign Extension
    Sign_Extend_Immediate extension (
                        .In(instruction_d),
                        .Imm_Ext(Imm_Ext_D),
                        .ImmSrc(ImmSrcD)
                        );

    // Declaring Register Logic
    always @(posedge flush) reset_signals();
    always @(posedge clk or negedge rst) begin
        if(!rst) reset_signals();
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
            this_valid_o <= 1'b1;
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
            csr_value_e_r
        } <= 0;
        this_ready_o <= 1'b1;
        end
    endtask
    
    

endmodule
