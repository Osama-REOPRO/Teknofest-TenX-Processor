module uart_wishbone_controller(
	input clk_i, rst_i,
	// -------------------- memory-mapped uart signals
	input 		  we_i,
	input  [31:0] adrs_i,
	input  [31:0] wdata_i,
	// input  [2:0]  wsize_i, // ignored, always word read/write
	input 		  req_i,
	output reg    		done_o,
	output reg [31:0] rdata_o,
	// wishbone
	input  [31:0] WB_ADR_O,
	output [31:0] WB_DAT_I,
	input  [31:0] WB_DAT_O,
	input 		  WB_WE_O,
	input 		  WB_CYC_O,
	input 		  WB_STB_O,
	output 		  WB_ACK_I,
	output 		  WB_RTY_I
);

reg  		  tx_en;
reg  		  rx_en;
reg [15:0] baud_div;
wire       tx_full;
wire       tx_empty;
wire       rx_full;
wire       rx_empty;
reg        wdata_write_request;
wire [7:0] wdata;
reg        rdata_read_request;
wire [7:0] rdata;

// output assignments
assign wdata = wdata_i[7:0];

// uart memory maps
localparam adrs_uart_ctrl 	 = 32'h20000000;
localparam adrs_uart_status = 32'h20000004;
localparam adrs_uart_rdata  = 32'h20000008;
localparam adrs_uart_wdata  = 32'h2000000c;

// memory map checks
wire adrs_is_uart_ctrl   = (adrs_i >= adrs_uart_ctrl)   && (adrs_i <= adrs_uart_ctrl+32'd1);
wire adrs_is_uart_status = (adrs_i >= adrs_uart_status) && (adrs_i <= adrs_uart_status+32'd1);
wire adrs_is_uart_rdata  = (adrs_i >= adrs_uart_rdata)  && (adrs_i <= adrs_uart_rdata+32'd1);
wire adrs_is_uart_wdata  = (adrs_i >= adrs_uart_wdata)  && (adrs_i <= adrs_uart_wdata+32'd1);

// combine signals into 32-bit words
wire [31:0] uart_ctrl;
assign uart_ctrl[0] = tx_en;
assign uart_ctrl[1] = tx_en;
assign uart_ctrl[15:2] = 14'b0;
assign uart_ctrl[31:16] = baud_div;
wire [31:0] uart_status;
assign uart_status[0] = tx_full;
assign uart_status[1] = tx_empty;
assign uart_status[2] = rx_full;
assign uart_status[3] = rx_empty;
assign uart_status[31:4] = 28'b0;
wire [31:0] uart_rdata;
assign uart_rdata[7:0] = rdata;
assign uart_rdata[31:8] = 24'b0;
wire [31:0] uart_wdata;
assign uart_wdata[7:0] = wdata;
assign uart_wdata[31:8] = 24'b0;

reg [3:0] state;
localparam idle_st 					= 0,
			  done_st 					= 1,
			  read_uart_ctrl_st		= 2,
			  read_uart_status_st	= 3,
			  read_uart_rdata_st		= 4,
			  read_uart_wdata_st		= 5,
			  write_uart_ctrl_st		= 6,
			  write_uart_status_st	= 7,
			  write_uart_rdata_st	= 8,
			  write_uart_wdata_st	= 9;

reg [3:0] sub_state;
localparam init   = 0,
			  busy   = 1,
			  finish = 2;

always @(posedge clk_i) begin
	if (rst_i) begin
		{  state,
			sub_state,
			tx_en,
			rx_en,
			baud_div,
			wdata_write_request,
			rdata_read_request,
			done_o,
			rdata_o
			} <= 0;
	end else begin
		case (state)
			idle_st: begin
				done_o <= 1'b0;
				if (req_i) begin
					if			(adrs_is_uart_ctrl) 	 state <= we_i ? write_uart_ctrl_st   : read_uart_ctrl_st;
					else if 	(adrs_is_uart_status) state <= we_i ? write_uart_status_st : read_uart_status_st;
					else if	(adrs_is_uart_rdata)	 state <= we_i ? write_uart_rdata_st  : read_uart_rdata_st;
					else if	(adrs_is_uart_wdata)  state <= we_i ? write_uart_wdata_st  : read_uart_wdata_st;
					else 									 state <= idle_st;
				end
			end

			done_st: begin
				done_o <= 1'b1;
				if (!req_i) state = idle_st;
			end




			read_uart_ctrl_st: begin
				rdata_o <= uart_ctrl;
				state   <= done_st;
			end

			read_uart_status_st: begin
				rdata_o <= uart_status;
				state   <= done_st;
			end

			read_uart_rdata_st: begin
				case (sub_state)
					0: begin
						rdata_read_request <= 1'b1;
						sub_state <= 3'd1;
					end
					1: begin
						rdata_o <= uart_rdata;
						rdata_read_request <= 1'b0;
						sub_state <= 3'd0;
						state <= done_st;
					end
				endcase
			end

			write_uart_ctrl_st: begin
				tx_en 	<= wdata_i[0];
				rx_en 	<= wdata_i[1];
				baud_div <= wdata_i[31:16];
				state   <= done_st;
			end

			write_uart_wdata_st: begin
				case (sub_state)
					0: begin
						wdata_write_request <= 1'b1;
						sub_state <= 3'd1;
					end
					1: begin
						wdata_write_request <= 1'b0;
						sub_state <= 3'd0;
						state <= done_st;
					end
				endcase
			end
		endcase
	end
end


wb_m_core_uart wishbone_master_uart (
	.clk_i         (clk_i),
	.rst_i         (rst_i),
	// uart
	.tx_en_i       (tx_en),
	.rx_en_i       (rx_en),
	.baud_div_i    (baud_div),
	.tx_full_o     (tx_full),
	.tx_empty_o    (tx_empty),
	.rx_full_o     (rx_full),
	.rx_empty_o    (rx_empty),
	.wdata_write_request_i(wdata_write_request),
	.wdata_i       (wdata),
	.rdata_read_request_i(rdata_read_request),
	.rdata_o       (rdata),
	// wb
	.ADR_O         (WB_ADR_O),
	.DAT_I         (WB_DAT_I),
	.DAT_O         (WB_DAT_O),
	.WE_O          (WB_WE_O),
	.CYC_O         (WB_CYC_O),
	.STB_O         (WB_STB_O),
	.ACK_I         (WB_ACK_I),
	.RTY_I         (WB_RTY_I)
	 );

endmodule