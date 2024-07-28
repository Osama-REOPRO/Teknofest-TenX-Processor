module uart
    (   input clk, rst,
        input [15:0] baud_div,
        input tx_en, rx_en,
        input rx_buffer_pop_i,
        input [7:0] wdata,
        output [7:0] rdata,
        output tx_full, tx_empty, rx_full, rx_empty,
        output reg tx,
        input rx
        );
        
    // baud-rate stuff
    wire [15:0] baud_div_non_zero = (baud_div > 0) ? baud_div : 1; // baud div can't be zero
    integer baud_cntr;
        
    // buffers
    wire [7:0] tx_buffer_popped_value;
    reg byte_was_sent;
    FIFObuffer #(.width(8), .size(32)) tx_buffer (
        .clk(clk), .rst(rst), 
        .push_en(tx_en), // no need for (&& !tx_full), that is internally handled
        .pop_en((tx_en || !tx_empty) && byte_was_sent && (baud_cntr == baud_div_non_zero - 1)),
        .push_data(wdata), 
        .pop_data(tx_buffer_popped_value),
        .empty(tx_empty), .full(tx_full));
        
    reg [7:0] received_byte;
    reg start_bit_detected = 0; 
    wire stop_bit_detected = ( rx_index > 7 && rx == stop_bit ) ? 1 : 0;
    FIFObuffer #(.width(8), .size(32)) rx_buffer (
        .clk(clk), .rst(rst),
        .push_en(rx_en && !rx_full && stop_bit_detected),
        .pop_en(rx_buffer_pop_i),
        .push_data(received_byte),
        .pop_data(rdata),
        .empty(rx_empty), .full(rx_full));    
    
    parameter start_bit = 1'b0;
    parameter stop_bit = 1'b1;
    wire [9:0] data_frame = {stop_bit, tx_buffer_popped_value, start_bit};
    integer index_bit_to_send;
    integer index_bit_to_send_next;
    integer rx_index;
    
    always @ (posedge clk) begin
        if (rst) begin
            {index_bit_to_send_next, index_bit_to_send, rx_index, start_bit_detected} = 0;
            baud_cntr = 0;
            byte_was_sent = 1;
            tx = 1;
        end else begin
            if (baud_cntr < baud_div_non_zero - 1)
                baud_cntr = baud_cntr + 1;
            else begin
                baud_cntr = 0;
                // transmission
                if ( (!tx_empty || tx_en) && byte_was_sent) begin
                    byte_was_sent = 0;
                end
                if ( !byte_was_sent ) begin
                    if ( index_bit_to_send < 9) begin
                        index_bit_to_send = index_bit_to_send_next;
                        tx = data_frame[index_bit_to_send];
                        index_bit_to_send_next = index_bit_to_send + 1;
                    end else begin
                        byte_was_sent = 1;
                        {index_bit_to_send, index_bit_to_send_next} = 0;
                        tx = 1;
                    end
                end
                
                // receiving
                start_bit_detected <= ( rx_index == 0 && rx == start_bit ) ? 1 : 0; // unblocking so first bit correct
                if( rx_en && !rx_full && (start_bit_detected || (rx_index > 0 && rx_index <= 7)) ) begin
                    received_byte[rx_index] = rx;
                    rx_index = rx_index + 1;
                end else
                    rx_index = 0;
            end
        end
    end
    
endmodule