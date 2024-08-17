`include "atomic_ops.vh"

module Atomic_Operations_Handler(
	input clk_i,
	input rst_i,

	input [3:0] data_atomic_operation_i,

	input 			data_we_i,
	input [31:0] 	data_adrs_i,
	input [31:0] 	data_wdata_i,
	input [1:0] 	data_wsize_i,
	input 			data_req_i,
	output reg		data_done_o,
	output [31:0] 	data_rdata_o,

	output reg		data_we_o,
	output [31:0] 	data_adrs_o,
	output [31:0] 	data_wdata_o,
	output [1:0] 	data_wsize_o,
	output reg		data_req_o,
	input  			data_done_i,
	input [31:0] 	data_rdata_i
);

wire [31:0] rdata_wdata_max = (data_rdata_i >= data_wdata_i)? data_rdata_i : data_wdata_i;
wire [31:0] rdata_wdata_min = (data_rdata_i < data_wdata_i)? data_rdata_i : data_wdata_i;

assign data_adrs_o = data_adrs_i;
assign data_wsize_o = data_wsize_i;

assign data_rdata_o = 
	// (data_atomic_operation_i == `load_reserved_aop) ? : // todo
	// (data_atomic_operation_i == `store_conditional_aop) ? : // todo
	data_rdata_i;

assign data_wdata_o = 
	// (data_atomic_operation_i == `load_reserved_aop) ? : // todo
	// (data_atomic_operation_i == `store_conditional_aop) ? : // todo
	(data_atomic_operation_i == `amo_swap_aop) ? data_wdata_i :
	(data_atomic_operation_i == `amo_add_aop) ? data_wdata_i + data_rdata_i :
	(data_atomic_operation_i == `amo_and_aop) ? data_wdata_i & data_rdata_i :
	(data_atomic_operation_i == `amo_or_aop) ? data_wdata_i | data_rdata_i :
	(data_atomic_operation_i == `amo_xor_aop) ? data_wdata_i ^ data_rdata_i :
	(data_atomic_operation_i == `amo_max_aop) ? rdata_wdata_max :
	(data_atomic_operation_i == `amo_min_aop) ? rdata_wdata_min :
	32'd0;

reg [4:0] state;
localparam idle = 0, read = 1, write = 2, done = 3;
reg [1:0] sub_state;
localparam init = 0, busy = 1, finish = 2;
always @(posedge clk_i) begin
	if (rst_i) begin
		{
			state, sub_state,
			data_we_o, data_req_o,
			data_done_o
			} <= 0;
	end else begin
		case (state)

			idle: begin
				data_done_o <= 1'b0;
				if (data_req_i) begin
					state <= read;
				end
			end

			read: begin
				case (sub_state)

					init: begin
						data_we_o <= 1'b0;
						data_req_o <= 1'b1;

						sub_state <= busy;
					end

					busy: begin
						if (data_done_i) begin
							data_req_o <= 1'b0;
							sub_state <= finish;
						end
					end

					finish: begin
						if (!data_done_i) begin
							state <= write;
							sub_state <= init;
						end
					end

				endcase
			end

			write: begin
				case (sub_state)

					init: begin
						data_we_o <= 1'b1;
						data_req_o <= 1'b1;

						sub_state <= busy;
					end

					busy: begin
						if (data_done_i) begin
							data_req_o <= 1'b0;
							sub_state <= finish;
						end
					end

					finish: begin
						if (!data_done_i) begin
							state <= write;
							sub_state <= init;
						end
					end

				endcase
			end

			done: begin
				data_done_o <= 1'b1;
				if (!data_req_i) begin
					state <= idle;
				end
			end

		endcase
	end
end

endmodule

// general algorithm:
// 	core side:
// 		set address to rs1
// 		set write data to rs2
// 	memory side:
// 		read mem address into rdata output
//			process data
// 		write the operation result to mem address
// 	core side:
// 		set rd to rdata