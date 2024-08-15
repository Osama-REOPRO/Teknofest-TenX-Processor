/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
FULL MEAN THERE IS AN ALREADY DEFINED SIGNALS FOR THAT FLAG
this_stage_done (FULL) -> this flags indicates that the stage has done its job  
next_ready_i (NULL bcz next is always ready) -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o (FULL) = this_stage_done && NULL -> this flag indicates that the stage is ready to propagate its values
prev_ready_i -> this flag indicates that the stage is ready to work on its data
*/

module memory_cycle
(
    // Declaration of I/Os
    input clk, rst, flush, register_write_m, int_rd_m, MemWriteM, mem_read_M,
    input [4:0] RD_M, 
    input [31:0] PCPlus4M, Execute_ResultM, WriteDataM,
    input [2:0] WordSize_M, /// byte: 00, half: 01, word: 10, unsignedbyte: 11, unsignedhalf: 100;

    output register_write_w, mem_read_W, int_rd_w, 
    output [4:0] rd_w,
    output [31:0] PCPlus4W, Execute_ResultW, ReadDataW,
    
    
    // mem signals 
	output reg			mem_data_we_o,
  	output reg [31:0] mem_data_adrs_o,
	output reg [31:0]	mem_data_wdata_o,
	output reg [1:0] 	mem_data_wsize_o, // 0>byte, 01>half, 10>word
  	output reg 			mem_data_req_o,
  	input 				mem_data_done_i, //this_stage_done
  	input 	  [31:0]	mem_data_rdata_i,
    input prev_valid_i,
    output reg this_ready_o
    );
    
    // Declaration of Interim Wires
    wire [31:0] ReadDataM;

    // Declaration of Interim Registers
    reg register_write_m_r, mem_read_M_r, int_rd_m_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, Execute_ResultM_r, ReadDataM_r;

   // Memory Stage Register Logic
	always @(posedge flush) begin
        register_write_m_r <= 1'b0; 
        mem_read_M_r <= 1'b0;
        RD_M_r <= 5'h00;
        PCPlus4M_r <= 32'h00000000; 
        Execute_ResultM_r <= 32'h00000000; 
        ReadDataM_r <= 32'h00000000;
        int_rd_m_r <= 1'b0;
        this_ready_o <= 1'b1;  // this_ready_o <= next_is_always_ready and prev is flushed.

	end 
   
    
    reg [1:0] mem_state;	
    localparam      mem_check_st  = 0, //00
                    mem_init_st   = 1, //01
					mem_busy_st   = 2, //10
					mem_finish_st = 3;//11
	 
	always @(posedge clk or negedge rst) begin
		if(!rst) begin

			{ 
                register_write_m_r,
                mem_read_M_r,
                RD_M_r,
                PCPlus4M_r,
                Execute_ResultM_r,
                ReadDataM_r,
                int_rd_m_r,
                mem_state,
			    mem_data_we_o,
				mem_data_adrs_o,
				mem_data_wdata_o,
				mem_data_wsize_o,
				mem_data_req_o
				} <= 0;
            this_ready_o <= 1'b1;
		end else if (prev_valid_i) begin
		    if(mem_read_M || MemWriteM) begin
                case(mem_state)
                    mem_init_st: begin //0
                        if (!mem_data_done_i && !mem_data_req_o) begin
                            mem_data_req_o 	<= 1'b1;
                            mem_data_adrs_o 	<= Execute_ResultM;
                            mem_data_we_o 		<= MemWriteM; //if write 1, if read 0
                            mem_data_wsize_o 	<= WordSize_M[1:0]; //ignored on read
                            mem_data_wdata_o  <= WriteDataM[1:0]; // ignored on read
                            mem_state <= mem_busy_st;
                            this_ready_o <= 1'b0;
                        end
                    end
                    
                    mem_busy_st: begin //1
                        if (mem_data_done_i) begin
                            mem_data_req_o <= 1'b0;
    
                            mem_state <= mem_finish_st;
                        end
                    end
                    
                    mem_finish_st: begin //2
                        if (!mem_data_done_i) begin
                           ReadDataM_r <= mem_data_rdata_i; //ignored for writes
                            latch_registers();  
                            this_ready_o <= 1'b1;        
                        end
                    end	
                endcase
            end
            else latch_registers();
		end
	end
    
    
    task latch_registers;
        begin
           register_write_m_r <= register_write_m; 
           mem_read_M_r <= mem_read_M;
           RD_M_r <= RD_M;
           PCPlus4M_r <= PCPlus4M;
           Execute_ResultM_r <= Execute_ResultM; 
           ReadDataM_r <= ReadDataM;
           int_rd_m_r <= int_rd_m;
           mem_state <= mem_init_st;      
       end
    endtask
    
    // Declaration of output assignments
    assign register_write_w = register_write_m_r;
    assign mem_read_W = mem_read_M_r;
    assign rd_w = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign Execute_ResultW = Execute_ResultM_r;
    assign ReadDataW = ReadDataM_r;
    assign int_rd_w = int_rd_m_r;
endmodule