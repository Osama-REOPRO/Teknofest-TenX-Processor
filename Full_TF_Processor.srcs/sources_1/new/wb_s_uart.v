module wb_s_uart(
   input             clk_i,
   input             rst_i,
   // wb
   input      [31:0] ADR_I, // todo: check for correct address
   input      [31:0] DAT_I,
   output reg [31:0] DAT_O,
   input             WE_I,
   input             CYC_I,
   input             STB_I,
   output reg        ACK_O,
   output reg        RTY_O,
   // uart
   output            tx_o,
   input             rx_i
   );
   
   wire DAT_I_tx_en           = DAT_I[0];
   wire DAT_I_rx_en           = DAT_I[1];
   wire [15:0] DAT_I_baud_div = DAT_I[31:16];
   wire [7:0] DAT_I_wdata     = DAT_I[7+2:2];
   wire [7:0] rdata;
   wire tx_full, tx_empty, rx_full, rx_empty;
   
   reg        tx_en;
   reg        rx_en;
   reg [15:0] baud_div;
   reg [7:0]  wdata;
   reg        rx_buffer_pop;
   
   uart uart (
      .clk(clk_i),
      .rst(rst_i),
      .tx_en(tx_en),
      .rx_en(rx_en), // should receive and push into buffer when rx_en, pop when pop request
      .rx_buffer_pop_i(rx_buffer_pop),
      .baud_div(baud_div),
      .wdata(wdata),
      .rdata(rdata),
      .tx_full(tx_full),
      .tx_empty(tx_empty),
      .rx_full(rx_full),
      .rx_empty(rx_empty),
      .tx(tx_o),
      .rx(rx_i)
      );
      
   
   // state machine
   reg [3:0] state;
   
   parameter idle                = 0;
   parameter receive_from_master = idle+1;
   parameter ack_receive         = receive_from_master+1;
   parameter send_to_master      = ack_receive+1;
   parameter await_buffer_pop    = send_to_master+1;
   parameter ack_send            = await_buffer_pop+1;
   parameter deassert_ack_rty    = ack_send+1;
   
   always @(*) begin
      if (CYC_I && STB_I && WE_I) begin
         state <= receive_from_master;
      end else if (CYC_I && STB_I && !WE_I) begin
         state <= send_to_master;
      end
   end
   
   
   always @(posedge clk_i) begin
      if(rst_i)begin
         {DAT_O, ACK_O, RTY_O, state, rx_buffer_pop} <= 0;
      end else begin
         case (state)
            receive_from_master: begin
               rx_en    <= DAT_I_rx_en;
               baud_div <= DAT_I_baud_div;
               if (!tx_full) begin
                  tx_en    <= DAT_I_tx_en;
                  wdata    <= DAT_I_wdata;
                  state <= ack_receive;
               end else begin
                  tx_en <= 0;
                  RTY_O <= 1;
                  state <= deassert_ack_rty;
               end
            end
            ack_receive: begin
               tx_en <= 0;
               ACK_O <= 1;
               state <= deassert_ack_rty;
            end
            send_to_master: begin
               if (!rx_empty) begin
                  rx_buffer_pop <= 1;
                  state <= await_buffer_pop;
               end else begin
                  rx_buffer_pop <= 0;
                  RTY_O <= 1;
                  state <= deassert_ack_rty;
               end
            end
            await_buffer_pop: begin
                  state <= ack_send;
            end
            ack_send: begin
               rx_buffer_pop <= 0;
               DAT_O <= rdata;
               ACK_O <= 1;
               state <= deassert_ack_rty;
            end
            deassert_ack_rty: begin
               if (!STB_I) begin
                  ACK_O <= 0;
                  RTY_O <= 0;
                  state <= idle;
               end
            end
         endcase
      end
   end
endmodule