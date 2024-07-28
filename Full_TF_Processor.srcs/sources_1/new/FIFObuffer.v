module FIFObuffer
    #(
        parameter width = 8,
        parameter size = 32
    )
    (
        input clk, rst,
        input pop_en, push_en,
        input [width-1:0] push_data,
        output reg [width-1:0] pop_data,
        output empty, full
    );
    
    reg [width-1:0] buffer [0:size-1];
    reg [$clog2(size)-1:0] count;
    reg [$clog2(size)-1:0] pop_ptr;
    reg [$clog2(size)-1:0] push_ptr;
    
    // pre-calculations
    wire [$clog2(size)-1:0] push_ptr_plus_1 = push_ptr + 1;
    wire [$clog2(size)-1:0] pop_ptr_plus_1 = pop_ptr + 1;
    wire [$clog2(size)-1:0] count_plus_1 = count + 1;
    wire [$clog2(size)-1:0] count_minus_1 = count - 1;
    
    
   assign empty = count <= 0 ? 1 : 0;
   assign full = count >= size-1 ? 1 : 0;
    
   // ------------------ state machine    
   reg [2:0] state;
   localparam opaque = 3'd0, transparent = 3'd1, push_pop = 3'd2, push_discard = 3'd3, pop = 3'd4, push = 3'd5;
    
   always @(*) begin
      if(push_en && pop_en && empty)
         state = transparent;
      else if(push_en && pop_en && !empty)
         state = push_pop;
      else if(push_en && full)
         state = push_discard;
      else if (push_en && !full)
         state = push;
      else if (pop_en && count > 0)
         state = pop;
      else
         state = opaque;
   end
    
   integer i;
   always @ (posedge clk) begin
      if (rst) begin
         {pop_ptr, push_ptr, count, state} <= 0;
         pop_data <= 0;
         for (i=0; i<size; i=i+1) begin
            buffer[i] <= 0;
         end
      end else begin
         case(state)
            transparent: begin
               pop_data <= push_data;
            end
            push_pop: begin
               pop_data <= buffer[pop_ptr];
               buffer[push_ptr] <= push_data;
               
               push_ptr <= (push_ptr_plus_1==size) ? 0 : push_ptr_plus_1;
               pop_ptr <= (pop_ptr_plus_1==size) ? 0 : pop_ptr_plus_1;
            end
            push_discard: begin
               buffer[push_ptr] <= push_data;
               
               push_ptr <= (push_ptr_plus_1==size) ? 0 : push_ptr_plus_1;
               pop_ptr <= (pop_ptr_plus_1==size) ? 0 : pop_ptr_plus_1;
            end
            push: begin
               buffer[push_ptr] <= push_data;
               push_ptr <= (push_ptr_plus_1==size) ? 0 : push_ptr_plus_1;
               count <= count_plus_1;
            end
            pop: begin
               pop_data <= buffer[pop_ptr];
               pop_ptr <= (pop_ptr_plus_1==size) ? 0 : pop_ptr_plus_1;
               count <= count_minus_1;
            end
            default:;
         endcase
      end
   end
endmodule