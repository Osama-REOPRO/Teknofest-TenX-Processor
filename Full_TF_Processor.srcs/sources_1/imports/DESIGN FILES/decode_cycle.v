/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
this_stage_done (NULL bcz i always take one cycle) -> this flags indicates that the stage has done its job  
next_ready_i -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o = NULL && next_ready_i -> this flag indicates that the stage is ready to propagate its values
prev_ready_i (NULL) -> this flag indicates that the stage is ready to work on its data
*/


module decode_cycle(
    
        // Declaring I/O
        input clk, rst, flush, register_write_w,
        input [4:0] rd_w,
        input [31:0] instruction_d, pc_d, pc_plus_4_d, result_w, int_rd_w,
        input next_ready_i,
        output reg this_ready_o,
        input prev_ready_i,
        output reg this_valid_o,
        output register_write_e,BSrcE,MemWriteE,JtypeE,mem_read_E,BranchE, F_instruction_E, int_rd_e,
        output [5:0] ALUControlE,
        output [4:0] FPUControlE,
        output [31:0] RD1_E, RD2_E, RD3_E, Imm_Ext_E,
        output [4:0] RS1_E, RS2_E, RD_E, // For Forwarding
        output [31:0] PCE, PCPlus4E,
        output [2:0] funct3_E
        
    );
    // Declare Interim Wires
    wire RegWriteD,BSrcD,MemWriteD,mem_read_D,BranchD,JtypeD, F_instruction_D, int_RD_D;
    wire [2:0] ImmSrcD;
    wire [5:0] ALUControlD;
    wire [4:0] FPUControlD;
    wire [31:0] RD1_int, RD2_int, RD1_fp, RD2_fp, RD1_D, RD2_D, RD3_D, Imm_Ext_D;
    wire is_rs1_int;
    wire write_to_int_rf;
    // Declaration of Interim Register
    reg RegWriteD_r,BSrcD_r,MemWriteD_r,mem_read_D_r,BranchD_r,JtypeD_r, F_instructionD_r, int_RD_D_r;
    reg [5:0] ALUControlD_r;
    reg [5:0] FPUControlD_r;
    reg [31:0] RD1_D_r, RD2_D_r, RD3_D_r, Imm_Ext_D_r;
    reg [4:0] RD_D_r, RS1_D_r, RS2_D_r, RS3_D_r;
    reg [31:0] pc_d_r, pc_plus_4_d_r;
    reg [2:0] funct3_D_r;
    
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
                            .is_rd_int(int_RD_D)
                            );
                            
    assign RD1_D = is_rs1_int ? RD1_int : RD1_fp;
    assign RD2_D = F_instruction_D ? RD2_fp : RD2_int;
    assign write_to_int_rf = int_rd_w & register_write_w;
    assign write_to_fp_rf = !int_rd_w & register_write_w;

    // Register File
    Integer_RF I_rf (
                        .clk(clk),
                        .rst(rst),
                        .WE3(write_to_int_rf),
                        .WD3(result_w),
                        .A1(instruction_d[19:15]),
                        .A2(instruction_d[24:20]),
                        .A3(rd_w),
                        .RD1(RD1_int),
                        .RD2(RD2_int)
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
                        .RD1(RD1_fp),
                        .RD2(RD2_fp),
                        .RD3(RD3_D)
                        );
    
    // Sign Extension
    Sign_Extend_Immediate extension (
                        .In(instruction_d),
                        .Imm_Ext(Imm_Ext_D),
                        .ImmSrc(ImmSrcD)
                        );

    // Declaring Register Logic
    always @(posedge flush) begin
        {      
            RegWriteD_r,
            BSrcD_r,
            MemWriteD_r,
            mem_read_D_r,
            BranchD_r,
            JtypeD_r,    
            ALUControlD_r,
            RD1_D_r,
            RD2_D_r,
            RD3_D_r,
            Imm_Ext_D_r,
            RD_D_r,
            pc_d_r,
            pc_plus_4_d_r,
            RS1_D_r,
            RS2_D_r,
            funct3_D_r,
            F_instructionD_r,
            int_RD_D_r,
            FPUControlD_r,
            this_valid_o
        } <= 0;
        this_ready_o <= 1'b1;

    end
    always @(posedge clk or negedge rst) begin
        if(!rst) begin
            {      
                RegWriteD_r,
                BSrcD_r,
                MemWriteD_r,
                mem_read_D_r,
                BranchD_r,
                JtypeD_r,    
                ALUControlD_r,
                RD1_D_r,
                RD2_D_r,
                RD3_D_r,
                Imm_Ext_D_r,
                RD_D_r,
                pc_d_r,
                pc_plus_4_d_r,
                RS1_D_r,
                RS2_D_r,
                funct3_D_r,
                F_instructionD_r,
                int_RD_D_r,
                FPUControlD_r,
                this_valid_o
            } <= 0;
            this_ready_o <= 1'b1;
        //decode is dones in a single cycle so i direcly propagate values.
        end else if (prev_ready_i && next_ready_i) begin 
            RegWriteD_r <= RegWriteD;
            BSrcD_r <= BSrcD;
            MemWriteD_r <= MemWriteD;
            mem_read_D_r <= mem_read_D;
            BranchD_r <= BranchD;
            JtypeD_r <= JtypeD; 
            ALUControlD_r <= ALUControlD;
            RD1_D_r <= RD1_D; 
            RD2_D_r <= RD2_D; 
            RD3_D_r <= RD3_D;
            Imm_Ext_D_r <= Imm_Ext_D;
            RD_D_r <= instruction_d[11:7];
            pc_d_r <= pc_d; 
            pc_plus_4_d_r <= pc_plus_4_d;
            RS1_D_r <= instruction_d[19:15];
            RS2_D_r <= instruction_d[24:20];
            funct3_D_r <= instruction_d[14:12];
            FPUControlD_r <= FPUControlD;
            F_instructionD_r <= F_instruction_D;
            int_RD_D_r <= int_RD_D;
            this_valid_o <= 1'b1;
        end
        else this_valid_o <=1'b0;
        
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
    assign RD1_E = RD1_D_r;
    assign RD2_E = RD2_D_r;
    assign RD3_E = RD3_D_r;
    assign Imm_Ext_E = Imm_Ext_D_r;
    assign RD_E = RD_D_r;
    assign PCE = pc_d_r;
    assign PCPlus4E = pc_plus_4_d_r;
    assign RS1_E = RS1_D_r;
    assign RS2_E = RS2_D_r;
    assign funct3_E = funct3_D_r;
    assign FPUControlE = FPUControlD_r;
    assign F_instruction_E = F_instructionD_r;
    assign int_rd_e = int_RD_D_r;

endmodule
