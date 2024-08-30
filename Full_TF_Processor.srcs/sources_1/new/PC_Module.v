module PC_Module
 #(parameter START_ADRS = 32'h80000000)
(
    input clk_i,rst_i, flush_i,
    input [31:0]pc_next_i,
    input increment_pc_i,
    output reg [31:0] pc_o,
    output reg pc_incremented_o
    );
    reg flushing;

    always @(posedge flush_i) begin
        //pc_o <= START_ADRS;            
        pc_incremented_o <= 1'b0;
    end
    always @(posedge clk_i or negedge rst_i) begin
        if(!rst_i) begin
            pc_o <= START_ADRS;      
            pc_incremented_o <= 1'b0;
        end else begin
            if (increment_pc_i && !pc_incremented_o) begin
                pc_o <= pc_next_i;
                pc_incremented_o <= 1'b1;
            end
            
            if (!increment_pc_i) pc_incremented_o <= 1'b0;
       end
    end
endmodule