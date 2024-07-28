//`timescale 1ns / 1ps
module core_memory_interface(
		input clk_i, rst_i,
		// core signals
			// todo
		// external signals
		// instruction mem operations
		input   		  mem_instr_we_o,
		input  [31:0] mem_instr_adrs_o,
		input  [31:0] mem_instr_wdata_o,
		input  [1:0]  mem_instr_wsize_o,
		input   		  mem_instr_req_o,
		output 		  mem_instr_done_i,
		output [31:0] mem_instr_rdata_i,
		// data mem operations
		input   		  mem_data_we_o,
		input  [31:0] mem_data_adrs_o,
		input  [31:0] mem_data_wdata_o,
		input  [1:0]  mem_data_wsize_o,
		input   		  mem_data_req_o,
		output 		  mem_data_done_i,
		output [31:0] mem_data_rdata_i
    );
    //pipeline_top
endmodule