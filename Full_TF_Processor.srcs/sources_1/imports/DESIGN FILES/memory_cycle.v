module memory_cycle(
    clk, rst, flush, RegWriteM, int_RD_M, MemWriteM, ResultSrcM, RD_M, PCPlus4M, WriteDataM, 
    Execute_ResultM, RegWriteW, int_RD_W, ResultSrcW, RD_W, PCPlus4W, Execute_ResultW, ReadDataW,
    WordSize_M, // byte: 00, half: 01, word: 10, unsignedbyte: 11, unsignedhalf: 100;

    mem_data_we_o,
    mem_data_adrs_o,
  	 mem_data_wdata_o,
    mem_data_wsize_o,
    mem_data_req_o,
    mem_data_done_i,
  	 mem_data_rdata_i
);
    // Declaration of I/Os
    input clk, rst, flush, RegWriteM, int_RD_M, MemWriteM, ResultSrcM;
    input [4:0] RD_M; 
    input [31:0] PCPlus4M, Execute_ResultM, WriteDataM;
    input [2:0] WordSize_M;

    output RegWriteW, ResultSrcW, int_RD_W; 
    output [4:0] RD_W;
    output [31:0] PCPlus4W, Execute_ResultW, ReadDataW;
    
    
    // mem signals 
	output reg			mem_data_we_o;
  	output reg [31:0] mem_data_adrs_o;
	output reg [31:0]	mem_data_wdata_o;
	output reg [1:0] 	mem_data_wsize_o; // 0>byte, 1>half, 2>word
  	output reg 			mem_data_req_o;
  	input 				mem_data_done_i;
  	input 	  [31:0]	mem_data_rdata_i;
    
    
    
    // Declaration of Interim Wires
    wire [31:0] ReadDataM;

    // Declaration of Interim Registers
    reg RegWriteM_r, ResultSrcM_r, int_RD_M_r;
    reg [4:0] RD_M_r;
    reg [31:0] PCPlus4M_r, Execute_ResultM_r, ReadDataM_r;
    
    
    
    
    
////    // Declaration of Module Initiation
//    Data_Memory dmem (
//        .clk(clk),
//        .rst(rst),
//        .WE(MemWriteM),
//        .WD(WriteDataM),
//        .A(Execute_ResultM),
//        .RD(ReadDataM),
//        .WS(WordSize_M)
//    );

   // Memory Stage Register Logic
	always @(posedge flush) begin
   	RegWriteM_r <= 1'b0; 
   	ResultSrcM_r <= 1'b0;
   	RD_M_r <= 5'h00;
   	PCPlus4M_r <= 32'h00000000; 
   	Execute_ResultM_r <= 32'h00000000; 
   	ReadDataM_r <= 32'h00000000;
   	int_RD_M_r <= 1'b0;
	end 
   
   
   
   
   
//	// todo: remove
//    always @(posedge clk or negedge rst) begin
//        if(rst == 1'b0) begin
//            RegWriteM_r <= 1'b0; 
//            ResultSrcM_r <= 1'b0;
//            RD_M_r <= 5'h00;
//            PCPlus4M_r <= 32'h00000000; 
//            Execute_ResultM_r <= 32'h00000000; 
//            ReadDataM_r <= 32'h00000000;
//        		int_RD_M_r <= 1'b0;
//        end else begin
//            RegWriteM_r <= RegWriteM; 
//            ResultSrcM_r <= ResultSrcM;
//            RD_M_r <= RD_M;
//            PCPlus4M_r <= PCPlus4M;
//            Execute_ResultM_r <= Execute_ResultM; 
//            ReadDataM_r <= ReadDataM;
//            int_RD_M_r <= int_RD_M;
//        end      
//    end 
    
    reg [3:0] mem_state;	
    localparam mem_init_st   = 0,
					mem_busy_st   = 1,
					mem_finish_st = 2;
	 
	always @(posedge clk or negedge rst) begin
		if(rst == 1'b0) begin
			RegWriteM_r <= 1'b0; 
			ResultSrcM_r <= 1'b0;
			RD_M_r <= 5'h00;
			PCPlus4M_r <= 32'h00000000; 
			Execute_ResultM_r <= 32'h00000000; 
			ReadDataM_r <= 32'h00000000;
			int_RD_M_r <= 1'b0;
			mem_state <= 3'b0;

			{ 	mem_data_we_o,
				mem_data_adrs_o,
				mem_data_wdata_o,
				mem_data_wsize_o,
				mem_data_req_o
				} <= 0;

		end else begin
			case(mem_state)
				mem_init_st: begin
					if (!mem_data_done_i && !mem_data_req_o) begin
						mem_data_req_o 	<= 1'b1;
						mem_data_adrs_o 	<= Execute_ResultM;

						if (MemWriteM) begin
							// write operation
							mem_data_we_o 		<= 1'b1;
							mem_data_wsize_o 	<= WordSize_M;
							mem_data_wdata_o  <= WriteDataM;
						end else begin
							// read operation
							mem_data_we_o 		<= 1'b0;
						end

						mem_state <= mem_busy_st;
					end
				end
				
				mem_busy_st: begin
					if (mem_data_done_i) begin
						mem_data_req_o <= 1'b0;

						mem_state <= mem_finish_st;
					end
				end
				
				mem_finish_st: begin
					if (!mem_data_done_i) begin
						ReadDataM_r <= mem_data_rdata_i; // ignored for writes

						mem_state <= mem_init_st;
					end
				end	
			endcase
		end
	end
    
    // Declaration of output assignments
    assign RegWriteW = RegWriteM_r;
    assign ResultSrcW = ResultSrcM_r;
    assign RD_W = RD_M_r;
    assign PCPlus4W = PCPlus4M_r;
    assign Execute_ResultW = Execute_ResultM_r;
    assign ReadDataW = ReadDataM_r;
    assign int_RD_W = int_RD_M_r;
endmodule

//module Data_Memory(
//    clk, rst, WE, WD, A, RD, WS
//);
//    input clk, rst, WE;
//    input [31:0] A, WD;
//    input [2:0] WS;
//    output [31:0] RD;

//    wire [31:0] result;
//    reg [31:0] mem [1023:0];

//    always @(posedge clk) begin
//        if (WE) begin
//           case (WS)
//                3'b000 : mem[A][7:0] = WD[7:0]; // byte signed
//                3'b001 : mem[A][15:0] = WD[15:0]; // half signed
//                3'b010 : mem[A] = WD; // word
//                default : mem[A] = 32'h0;
//            endcase
//            //mem[A >> 2] <= WD;  // Addressing by word, assuming word-aligned addresses
//        end
//    end

//    assign result = mem[A];
    
//    //Shift here (for some reason arithmetic shift doesnt' work;
//    assign RD = (rst == 1'b0) ? 32'd0 :
//                    (WS == 3'b010) ? result :          // word
//                    (WS == 3'b000) ? { {24{result[7]}}, result[7:0] } :  // byte
//                    (WS == 3'b001) ? { {16{result[15]}}, result[15:0] } :  // half
//                    (WS == 3'b100) ? result >> 24:  // unsigned byte
//                    (WS == 3'b101) ? result >> 16:   //only left case: unsigned half (WS == 3'b100)
//                32'b0;            // default
                
//    initial begin
//        // Initialize memory as needed
//        mem[0] = 32'h00000000;
//        mem[5] = 32'haaaaaaaa;
//        mem[2] = 32'hffffffff;
//        // Additional initializations if needed
//    end
//endmodule
