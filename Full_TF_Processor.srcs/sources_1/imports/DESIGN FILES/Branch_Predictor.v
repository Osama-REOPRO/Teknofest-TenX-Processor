//module Branch_Predictor 
//# (parameter GSHARE_SIZE = 'd2)
//(
//    input clk_i,
//    input rst_i,
//    input [31:0] pc_i,
//    input update_i,
//    input is_taken_i,
//    input [31:0] target_address_i,
//    output [31:0] next_pc,
//    output prediction
//);
//    wire [GSHARE_SIZE-1:0] gb_history;
//    wire [31:0] btb_target;
//    wire [GSHARE_SIZE-1:0] index;
    
//    Global_Branch_History GBH (
//        .clk_i(clk_i),
//        .rst_i(rst_i),
//        .update(update),
//        .taken(taken),
//        .gb_history_i(gb_history)
//    );

//    Branch_Target_Buffer BTB
    
//    (
//        .clk_i(clk_i),
//        .rst_i(reset_i),
//        .pc_index_i(pc_i),
//        .update_i(update_i),
//        .update_target_i(target_address_i),
//        .btb_target_o(btb_target)
//        );

//    assign index = gb_history ^ pc_i;

//    Pattern_History_Table PHT (
//        .clk_i(clk_i),
//        .rst_i(rst_i),
//        .index_i(index[GSHARE_SIZE+1:2]),
//        .update_i(update_i),
//        .update_prediction_i(is_taken_i),
//        .prediction_o(prediction)
//    );

////    assign next_pc = (prediction & (btb_target != 32'b0)) ? btb_target : (pc + 4);

//    assign next_pc_o = (branch_taken & |btb_target) ? btb_target : (pc + 4);


//endmodule


////module GlobalBranchHistory (
////    input clk,
////    input reset,
////    input update,
////    input taken,
////    output reg [31:0] gbhr
////);
////    always @(posedge clk or posedge reset) begin
////        if (reset) begin
////            gbhr <= 32'b0;
////        end else if (update) begin
////            gbhr <= {gbhr[30:0], taken};
////        end
////    end
////endmodule



////module BranchTargetBuffer (
////    input clk,
////    input reset,
////    input [31:0] pc,
////    input update,
////    input [31:0] target_address,
////    output reg [31:0] btb_target
////);
////    reg [31:0] btb [0:1023];  // 1024-entry BTB for example
////    integer i;

////    always @(posedge clk or posedge reset) begin
////        if (reset) begin
////            for (i = 0; i < 1024; i = i + 1) begin
////                btb[i] <= 32'b0;
////            end
////        end else if (update) begin
////            btb[pc[11:2]] <= target_address;
////        end
////    end

////    always @(posedge clk) begin
////        btb_target <= btb[pc[11:2]];
////    end
////endmodule



////module DirectionPredictor (
////    input clk,
////    input reset,
////    input [31:0] index,
////    input update,
////    input taken,
////    output reg prediction
////);
////    reg [1:0] counters [0:1023];  // 1024-entry direction predictor
////    integer i;

////    always @(posedge clk or posedge reset) begin
////        if (reset) begin
////            for (i = 0; i < 1024; i = i + 1) begin
////                counters[i] <= 2'b10;  // Weakly taken state
////            end
////        end else if (update) begin
////            if (taken) begin
////                if (counters[index] < 2'b11) counters[index] <= counters[index] + 1;
////            end else begin
////                if (counters[index] > 2'b00) counters[index] <= counters[index] - 1;
////            end
////        end
////    end

////    always @(posedge clk) begin
////        prediction <= counters[index][1];
////    end
////endmodule

