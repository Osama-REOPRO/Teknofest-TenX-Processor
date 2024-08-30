`include "cache_ops.vh"

module cache
#(
	parameter C = 8,   // capacity (total words)
	parameter b = 2,   // block size (words per block)
	parameter N = 2    // degree of associativity (blocks per set)
)
(
	input       			   	  i_clk, 
	input         			   	  i_rst,

	input 	  [`op_N:0]	   	  i_op, 				// lookup, read, write
	input		  [31:0]		   	  i_address,

	input 							  i_set_valid,
	input 							  i_set_tag,
	input 							  i_set_dirty,
	input 							  i_set_use,

	input 					   	  i_mem_operation,

	output reg 						  o_hit_occurred,
	output reg 						  o_empty_found,
	output reg  			   	  o_clean_found,

	input 	  [(4*b)-1:0]	     i_valid_bytes, 	// valid bytes in read/write data, 1 for each valid byte

	input 	  [(32*b)-1:0] 	  i_write_data,
	output reg [(32*b)-1:0] 	  o_read_data,

	output reg				   	  o_mem_operation_done
);

	// parameters
	localparam B  = C/b;  // number of blocks
	localparam S  = B/N;  // number of sets

	localparam Single_word_blocks  = (b <= 1); // no block offset
	localparam Direct_mapped       = (N <= 1); // don't utilize use_bit
	localparam Fully_associative   = (S <= 1); // set address always 0

	localparam Byte_offset_nbytes  = 2; // offset of byte within word
	localparam Block_offset_nbytes = $clog2(b); // offset of word within block (more like word_offset)
	localparam Set_nbytes 			 = $clog2(S);
	localparam Tag_nbytes 			 = 32 - Set_nbytes - Block_offset_nbytes - Byte_offset_nbytes;
	
	// mem
	reg [7:0] 				data_mem  [N-1:0] [S-1:0] [b-1:0] [3:0];
	reg [Tag_nbytes-1:0] tag_mem   [N-1:0] [S-1:0];
	reg 						valid_mem [N-1:0] [S-1:0];
	reg 						dirty_mem [N-1:0] [S-1:0];
	reg 						use_mem   			[S-1:0];

	// decode address
	wire [Byte_offset_nbytes-1:0]  											 byte_offset_adrs  =										 i_address[0 +: Byte_offset_nbytes ];
	wire [(Block_offset_nbytes > 0 ? Block_offset_nbytes-1 : 0) :0] block_offset_adrs = Single_word_blocks ? 1'b0 : i_address[0 +  Byte_offset_nbytes +: Block_offset_nbytes > 0 ? Block_offset_nbytes : 1]; // just so it will compile, not used when Single_word_blocks
	wire [Set_nbytes-1:0] 			 											 set_adrs 			 =	Fully_associative  ? 1'b0 : i_address[0 +  Byte_offset_nbytes +  Block_offset_nbytes	+:	Set_nbytes ];
	wire [Tag_nbytes-1:0] 			 											 tag_adrs 			 =										 i_address[0 +  Byte_offset_nbytes +  Block_offset_nbytes	+	Set_nbytes +: Tag_nbytes ];

	// N operations
	integer i;
	localparam size_N = $clog2(N);

	reg [size_N-1:0] hit_N; // which of the N-ways the hit occurred in
	reg [size_N-1:0] empty_N; // which of the N-ways is empty
	reg [size_N-1:0] clean_N;

	wire [size_N-1:0] random_N; // randomly generated N with LFSR
	reg get_new_random_num;
	reg rand_gen_clk;
	always @(posedge i_clk) begin
		if (i_rst) begin 
			rand_gen_clk <= 1'b0;
		end else if (get_new_random_num) begin
			rand_gen_clk 		 	<= 1'b1;
			get_new_random_num 	<= 1'b0;
		end else 
			rand_gen_clk 		 	<= 1'b0;
	end
	LFSR #(.size(size_N)) rand_gen (.i_clk(i_rst ? i_clk : rand_gen_clk), .i_rst(i_rst), .o_num(random_N));
	wire [size_N-1:0] target_N = Direct_mapped ? 0       : 
						 o_hit_occurred  ? hit_N 	 :
						 o_empty_found   ? empty_N :
						 o_clean_found   ? clean_N :
						 size_N >= 2	  ? {random_N[size_N-1:1], !use_mem [set_adrs]} : // N to evacuate then replace #note0001
						 !use_mem [set_adrs];

	wire write_would_conflict = !o_hit_occurred && !o_empty_found && !o_clean_found;

	// state machine
	reg [$clog2(3)-1:0] state;
	localparam 
		idle_st 	 = 0,
		busy_st 	 = 1,
		done_st 	 = 2;

	always @(*) if (state == idle_st) o_mem_operation_done = 1'b0;

	always @(posedge i_clk) begin
		if(i_rst) begin 
			state <= 0;
		end
		else begin
			case (state)
				idle_st: if (i_mem_operation) 	  state <= busy_st;
				busy_st: if (o_mem_operation_done) state <= done_st;
				done_st: if (!i_mem_operation) 	  state <= idle_st;
			endcase
		end
	end
	
	reg delay_started;

	// hit check
	always @(*) begin
		if (i_rst) begin

			o_hit_occurred = 1'b0;
			o_empty_found  = 1'b0;
			o_clean_found  = 1'b0;

			hit_N   = {size_N{1'b0}};
			empty_N = {size_N{1'b0}};
			clean_N = {size_N{1'b0}};
			
			get_new_random_num = 1'b0;

			i = 0;

		end else if (state == busy_st && i_op == `lookup_op && !o_mem_operation_done) begin
			o_hit_occurred = 1'b0;
			o_clean_found  = 1'b0;
			o_empty_found  = 1'b0;
			get_new_random_num = 1'b1;
			#10;
			o_mem_operation_done = 1'b1;
			for (i=N-1; i>=0; i=i-1) begin // going backwards so the lowest hit is returned not highest! (stylistic choice)
				if (valid_mem[i][set_adrs]) begin
					if (tag_adrs == tag_mem[i][set_adrs]) begin
						o_hit_occurred = 1'b1;
						hit_N = i;
					end else if (!dirty_mem[i][set_adrs]) begin
						o_clean_found  = 1'b1;
						clean_N = i;
					end
				end else begin
					o_empty_found = 1'b1;
					empty_N = i;
				end
			end
		end
	end

	// clocked read/write operations
	always @(posedge i_clk) begin : read_write
		integer i0;
		integer i1;
		integer i2;
		integer i3;
		reg [$clog2(4*b):0] ib; 	// number of bytes in write_data
		if (i_rst) begin
		
			o_mem_operation_done <= 1'b0;
			delay_started <= 1'b0;

			for (i0=0; i0<N; i0=i0+1) begin
				for (i1=0; i1<S; i1=i1+1) begin

					tag_mem	 [i0][i1] <= 0;
					valid_mem [i0][i1] <= 0;
					dirty_mem [i0][i1] <= 0;
					use_mem       [i1] <= 0;

					for (i2=0; i2<b; i2=i2+1) begin
						for (i3=0; i3<4; i3=i3+1) begin

							data_mem[i0][i1][i2][i3] <= 8'hff;

						end
					end
				end
			end
		end else begin
		
			if (state == busy_st && i_op == `write_op && !o_mem_operation_done && !delay_started) begin ////////////////////////////////////// write
//				log_state_write_before_delay();

				delay_started <= 1'b1;
				#20
				delay_started <= 1'b0;

//				log_state_write_after_delay();
				
				for ( ib=0; ib < (4*b); ib=ib+1) begin
					if (i_valid_bytes[ib]) begin
						data_mem [target_N] [set_adrs] [ ($clog2(4*b)-1) >= 2 ? ib[$clog2(4*b)-1:2] : 0 ] [ ib[1:0] ] 
							<= i_write_data[((ib+1)*8)-1 -: 8];
					end
				end
				
				if (i_set_valid) valid_mem [target_N][set_adrs] <= 1'b1;
				if (i_set_tag)   tag_mem 	[target_N][set_adrs] <= tag_adrs;
				if (i_set_dirty) dirty_mem [target_N][set_adrs] <= 1'b1;
				if (i_set_use)   use_mem 				 [set_adrs] <= target_N [0]; // #note0001

				o_mem_operation_done <= 1'b1;
			end else if (state == busy_st && i_op == `read_op && !o_mem_operation_done && !delay_started) begin ////////////////////////////////////// read
//				log_state_read_before_delay();
				delay_started <= 1'b1;
				#20
				delay_started <= 1'b0;
				
				for (ib=0; ib<(4*b); ib=ib+1) begin
//					$display("		ib = %b", ib);
//					$display("		i_valid_bytes[%0d] = %b", ib, i_valid_bytes[ib]);
					if (i_valid_bytes[ib]) begin
						$write("		o_read_data[%0d -:8] <= %b", ((ib+1)*8)-1, data_mem[target_N][set_adrs][ ($clog2(4*b)-1) >= 2 ? ib[$clog2(4*b)-1:2] : 0 ][ ib[1:0] ]);
						$write(" = %0d\n", data_mem[target_N][set_adrs][ ($clog2(4*b)-1) >= 2 ? ib[$clog2(4*b)-1:2] : 0 ] [ ib[1:0] ]);
						o_read_data[((ib+1)*8)-1 -:8] <= data_mem[target_N][set_adrs][ ($clog2(4*b)-1) >= 2 ? ib[$clog2(4*b)-1:2] : 0 ] [ ib[1:0] ];
					end
				end
				
				o_mem_operation_done <= 1'b1;

//				log_state_read_after_delay();
			end
			
		end
	end

	task log_state_write_before_delay;
		begin
			$display("		write state inside cache start: ************************");

			$display();
			$display("		i_address 	  = %0d", i_address);

			$display();
			$display("		i_set_valid   = %b", i_set_valid);
			$display("		i_set_tag 	  = %b", i_set_tag);
			$display("		i_set_dirty   = %b", i_set_dirty);
			$display("		i_set_use 	  = %b", i_set_use);

			$display();
			$display("		i_valid_bytes = %b", i_valid_bytes);
			$display("		i_write_data  = %b", i_write_data);
		end
	endtask

	task log_state_write_after_delay;
		begin
			$display();
			$display("		write state inside cache end: ************************");
		end
	endtask


	task log_state_read_before_delay;
		begin
			$display("		************************ read state inside cache start");
			$display("		i_address 	  = %0d", i_address);

			$display();
			$display("		i_valid_bytes = %b", i_valid_bytes);
			$display("		o_read_data  = %b", o_read_data);
			$write("		");
			$write(data_mem);
			$write("\n");
		end
	endtask

	task log_state_read_after_delay;
		begin
			$strobe();
			$strobe("		********** after delay");
			$strobe("		o_read_data  = %0b", o_read_data);
			$strobe("		************************ read state inside cache end");
		end
	endtask

//	initial begin
//		$monitor("\n(%0t) ################## target_N = ", $time, target_N);
//	end

endmodule

// LFSR
module LFSR
#(
	parameter size = 4,
	localparam clamped_size = size >= 4 ? size : 4 // LFSR makes no sense under 4-bits
) (
	input i_clk, i_rst, 
	output reg [clamped_size-1:0] o_num
);
	always@(posedge i_clk) begin
		if(i_rst) o_num <= {clamped_size{1'b1}};
		else begin
			o_num <= {o_num[clamped_size-2:0],(o_num[clamped_size-1]^o_num[clamped_size-2])};
//			$display("~~~~ new random number generated (%b) ~~~~", o_num);
		end
		// shift left once
		// right-most bit is xor of 2 left-most bits
	end
endmodule
