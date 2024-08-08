//`timescale 1us / 1ns
`include "cache_ops.vh"

module cache_controller
#(
	parameter C = 8,   // capacity (total words)
	parameter b = 2,   // block size (words per block)
	parameter N = 2    // degree of associativity (blocks per set)
)
(
	input clk_i, rst_i,

	input 				 we_i,
	input 	  [31:0]  adrs_i,
	input 	  [31:0]	 wdata_i,
	input 	  [1:0]   wsize_i,
	input 				 req_i,
	output reg 			 done_o,
	output reg [31:0]	 rdata_o,

	output reg 		    main_we_o,
	output [31:0]  main_adrs_o,
	output reg [127:0] main_wdata_o,
	output reg [15:0]  main_wstrb_o,
	output reg 		    main_req_o,
	input  		   	 main_done_i,
	input  	  [127:0] main_rdata_i
);

// test wires
wire [31:0] start_of_32_word = adrs_i[3:2]*32;

// signals
assign main_adrs_o = adrs_i;


// cache signals
reg [`op_N:0] op;
reg 			  mem_operation;
wire 			  mem_operation_done;
reg  [15:0]	  valid_bytes;
reg  [127:0]  write_data;
wire [127:0]  read_data;

reg set_valid;
reg set_tag;
reg set_dirty;
reg set_use;

wire hit_occurred;
wire empty_found;
wire clean_found;

// state machine
reg [3:0] state;
localparam idle_st	= 0,
			  lookup_st	= 1,
			  read_st	= 2,
			  write_st	= 3,
			  done_st	= 4;

reg [3:0] cache_sub_state;
localparam init   = 0,
			  busy   = 1,
			  finish = 2;

reg [3:0] op_sub_state;
// read sub states
localparam read_begin_st = 0,
			  read_cache_st = 1,
			  read_main_st  = 2,
			  read_done_st  = 3;
// write sub states
localparam write_begin_st = 0,
			  write_cache_st = 1,
			  write_main_st  = 2,
			  write_done_st  = 3;

// ######################################### state machine tasks
// read_op: miss and no clean nor empty
// write_op: miss and no clean nor empty
wire evac_needed = !hit_occurred && (!empty_found && !clean_found);
// read_op: we read if hit or need evac
// write_op: we read if need evac
wire read_needed_cache = evac_needed || (op && hit_occurred);
// read_op: miss
// write_op: miss
wire read_needed_main = !hit_occurred;
// read_op: evac_needed or missed
// write_op: write_op or evac_needed
wire write_needed_cache = !hit_occurred || (op == `write_op) || evac_needed;
// read_op: evac_needed
// write_op: evac_needed
wire write_needed_main = evac_needed;

integer i;
always @(posedge clk_i) begin
	if(rst_i) begin
		i 					 <= 0;
		state				 <= 0;
		cache_sub_state <= 0;
		op_sub_state	 <= 0;

		{	op,
			mem_operation,
		 	valid_bytes,
		 	write_data,
			set_valid,
			set_tag,
			set_dirty,
			set_use
			} <= 0;

	end else begin
		case (state)

			idle_st: begin
				done_o <= 1'b0;
				if (req_i) begin
					state <= lookup_st;
				end
			end

			done_st: begin
				done_o = 1'b1;
				if (!req_i) state = idle_st;
			end

			lookup_st: begin
				case (cache_sub_state)
					init: begin
						op 				<= `lookup_op;
						mem_operation 	<= 1'b1;

						cache_sub_state   <= busy;
					end
					busy: begin
						if (mem_operation_done) begin
							mem_operation <= 1'b0;

							cache_sub_state 	  <= finish;
						end
					end
					finish: begin
						if (!mem_operation_done) begin
							if (read_needed_cache || read_needed_main) 	state <= read_st;
							else 														state <= write_st;

							cache_sub_state <= init;
						end
					end
				endcase
			end

			read_st: begin
				case (op_sub_state)

					read_begin_st: begin
						op_sub_state <= read_needed_cache? read_cache_st : read_main_st;
					end

					read_cache_st: begin
						// either we read to evacuate, or we read to return
						case (cache_sub_state)
							init: begin
								op 			   <= `read_op;
								mem_operation  <= 1'b1;
								valid_bytes <= {(4*b){1'b1}}; // how about all valid? while reading that it

								cache_sub_state		<= busy;
							end
							busy: begin
								if (mem_operation_done) begin
									mem_operation <= 1'b0;

									cache_sub_state 	  <= finish;
								end
							end
							finish: begin
								if (!mem_operation_done) begin
									if ((op == `read_op) && hit_occurred) begin
										// if hit occurred and we are in read state then we simply return the data
										rdata_o <= read_data[(adrs_i[3:2]*32) +: 32]; // todo: verify
										op_sub_state <= read_done_st;
									end else begin
										op_sub_state <= read_main_st;
									end

									cache_sub_state  <= init;
								end
							end
						endcase
					end

					read_main_st: begin
						case (cache_sub_state)
							init: begin
								main_we_o   <= 1'b0; // read op
								main_req_o  <= 1'b1;

								cache_sub_state <= busy;
							end
							busy: begin
								if (main_done_i) begin
									main_req_o  <= 1'b0;

									cache_sub_state <= finish;
								end
							end
							finish: begin
								if (!main_done_i) begin
									if (we_i == 0) begin
										rdata_o <= main_rdata_i[(adrs_i[3:2]*32)+31 -: 32]; // todo: verify
									end

									op_sub_state <= read_done_st;
									cache_sub_state  <= init;
								end
							end
						endcase
					end

					read_done_st: begin
						if (write_needed_cache || write_needed_main) state <= write_st;
						else state <= done_st;

						op_sub_state <= read_begin_st;
					end

				endcase
			end

			write_st: begin
				// todo
				case (op_sub_state)

					write_begin_st: begin
						if (write_needed_cache) op_sub_state <= write_cache_st;
						else op_sub_state <= write_main_st;
					end

					write_cache_st: begin
						case (cache_sub_state)
							init: begin
								op 			   <= `write_op;
								mem_operation  <= 1'b1;

								// valid_bytes depend on whether we are writing
								// from input or we are writing missing data from main
								// mem. If we are writing from input then valid bytes
								// will be determined by wsize_i, if we are
								// writing missing data from above then all are valid
								if (hit_occurred) begin
									// only write valid bytes from input
									case (wsize_i) // 0:byte, 1:half, 2:word
										2'h0: begin
											// byte, must be at the beginning of input word
											valid_bytes <= {(4*b){1'b0}};
											valid_bytes[adrs_i % (4*b)] <= 1'b1; // todo: verify

											write_data[((adrs_i % (4*b))*8)-1 +:8] <= wdata_i[7:0]; // todo: verify
										end
										2'h1: begin
											// half word, must be at beginning of word (lower half)
											valid_bytes <= {(4*b){1'b0}};
											valid_bytes[(adrs_i*2) % (4*b) +:2] <= 2'b11; // todo: verify

											write_data[(((adrs_i*2) % (4*b))*16)-1 +:16] <= wdata_i[15:0]; // todo: verify
										end
										2'h2: begin
											// word
											valid_bytes <= {(4*b){1'b0}};
											valid_bytes[(adrs_i*4) % (4*b) +:4] <= 4'b1111; // todo: verify

											write_data[(((adrs_i*4) % (4*b))*32)-1 +:32] <= wdata_i; // todo: verify
										end
									endcase
								end else begin
									// write all from above
									valid_bytes <= {(4*b){1'b1}}; // all valid
									write_data <= main_rdata_i; // todo: verify
								end

								cache_sub_state		<= busy;
							end
							busy: begin
								if (mem_operation_done) begin
									mem_operation <= 1'b0;

									cache_sub_state 	  <= finish;
								end
							end
							finish: begin
								if (!mem_operation_done) begin
									if (write_needed_main) 	op_sub_state <= write_main_st;
									else 								op_sub_state <= write_done_st;

									cache_sub_state  <= init;
								end
							end
						endcase
					end

			  		write_main_st: begin
						// todo
						case (cache_sub_state)
							init: begin
								main_we_o <= 1'b1;
								main_req_o  <= 1'b1;
								main_wstrb_o <= {(16){1'b1}}; // all valid
								main_wdata_o <= read_data; // we must be evacuating

								cache_sub_state		<= busy;
							end
							busy: begin
								if (main_done_i) begin
									main_req_o <= 1'b0;

									cache_sub_state 	  <= finish;
								end
							end
							finish: begin
								if (!main_done_i) begin
									op_sub_state <= write_done_st;

									cache_sub_state  <= init;
								end
							end
						endcase
					end

			  		write_done_st: begin
						state <= done_st;

						op_sub_state <= write_begin_st;
					end

				endcase
			end

		endcase
	end
end

cache 
#(
	.C(C), // capacity (words)
	.b(b), // block size (words in block)
	.N(N)  // degree of associativity
) 
cache_data
(
	.i_clk(clk_i),
	.i_rst(rst_i),

	.i_op(op),

	.i_address(adrs_i),

	// todo: decide how these work
	.i_set_valid(set_valid),
	.i_set_tag(set_tag),
	.i_set_dirty(set_dirty),
	.i_set_use(set_use),

	.i_mem_operation(mem_operation),

	.o_hit_occurred(hit_occurred),
	.o_empty_found(empty_found),
	.o_clean_found(clean_found),

	.i_valid_bytes(valid_bytes),

	.i_write_data(write_data),
	.o_read_data(read_data),

	.o_mem_operation_done(mem_operation_done)
);
endmodule
