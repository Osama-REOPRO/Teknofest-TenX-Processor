`define UART_PERIPHERAL_ADRS 8'b0

module wb_m_core_uart(
   input             clk_i,
   input             rst_i,
   //---------------------------- uart
   input             tx_en_i,
   input             rx_en_i,
   input      [15:0] baud_div_i,
   output            tx_full_o,
   output            tx_empty_o,
   output            rx_full_o,
   output            rx_empty_o,
   input             wdata_write_request_i,
   input       [7:0] wdata_i,
   input             rdata_read_request_i,
   output      [7:0] rdata_o,
   //---------------------------- wb
   output reg [ 7:0] ADR_O,
   input      [31:0] DAT_I,
   output reg [31:0] DAT_O,
   output reg        WE_O,
   output reg        CYC_O,
   output reg        STB_O,
   input             ACK_I,
   input             RTY_I
    );

reg tx_en, rx_en;
reg [15:0] baud_div;
reg [7:0] wdata;
reg ctrl_changed;
reg wdata_write_request;

always @ (*) begin
   if (rst_i) begin 
      {tx_en, rx_en, baud_div, wdata, wdata_write_request} <= 0;
      ctrl_changed <= 0;
   end else begin
      if (/* (tx_en != tx_en_i) || */(rx_en != rx_en_i) || (baud_div != baud_div_i)) 
         ctrl_changed <= 1; // todo: test
      {tx_en, rx_en, baud_div, wdata, wdata_write_request} <= {tx_en_i, rx_en_i, baud_div_i, wdata_i, wdata_write_request_i}; // todo: test
   end
end

wire [7:0] tx_buffer_popped_value;
reg tx_rty;
wire tx_buffer_pop_en;
FIFObuffer #(.width(8), .size(32)) tx_buffer (
   .clk       (clk_i),
   .rst       (rst_i),
   .push_en   (wdata_write_request),
   .pop_en    (tx_buffer_pop_en),
   .push_data (wdata),
   .pop_data  (tx_buffer_popped_value),
   .empty     (tx_empty_o),
   .full      (tx_full_o)
   );

wire [7:0] rx_buffer_popped_value;
reg rx_rty;
wire rx_empty, rx_full;
reg rx_buffer_push_en;
reg [7:0] rx_buffer_push_value;
FIFObuffer #(.width(8), .size(32)) rx_buffer (
   .clk       (clk_i),
   .rst       (rst_i),
   .push_en   (rx_buffer_push_en), // todo
   .pop_en    (rdata_read_request_i),
   .push_data (rx_buffer_push_value), // todo
   .pop_data  (rdata_o),
   .empty     (rx_empty_o),
   .full      (rx_full_o)
   );

reg [3:0] state;
parameter idle = 0, buffer_pop = 1, write_cycle = 2, await_write_ack = 3, read_cycle = 4, await_read_ack = 5, end_read_cycle_disable_rx_buffer = 6;

// state machine entry
always @(*) begin
   if (state==idle) begin
      if(tx_en && !tx_empty_o)
         state = tx_rty? write_cycle : buffer_pop;
      else if (ctrl_changed)
         state = write_cycle;
      else if (rx_en)
         state = read_cycle;
   end
end

//always @(*) tx_buffer_pop_en = (state == buffer_pop);
assign tx_buffer_pop_en = (state == buffer_pop); // todo: test
//always @(*) if (!STB_O) DAT_O = {baud_div, 6'b0, tx_buffer_popped_value, rx_en, tx_en};

always @ (posedge clk_i) begin
   if(rst_i)begin
      {ADR_O, 
      WE_O, CYC_O, STB_O,
      tx_rty, rx_rty,
      rx_buffer_push_en,
      rx_buffer_push_value} <= 0;
      state = idle;
   end else begin
      case(state)
         buffer_pop: begin
            // tx_buffer_pop_en is being set to 1 combinationally above
            state <= write_cycle;
         end
         write_cycle: begin            
            ctrl_changed <= 0;
            CYC_O <= 1;
            STB_O <= 1;
            ADR_O <= `UART_PERIPHERAL_ADRS;
            DAT_O <= {baud_div, 6'b0, tx_buffer_popped_value, rx_en, tx_en};
            WE_O <= 1;
            state <= await_write_ack;
         end
         await_write_ack: begin
            if (ACK_I || RTY_I) begin
               CYC_O <= 0;
               STB_O <= 0;
               tx_rty <= RTY_I;
               DAT_O[0] <= 0;
               state <= rx_en ? read_cycle : idle; // todo
//               state <= idle; // todo: replace with comment above once rx ready, to speed it up
            end
         end
         read_cycle: begin
            CYC_O <= 1;
            STB_O <= 1;
            ADR_O <= `UART_PERIPHERAL_ADRS;
            WE_O <= 0;
            state <= await_read_ack;
         end
         await_read_ack: begin
            if (ACK_I || RTY_I) begin
               CYC_O <= 0;
               STB_O <= 0;
               rx_rty <= RTY_I; // todo: handle retry
               rx_buffer_push_value <= RTY_I ? rx_buffer_push_value : DAT_I[7:0];
               rx_buffer_push_en <= !RTY_I;
               state <= RTY_I ? idle : end_read_cycle_disable_rx_buffer;
            end
         end
         end_read_cycle_disable_rx_buffer: begin
            rx_buffer_push_en <= 0;
            state <= idle;
         end
      endcase
   end
end
endmodule