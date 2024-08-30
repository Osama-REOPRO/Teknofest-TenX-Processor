/*
mem_instr_done_i -> this flags indicates that the stage has done its job
decode_done -> this flag indicated that the stage can propagate data to the next state
mem_instr_done_i && exectue_done -> this flag indicated that the stage is ready to be used
*/
module fetch_cycle
#(parameter PC_START_ADRS = 32'h80000000 )

(
    // Declare input & outputs
        input clk_i, rst_i, flush_i,
        input [31:0] pc_error_i,
        input is_exp_i,
        output reg this_ready_o,
        input next_ready_i,
        
        input mem_instr_done_i, 
        input [31:0] mem_instr_rdata_i,
        output reg mem_instr_req_o,
        output reg [31:0] mem_instr_adrs_o,
        
        input pc_src_e_i,
        input [31:0] pc_target_e_i,
        output [31:0] instruction_d_o,
        output [31:0] pc_d_o, pc_plus_4_d_o
        
        );

//    assign exp_instr_acc_fault_o = 0;
	 // localparam pc_start_adrs = 32'h80000000;

    // Declaring interim wires
    wire [31:0] pc_next, pc_f_next, pc_f, pc_plus_4_f;
    //wire [31:0] InstrF;

    // Declaration of Register
    reg [31:0] instruction_f_r;
    reg [31:0] pc_f_r, pc_plus_4_f_r;


    // Initiation of Modules
    // Declare PC Mux
    Mux_2_by_1 PC_MUX (
                .a_i(pc_plus_4_f),
                .b_i(pc_target_e_i),
                .s_i(pc_src_e_i),
                .c_o(pc_next)
                );

    // Declare PC Mux
    Mux_2_by_1 pc_error_mux (
                .a_i(pc_next),
                .b_i(pc_error_i),
                .s_i(is_exp_i),
                .c_o(pc_f_next)
                );


    // Declare PC Counter
    reg increment_pc;
    wire pc_incremented;
    
    PC_Module
     #(.START_ADRS(PC_START_ADRS))
    Program_Counter (
                .clk_i(clk_i),
                .rst_i(rst_i),
                .flush_i(flush_i),
                .pc_next_i(pc_f_next),
                .pc_o(pc_f),
                .increment_pc_i(increment_pc),
                .pc_incremented_o(pc_incremented)
                );

    // Declare PC adder
    PC_Adder PC_adder (
                .a_i(pc_f),
                .b_i(32'h00000004),
                .c_o(pc_plus_4_f)
                );

   // Fetch Cycle Register Logic state machine
   reg [1:0] mem_state;
    localparam [1:0] mem_init_st   = 0,
	                 mem_busy_st   = 1,
	                 mem_finish_st = 2,
	                 pc_increment_st = 3;
    
    
    reg flushing;
    always @(posedge flush_i) begin
        increment_pc <= 1'b1;
        mem_state <= 3;
        reset_signals();
        flushing <= 1'b1;
    end   
   
	
	always @(posedge clk_i or negedge rst_i) begin
        if(flushing) flushing <= 1'b0;
        else if(!rst_i) begin 
            increment_pc <= 0;
            mem_state <= 0;
            reset_signals();
         end
        else begin
        		case(mem_state)
        			mem_init_st: begin
        				if (!mem_instr_done_i && !mem_instr_req_o) begin //check is useless ?
        				    this_ready_o <= 1'b0;
							mem_instr_req_o <= 1'b1;
							mem_instr_adrs_o <= pc_f; // PC address
							increment_pc <= 1'b0;
							
							mem_state <= mem_busy_st;
        				end
        			end
        			mem_busy_st: begin
						if (mem_instr_done_i) begin
							mem_instr_req_o <= 1'b0;
							mem_state <= mem_finish_st;
						end
        			end
        			mem_finish_st: begin
						if (!mem_instr_done_i && next_ready_i) begin
							instruction_f_r <= mem_instr_rdata_i;
							pc_f_r <= pc_f;
							pc_plus_4_f_r <= pc_plus_4_f;
							increment_pc <= 1'b1;
							
							mem_state <= pc_increment_st;
							this_ready_o <= 1'b1;
							//this_valid_o <= 1'b1;
						end
        			end
        			pc_increment_st: begin
                        if (pc_incremented) mem_state <= mem_init_st;
        			end
        		endcase
        end
	end

    // Assigning Registers Value to the Output port
    assign  instruction_d_o = instruction_f_r;
    assign  pc_d_o = pc_f_r;
    assign  pc_plus_4_d_o = pc_plus_4_f_r;
    
    task reset_signals;
        begin
            mem_instr_adrs_o <= PC_START_ADRS;
            {
                instruction_f_r,
                pc_f_r,
                pc_plus_4_f_r,
                mem_instr_req_o,
                this_ready_o
            } <= 0;
        end
    endtask

endmodule
