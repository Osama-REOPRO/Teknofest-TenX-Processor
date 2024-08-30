/*
NULL MEANS THE FLAG IS NOT NEEDED IN THIS STAGE
FULL MEAN THERE IS AN ALREADY DEFINED SIGNALS FOR THAT FLAG
this_stage_done (FULL) -> this flags indicates that the stage has done its job  
next_ready_i (NULL bcz next is always ready) -> this flag indicates that the stage can propagate data to the next stage  
this_ready_o (FULL) = this_stage_done && NULL -> this flag indicates that the stage is ready to propagate its values
prev_ready_i -> this flag indicates that the stage is ready to work on its data
*/


`include "atomic_ops.vh"

module memory_cycle
(
    // Declaration of I/Os
    input clk, rst, flush, register_write_m, int_rd_m, MemWriteM, mem_read_M, is_csr_m_i,
    input [4:0] RD_M,
    input [3:0] atomic_op_m_i,
    input [31:0] PCPlus4M, Execute_ResultM, WriteDataM, csr_value_m_i, csr_address_m_i,
    input [2:0] WordSize_M, /// byte: 00, half: 01, word: 10, unsignedbyte: 11, unsignedhalf: 100;

    output register_write_w, mem_read_w, int_rd_w, is_csr_w_o,
    output [4:0] rd_w,
    output [31:0] PCPlus4W, Execute_ResultW, ReadDataW, csr_value_w_o, csr_address_w_o,
    
    
    // mem signals 
	output reg			mem_data_we_o,
  	output reg [31:0] mem_data_adrs_o,
	output reg [31:0]	mem_data_wdata_o,
	output reg [1:0] 	mem_data_wsize_o, // 0>byte, 01>half, 10>word
  	output reg 			mem_data_req_o,
  	input 				mem_data_done_i, //this_stage_done
  	input 	  [31:0]	mem_data_rdata_i,
  	output reg [3:0] mem_data_atomic_operation_o,
  	
  	
    input prev_valid_i,
    output reg this_ready_o
    
    
//    output exp_ld_acc_fault_o,
//    output exp_st_acc_fault_o
    
    );
    // Declaration of Interim Wires
    //wire [31:0] ReadDataM;

    // Declaration of Interim Registers
    reg [31:0] reservation_address;
    reg register_write_m_r, mem_read_M_r, int_rd_m_r, is_csr_m_r;
    reg [4:0] RD_M_r;
    reg [11:0] csr_address_m_r;
    reg [31:0] PCPlus4M_r, Execute_ResultM_r, ReadDataM_r, csr_value_m_r;
    
    //FOR ATOMICS
    //Execute_ResultM_r = RS1, 
    // RS2_ATOMIC = RS2,
    reg processing;
    
    reg [1:0] mem_state;	
    localparam [1:0]      mem_init_st   = 0, //00
					      mem_busy_st   = 1, //01
					       mem_finish_st = 2;//10


   // Memory Stage Register Logic
   //always @(posedge flush) reset_signals();
	always @(posedge clk or negedge rst) begin
		if(!rst | flush) reset_signals();
        else begin
            if (processing) begin 
                if(atomic_op_m_i === `store_conditional_aop && Execute_ResultM != reservation_address) begin
                    ReadDataM_r <= 1'b1;
                    latch_registers();
                    
                end
                    
                else if(mem_read_M || MemWriteM) begin
                    case(mem_state)
                        mem_init_st: begin //0
                            if (!mem_data_done_i && !mem_data_req_o) begin //useless checks
                                mem_data_req_o 	<= 1'b1;
                                mem_data_adrs_o 	<= Execute_ResultM; // RS1
                                mem_data_atomic_operation_o <=  atomic_op_m_i;
                                mem_data_we_o 		<= MemWriteM; //if write 1, if read 0
                                mem_data_wsize_o 	<= WordSize_M[1:0];
                                mem_data_wdata_o  <= WriteDataM; // FOR ATOMICS THIS RS2
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

                                if (atomic_op_m_i === `store_conditional_aop)
                                    ReadDataM_r <= 1'b0;
                                else begin
                                     if(WordSize_M[1]) //word
                                        ReadDataM_r <= mem_data_rdata_i;
                                    else if(WordSize_M[2]) begin // if unsigned
                                        ReadDataM_r <= mem_data_rdata_i >> (WordSize_M[0] ? 16 : 24); //hlaf or byte
                                    end else begin // is signed
                                        if(WordSize_M[0]) // if is half
                                            ReadDataM_r <= { {16{mem_data_rdata_i[15]}}, mem_data_rdata_i[15:0]};
                                        else //is byte
                                            ReadDataM_r <= { {24{mem_data_rdata_i[7]}}, mem_data_rdata_i[7:0] };
                                    end 
                                    if (atomic_op_m_i === `load_reserved_aop)
                                        reservation_address <= Execute_ResultM;
                                    
                                end
                                latch_registers();  
                            end
                        end	
                    endcase
                end
                else latch_registers();
            end else if(prev_valid_i) processing <=1'b1; 
		end
	end
    
    
    task latch_registers;
        begin
           register_write_m_r <= register_write_m; 
           mem_read_M_r <= mem_read_M;
           RD_M_r <= RD_M;
           PCPlus4M_r <= PCPlus4M;
           Execute_ResultM_r <= Execute_ResultM; 
           //ReadDataM_r <= ReadDataM;
           csr_value_m_r <= csr_value_m_i;
           csr_address_m_r <= csr_address_m_i;
           int_rd_m_r <= int_rd_m;
           mem_state <= mem_init_st;    
           is_csr_m_r <= is_csr_m_i; 
           this_ready_o <= 1'b1;        
           processing <= 1'b0;
           
       end
    endtask
    
        
    task reset_signals;
        begin
            { 
                register_write_m_r,
                mem_read_M_r,
                RD_M_r,
                PCPlus4M_r,
                Execute_ResultM_r,
                ReadDataM_r,
                int_rd_m_r,
                csr_value_m_r,
                csr_address_m_r,
                mem_state,
                mem_data_we_o,
                mem_data_adrs_o,
                mem_data_wdata_o,
                mem_data_wsize_o,
                mem_data_req_o,
                mem_data_atomic_operation_o,
                is_csr_m_r,
                processing,
                reservation_address
            } <= 0;
            this_ready_o <= 1'b1;
       end
    endtask
    
    // Declaration of output assignments
    assign register_write_w = register_write_m_r;
    assign mem_read_w = mem_read_M_r;
    assign rd_w = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign Execute_ResultW = Execute_ResultM_r;
    assign ReadDataW = ReadDataM_r;
    assign int_rd_w = int_rd_m_r;
    assign csr_value_w_o = csr_value_m_r;
    assign csr_address_w_o = csr_address_m_r;
    assign is_csr_w_o = is_csr_m_r;
endmodule