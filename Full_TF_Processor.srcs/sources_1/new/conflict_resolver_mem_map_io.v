module conflict_resolver_mem_map_io(
	input clk_i,
	input rst_i,
	// instr
	input  		  instr_we_i,
	input  [31:0] instr_adrs_i,
	input  [31:0] instr_wdata_i,
	input  [1:0]  instr_wsize_i,
	input  		  instr_req_i,
	output     	  instr_done_o,
	output [31:0] instr_rdata_o,
	// data
	input  		  data_we_i,
	input  [31:0] data_adrs_i,
	input  [31:0] data_wdata_i,
	input  [1:0]  data_wsize_i,
	input  		  data_req_i,
	output     	  data_done_o,
	output [31:0] data_rdata_o,
	// result
	output 		  res_we_o,
	output [31:0] res_adrs_o,
	output [31:0] res_wdata_o,
	output [2:0]  res_wsize_o,
	output 		  res_req_o,
	input      	  res_done_i,
	input  [31:0] res_rdata_i
);
wire req_instr = instr_req_i;
wire req_data = data_req_i;

reg [3:0] allowed;
localparam none = 0, instr = 1, data = 2;

always @(clk_i) begin
	if (rst_i) begin
		allowed <= 0;
	end else begin
		case (allowed)
			none: begin
				if 		(req_instr) allowed <= instr;
				else if 	(req_data) 	allowed <= data;
				else 						allowed <= none;
			end
			instr: begin
				if (!res_req_o && !res_done_i) begin // done
					if (req_data) 	allowed <= data;
					else 				allowed <= none;
				end
			end
			data: begin
				if (!res_req_o && !res_done_i) begin // done
					if (req_instr) allowed <= instr;
					else 				allowed <= none;
				end
			end
		endcase
	end
end

assign res_we_o 	  = (allowed == instr)? instr_we_i		:(allowed == data)? data_we_i    : 0;
assign res_adrs_o  = (allowed == instr)? instr_adrs_i		:(allowed == data)? data_adrs_i  : 0;
assign res_wdata_o = (allowed == instr)? instr_wdata_i	:(allowed == data)? data_wdata_i : 0;
assign res_wsize_o = (allowed == instr)? instr_wsize_i	:(allowed == data)? data_wsize_i : 0;
assign res_req_o   = (allowed == instr)? instr_req_i		:(allowed == data)? data_req_i   : 0;

assign instr_done_o  	= (allowed == instr)? 	res_done_i : 0;
assign data_done_o  	= (allowed == data)?		res_done_i : 0;
assign instr_rdata_o  = (allowed == instr)? 	res_rdata_i : 0;
assign data_rdata_o  	= (allowed == data)? 	res_rdata_i : 0;

endmodule
