`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company:     TUBITAK - TUTEL
// Project:     TEKNOFEST CIP TASARIM YARISMASI
// Engineer:    -
// Version:     1.0
//*************************************************************************************************************************************************//
// Create Date:
// Module Name: teknofest_wrapper
//
// Description: 
//
//*************************************************************************************************************************************************//
// Copyright 2024 TUTEL (IC Design and Training Laboratory - TUBITAK).
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


module teknofest_memory #(
    parameter USE_SRAM  = 1,
    parameter MEM_DEPTH = 16, // Only valid for SRAM/ means the memory array will have 16 entries (each 128 bits wide)
	 parameter MEM_START_ADRS = 0
)(
    input  logic        clk_i,
    input  logic        rst_ni,
    // Memory interface between the core and memory
    input  logic        req,	// this is like mem_op or like Cyc, it signals the start of an operation
    output logic        gnt,  // don't know what this is
										 // gnt is set equal to req on each clock cycle
										 // rvalid only set when gnt is set (look at line no 112)
										 // remember this is an output not an input
    input  logic        we,	// write enable
    input  logic[31:0]  addr, // byte address
    input  logic[127:0] wdata, // these are 16 bytes of data that are available in each sram entry
    input  logic[15:0]  wstrb, //  similar to valid_bytes, determines which of the 
    output logic[127:0] rdata,
    output logic        rvalid, // read data valid
    
    // Related to DDR MIG
    input logic sys_rst,
    input logic sys_clk,
    
    output logic ui_clk,
    output logic ui_rst_n,
    
    inout  [15:0] ddr2_dq,
    inout  [1:0]  ddr2_dqs_n,
    inout  [1:0]  ddr2_dqs_p,
    output [12:0] ddr2_addr,
    output [2:0]  ddr2_ba,
    output        ddr2_ras_n,
    output        ddr2_cas_n,
    output        ddr2_we_n,
    output        ddr2_reset_n,
    output        ddr2_ck_p,
    output        ddr2_ck_n,
    output        ddr2_cke,
    output        ddr2_cs_n,
    inout  [1:0]  ddr2_dm,
    output        ddr2_odt
);

    wire [31:0] addr_offset = addr - 32'h80000000;

    wire        sys_clk_i    = sys_clk;
    wire [26:0] app_addr     = addr_offset[30:4];
    wire [2:0]  app_cmd      = ~we ? (3'b001) : (wstrb != 16'hFFFF ? 3'b001 : 3'b000);
    wire        app_en       = req;
    wire [127:0]app_wdf_data = wdata;
    wire        app_wdf_end  = req && we;
    wire [15:0] app_wdf_mask = ~wstrb;
    wire        app_wdf_wren = req && we;
    
    wire [127:0]app_rd_data;
    wire        app_rd_data_valid;
    wire        app_rd_data_end;
    wire        app_wdf_rdy;
    wire        app_rdy;
    
    wire        app_sr_req = 1'b0;
    wire        app_ref_req = 1'b0;
    wire        app_zq_req  = 1'b0;
    wire        app_sr_active;
    wire        app_ref_ack;
    wire        app_zq_ack;
    
    wire        ui_clk_sync_rst;
    assign      ui_rst_n = ~ui_clk_sync_rst;
    wire        init_calib_complete;
    
    
    


    
    generate
        if(USE_SRAM == 1) begin : gen_sram
            localparam ADDR_W = $clog2(MEM_DEPTH);
            logic [127:0] memory [0 : MEM_DEPTH];
            
            always_ff@(posedge clk_i) begin
                if(req && we) begin		// write operation
                    for(int i=0; i<16; i++) begin
                        if(wstrb[i]) 
                        	 // only write bytes for which wstrb is asserted
                            memory[addr_offset[4+:ADDR_W]][i*8+:8] <= wdata[i*8 +: 8];
                    end
                end else if(req && ~we) begin // read operation
                    rdata <= memory[addr_offset[4+:ADDR_W]];
                end
            end
            
            always_ff@(posedge clk_i or negedge rst_ni) begin
                if(~rst_ni) begin
                    rvalid <= 1'b0;
                    gnt <= 1'b0;
                end else begin
                    rvalid <= req && ~we && gnt;
                    gnt <= req;
                end
            end
            
            //assign gnt = 1'b1;
            
            assign init_calib_complete = 1'b1;
            
        end else begin : gen_ddr
        
            assign rdata        = app_rd_data;
            assign rvalid       = app_rd_data_valid;
            assign gnt          = (we ? (app_wdf_rdy && app_rdy) : app_rdy) && init_calib_complete;
    
            mig_7series_0 u_ddr(.*);				

        end
    endgenerate

endmodule
