//`timescale 1us / 1ns

`include "cache_ops.vh"

module memory_controller(
	input clk_i, rst_i,
	// -------------------- core signals
	// instruction mem operations
	input   		  instr_we_i,
	input  [31:0] instr_adrs_i,
	input  [31:0] instr_wdata_i,
	input  [1:0]  instr_wsize_i, // 0:byte, 1:half, 2:word
	input   		  instr_req_i,
	output 		  instr_done_o,
	output [31:0] instr_rdata_o,
	// data mem operations
	input   		  data_we_i,
	input  [31:0] data_adrs_i,
	input  [31:0] data_wdata_i,
	input  [1:0]  data_wsize_i, // 0:byte, 1:half, 2:word
	input     	  data_req_i,
	output	  	  data_done_o,
	output [31:0] data_rdata_o,
	// -------------------- main mem signals
	output 		   main_we_o,
	output [31:0]  main_adrs_o,
	output [127:0] main_wdata_o,
	output [15:0]  main_wstrb_o, // careful, strb not size
	output 		   main_req_o,
	input      	 	main_done_i,
	input  [127:0] main_rdata_i,
	// wishbone
	output [31:0] WB_ADR_O,
	input	 [31:0] WB_DAT_I,
	output [31:0] WB_DAT_O,
	output 		  WB_WE_O,
	output 		  WB_CYC_O,
	output 		  WB_STB_O,
	input 		  WB_ACK_I,
	input 		  WB_RTY_I
);

// todo: replace with final params
localparam C_instr = 32; // capacity (total words)
localparam b_instr = 4; // block size (words per block)
localparam N_instr = 1; // degree of associativity (blocks per set)

localparam C_data = 32; // capacity (total words)
localparam b_data = 4; // block size (words per block)
localparam N_data = 2; // degree of associativity (blocks per set)

// memory maps
localparam adrs_main_start = 32'h80000000;
localparam adrs_main_end 	= 32'hffffffff;
localparam adrs_uart_start = 32'h20000000;
localparam adrs_uart_end 	= 32'h2000000c + 32'd4;

// memory map checks
wire adrs_instr_is_uart = (instr_adrs_i >= adrs_uart_start) && (instr_adrs_i <= adrs_uart_end);
wire adrs_instr_is_interface = instr_adrs_i > adrs_uart_end;
wire adrs_instr_is_main = (instr_adrs_i >= adrs_main_start) && (instr_adrs_i <= adrs_main_end);

wire adrs_data_is_uart = (data_adrs_i >= adrs_uart_start) && (data_adrs_i <= adrs_uart_end);
wire adrs_data_is_interface = data_adrs_i > adrs_uart_end;
wire adrs_data_is_main = (data_adrs_i >= adrs_main_start) && (data_adrs_i <= adrs_main_end);

wire adrs_is_uart = adrs_instr_is_uart || adrs_data_is_uart;

// ----------------- intermediate signals
// uart signals
wire		   uart_we;
wire [31:0] uart_adrs;
wire [31:0] uart_wdata;
wire		   uart_req;
wire        uart_done;
wire [31:0] uart_rdata;

wire 			instr_done_o_uart;
wire [31:0] instr_rdata_o_uart;

wire 			data_done_o_uart;
wire [31:0] data_rdata_o_uart;


// resolve conflicts between signals going to uart
conflict_resolver_mem_map_io con_res_uart(
	.clk_i(clk_i),
	.rst_i(rst_i),
	// instr
	.instr_we_i	   (instr_we_i),
	.instr_adrs_i  (instr_adrs_i),
	.instr_wdata_i (instr_wdata_i),
	.instr_wsize_i (instr_wsize_i),
	.instr_req_i   (instr_req_i && adrs_is_uart),
	.instr_done_o  (instr_done_o_uart),
	.instr_rdata_o (instr_rdata_o_uart),
	// data
	.data_we_i	   (data_we_i),
	.data_adrs_i   (data_adrs_i),
	.data_wdata_i  (data_wdata_i),
	.data_wsize_i  (data_wsize_i),
	.data_req_i    (data_req_i && adrs_is_uart),
	.data_done_o   (data_done_o_uart),
	.data_rdata_o  (data_rdata_o_uart),
	// result
	.res_we_o	  	(uart_we),
	.res_adrs_o  	(uart_adrs),
	.res_wdata_o 	(uart_wdata),
	.res_wsize_o 	(), // not used
	.res_req_o		(uart_req),
	.res_done_i		(uart_done),
	.res_rdata_i	(uart_rdata)
);

// uart
assign uart_we_ctrl 		= adrs_is_uart 	? uart_we    :  1'b0;
assign uart_adrs_ctrl 	= adrs_is_uart 	? uart_adrs  : 32'b0;
assign uart_wdata_ctrl  = adrs_is_uart 	? uart_wdata : 32'b0;
assign uart_req_ctrl 	= adrs_is_uart 	? uart_req   :  3'b0;
assign uart_done   = adrs_is_uart ? uart_done_ctrl	 :	 1'b0;
assign uart_rdata  = adrs_is_uart ? uart_rdata_ctrl : 32'b0;

uart_wishbone_controller uart_wb_ctrl(
	.clk_i(clk_i),
	.rst_i(rst_i),
	// signals from mem ctrl
	.we_i(uart_we_ctrl),
	.adrs_i(uart_adrs_ctrl),
	.wdata_i(uart_wdata_ctrl),
	.req_i(uart_req_ctrl),
	.done_o(uart_done_ctrl),
	.rdata_o(uart_rdata_ctrl),
	//---------------------------- wb
	.WB_ADR_O(WB_ADR_O),
	.WB_DAT_I(WB_DAT_I),
	.WB_DAT_O(WB_DAT_O),
	.WB_WE_O (WB_WE_O),
	.WB_CYC_O(WB_CYC_O),
	.WB_STB_O(WB_STB_O),
	.WB_ACK_I(WB_ACK_I),
	.WB_RTY_I(WB_RTY_I)
	);

// caches inputs/outputs
wire 		    instr_we    = adrs_instr_is_main? instr_we_i    :  1'b0;
wire [31:0]  instr_adrs  = adrs_instr_is_main? instr_adrs_i  : 32'b0;
wire [31:0]  instr_wdata = adrs_instr_is_main? instr_wdata_i : 32'b0;
wire [1:0]   instr_wsize = adrs_instr_is_main? instr_wsize_i :  2'b0;
wire 		    instr_req   = adrs_instr_is_main? instr_req_i   :  1'b0;
assign instr_done_o  = adrs_instr_is_main? instr_done : adrs_instr_is_uart? instr_done_o_uart  :  1'b0;
assign instr_rdata_o = adrs_instr_is_main? instr_rdata : adrs_instr_is_uart? instr_rdata_o_uart :  32'b0;

wire 		    data_we    = adrs_data_is_main? data_we_i    :  1'b0;
wire [31:0]  data_adrs  = adrs_data_is_main? data_adrs_i  : 32'b0;
wire [31:0]  data_wdata = adrs_data_is_main? data_wdata_i : 32'b0;
wire [1:0]   data_wsize = adrs_data_is_main? data_wsize_i :  2'b0;
wire 		    data_req   = adrs_data_is_main? data_req_i   :  1'b0;
assign data_done_o  = adrs_data_is_main? data_done  : adrs_data_is_uart? data_done_o_uart :  1'b0;
assign data_rdata_o = adrs_data_is_main? data_rdata : adrs_data_is_uart? data_rdata_o_uart :  32'b0;

// between caches and main mem
wire 		    instr_main_we;
wire [31:0]  instr_main_adrs;
wire [127:0] instr_main_wdata;
wire [15:0]  instr_main_wstrb;
wire 		    instr_main_req;
wire     	 instr_main_done;
wire [127:0] instr_main_rdata;

wire 		    data_main_we;
wire [31:0]  data_main_adrs;
wire [127:0] data_main_wdata;
wire [15:0]  data_main_wstrb;
wire 		    data_main_req;
wire     	 data_main_done;
wire [127:0] data_main_rdata;

cache_controller
#(
	.C(C_instr), // capacity (words)
	.b(b_instr), // block size (words in block)
	.N(N_instr)  // degree of associativity
) 
cache_ctrl_instr
(
	.clk_i(clk_i),
	.rst_i(rst_i),

	// todo: change these after mem map
	.we_i		(instr_we),
	.adrs_i	(instr_adrs),
	.wdata_i (instr_wdata),
	.wsize_i (instr_wsize),
	.req_i	(instr_req),
	.done_o	(instr_done),
	.rdata_o (instr_rdata),

	.main_we_o	  	(instr_main_we),
	.main_adrs_o  	(instr_main_adrs),
	.main_wdata_o 	(instr_main_wdata),
	.main_wstrb_o 	(instr_main_wstrb),
	.main_req_o		(instr_main_req),
	.main_done_i	(instr_main_done),
	.main_rdata_i	(instr_main_rdata)
);

cache_controller
#(
	.C(C_data), // capacity (words)
	.b(b_data), // block size (words in block)
	.N(N_data)  // degree of associativity
) 
cache_ctrl_data
(
	.clk_i(clk_i),
	.rst_i(rst_i),

	.we_i		(data_we),
	.adrs_i	(data_adrs),
	.wdata_i (data_wdata),
	.wsize_i (data_wsize),
	.req_i	(data_req),
	.done_o	(data_done),
	.rdata_o (data_rdata),

	.main_we_o	  	(data_main_we),
	.main_adrs_o  	(data_main_adrs),
	.main_wdata_o 	(data_main_wdata),
	.main_wstrb_o 	(data_main_wstrb),
	.main_req_o		(data_main_req),
	.main_done_i	(data_main_done),
	.main_rdata_i	(data_main_rdata)
);

// resolve conflicts between signals coming from caches to main
conflict_resolver_caches_main con_res_main(
	.clk_i(clk_i),
	.rst_i(rst_i),
	// instr
	.instr_we_i	   (instr_main_we),
	.instr_adrs_i  (instr_main_adrs),
	.instr_wdata_i (instr_main_wdata),
	.instr_wstrb_i (instr_main_wstrb),
	.instr_req_i   (instr_main_req),
	.instr_done_o  (instr_main_done),
	.instr_rdata_o (instr_main_rdata),
	// data
	.data_we_i	   (data_main_we),
	.data_adrs_i   (data_main_adrs),
	.data_wdata_i  (data_main_wdata),
	.data_wstrb_i  (data_main_wstrb),
	.data_req_i    (data_main_req),
	.data_done_o   (data_main_done),
	.data_rdata_o  (data_main_rdata),
	// result
	.res_we_o	  	(main_we_o),
	.res_adrs_o  	(main_adrs_o),
	.res_wdata_o 	(main_wdata_o),
	.res_wstrb_o 	(main_wstrb_o),
	.res_req_o		(main_req_o),
	.res_done_i		(main_done_i),
	.res_rdata_i	(main_rdata_i)
);

endmodule