//module BranchPredictor (
//    input clk,
//    input reset,
//    input [31:0] pc,
//    input update,
//    input taken,
//    input [31:0] target_address,
//    output [31:0] next_pc,
//    output prediction
//);
//    wire [31:0] gbhr;
//    wire [31:0] btb_target;
//    wire [31:0] index;
    
//    GlobalBranchHistory gbh (
//        .clk(clk),
//        .reset(reset),
//        .update(update),
//        .taken(taken),
//        .gbhr(gbhr)
//    );

//    BranchTargetBuffer btb (
//        .clk(clk),
//        .reset(reset),
//        .pc(pc),
//        .update(update),
//        .target_address(target_address),
//        .btb_target(btb_target)
//    );

//    assign index = gbhr ^ pc;

//    DirectionPredictor dp (
//        .clk(clk),
//        .reset(reset),
//        .index(index[11:2]),
//        .update(update),
//        .taken(taken),
//        .prediction(prediction)
//    );

//    assign next_pc = (prediction & (btb_target != 32'b0)) ? btb_target : (pc + 4);
//endmodule


//module GlobalBranchHistory (
//    input clk,
//    input reset,
//    input update,
//    input taken,
//    output reg [31:0] gbhr
//);
//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            gbhr <= 32'b0;
//        end else if (update) begin
//            gbhr <= {gbhr[30:0], taken};
//        end
//    end
//endmodule



//module BranchTargetBuffer (
//    input clk,
//    input reset,
//    input [31:0] pc,
//    input update,
//    input [31:0] target_address,
//    output reg [31:0] btb_target
//);
//    reg [31:0] btb [0:1023];  // 1024-entry BTB for example
//    integer i;

//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            for (i = 0; i < 1024; i = i + 1) begin
//                btb[i] <= 32'b0;
//            end
//        end else if (update) begin
//            btb[pc[11:2]] <= target_address;
//        end
//    end

//    always @(posedge clk) begin
//        btb_target <= btb[pc[11:2]];
//    end
//endmodule



//module DirectionPredictor (
//    input clk,
//    input reset,
//    input [31:0] index,
//    input update,
//    input taken,
//    output reg prediction
//);
//    reg [1:0] counters [0:1023];  // 1024-entry direction predictor
//    integer i;

//    always @(posedge clk or posedge reset) begin
//        if (reset) begin
//            for (i = 0; i < 1024; i = i + 1) begin
//                counters[i] <= 2'b10;  // Weakly taken state
//            end
//        end else if (update) begin
//            if (taken) begin
//                if (counters[index] < 2'b11) counters[index] <= counters[index] + 1;
//            end else begin
//                if (counters[index] > 2'b00) counters[index] <= counters[index] - 1;
//            end
//        end
//    end

//    always @(posedge clk) begin
//        prediction <= counters[index][1];
//    end
//endmodule

