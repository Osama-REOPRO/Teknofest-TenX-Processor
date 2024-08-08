`timescale 1ns / 1ps


module teknofest_wrapper #(
    parameter USE_SRAM  = 0,
    parameter DDR_FREQ_HZ = 300_000_000,
    parameter UART_BAUD_RATE = 9600
)(
    // Related to DDR MIG
    input logic sys_rst_n,
    input logic sys_clk, // TODO: SRAM kullan?rken bunu cpu clock olarak kullan, yoksa DDR ui_clk
    
    input logic ram_prog_rx_i, // uart rx port
    
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

    localparam CPU_FREQ_HZ = DDR_FREQ_HZ / 4; // MIG is configured 1:4

    typedef struct packed {
        logic         req;
        logic         gnt;
        logic         we;
        logic [31:0]  addr;
        logic [127:0] wdata;
        logic [15:0]  wstrb;
        logic [127:0] rdata;
        logic         rvalid;
    } mem_t; // this struct simply contains all the signals one would use to interact with a memory, basically a fast way to declare ports
    
    mem_t core_mem, programmer_mem, sel_mem;
    // sel_mem: I think this is "selected memory" so that we can switch between core_mem and programmer_mem
    // core_mem: these are simply the signals connecting the core to the main memory, I might connect these signals to the cache inside the core
    // programmer_mem: I think this is for programming the core
    
    logic system_reset_n;
    logic programmer_active;
    logic ui_clk, ui_rst_n;
    
    wire core_clk = USE_SRAM ? sys_clk : ui_clk;
    wire core_rst_n = system_reset_n && (USE_SRAM ? sys_rst_n : ui_rst_n);

   // mem signals
	// instruction mem operations
	wire 			mem_instr_we;
	wire [31:0] mem_instr_adrs;
	wire [31:0] mem_instr_wdata;
	wire [1:0]  mem_instr_wsize;
	wire 			mem_instr_req;
	wire 			mem_instr_done;
	wire [31:0] mem_instr_rdata;
	// data mem operations
	wire 			mem_data_we;
	wire [31:0] mem_data_adrs;
	wire [31:0] mem_data_wdata;
	wire [1:0]  mem_data_wsize;
	wire 			mem_data_req;
	wire 			mem_data_done;
	wire [31:0] mem_data_rdata;
	// main mem operations
	wire 			 mem_main_we;
	wire [31:0]  mem_main_adrs;
	wire [127:0] mem_main_wdata;
	wire [15:0]  mem_main_wstrb;
	wire 			 mem_main_req;
	wire 			 mem_main_done;
	wire [127:0] mem_main_rdata;
	// memory-mapped uart signals
	wire 			uart_we;
	wire [31:0] uart_adrs;
	wire [31:0] uart_wdata;
	wire 		   uart_req;
	wire 			uart_done;
	wire [31:0] uart_rdata;
         
    // Core'u burada cagirin.
	 // core instantiation
    Pipeline_top core(
		 .clk(core_clk), 
		 .rst(core_rst_n),
		 // instruction mem operations
		 .mem_instr_we_o(mem_instr_we),
		 .mem_instr_adrs_o(mem_instr_adrs),
		 .mem_instr_wdata_o(mem_instr_wdata),
		 .mem_instr_wsize_o(mem_instr_wsize),
		 .mem_instr_req_o(mem_instr_req),
		 .mem_instr_done_i(mem_instr_done),
		 .mem_instr_rdata_i(mem_instr_rdata),
		 // data mem operations
		 .mem_data_we_o(mem_data_we),
		 .mem_data_adrs_o(mem_data_adrs),
		 .mem_data_wdata_o(mem_data_wdata),
		 .mem_data_wsize_o(mem_data_wsize),
		 .mem_data_req_o(mem_data_req),
		 .mem_data_done_i(mem_data_done),
		 .mem_data_rdata_i(mem_data_rdata)
		 );

	wire [31:0] WB_UART_ADR;
	wire [31:0] WB_UART_DAT_IN;
	wire [31:0] WB_UART_DAT_OUT;
	wire 		   WB_UART_WE;
	wire 		   WB_UART_CYC;
	wire 		   WB_UART_STB;
	wire 			WB_UART_ACK;
	wire 			WB_UART_RTY;
	memory_controller mem_ctrl (
		.clk_i(core_clk),
		.rst_i(!core_rst_n),
		// instruction mem operations
		.instr_we_i(mem_instr_we),
		.instr_adrs_i(mem_instr_adrs),
		.instr_wdata_i(mem_instr_wdata),
		.instr_wsize_i(mem_instr_wsize),
		.instr_req_i(mem_instr_req),
		.instr_done_o(mem_instr_done),
		.instr_rdata_o(mem_instr_rdata),
		// data mem operations
		.data_we_i(mem_data_we),
		.data_adrs_i(mem_data_adrs),
		.data_wdata_i(mem_data_wdata),
		.data_wsize_i(mem_data_wsize),
		.data_req_i(mem_data_req),
		.data_done_o(mem_data_done),
		.data_rdata_o(mem_data_rdata),
		// main mem operations
		.main_we_o(mem_main_we),
		.main_adrs_o(mem_main_adrs),
		.main_wdata_o(mem_main_wdata),
		.main_wstrb_o(mem_main_wstrb),
		.main_req_o(mem_main_req),
		.main_done_i(mem_main_done),
		.main_rdata_i(mem_main_rdata),
		//---------------------------- wb
		.WB_ADR_O(WB_UART_ADR),
		.WB_DAT_I(WB_UART_DAT_IN),
		.WB_DAT_O(WB_UART_DAT_OUT),
		.WB_WE_O (WB_UART_WE),
		.WB_CYC_O(WB_UART_CYC),
		.WB_STB_O(WB_UART_STB),
		.WB_ACK_I(WB_UART_ACK),
		.WB_RTY_I(WB_UART_RTY)
		);
	
	wire tx; // uart tx port
	wb_s_uart uart (
		.clk_i         (core_clk),
		.rst_i         (core_rst_n),
		// wb
		.ADR_I         (WB_UART_ADR),
		.DAT_O         (WB_UART_DAT_IN),
		.DAT_I         (WB_UART_DAT_OUT),
		.WE_I          (WB_UART_WE),
		.CYC_I         (WB_UART_CYC),
		.STB_I         (WB_UART_STB),
		.ACK_O         (WB_UART_ACK),
		.RTY_O         (WB_UART_RTY),
		// uart
		.rx_i          (ram_prog_rx_i),
		.tx_o          (tx)
		);

	// core_mem struct'ini baglayin.
	// These signals should be connected to the mem controller so it can make memory requests and get responses
    assign core_mem.req = mem_main_req;
    assign core_mem.we  = mem_main_we;
    assign core_mem.addr = mem_main_adrs;
    assign core_mem.wdata = mem_main_wdata;
    assign core_mem.wstrb = mem_main_wstrb;
    assign core_mem.gnt = mem_main_done;

    assign mem_main_done = mem_main_we? core_mem.gnt : core_mem.rvalid; // todo: verify that this works
	 assign mem_main_rdata = core_mem.rdata;
    
programmer #(
    .UART_BAUD_RATE(UART_BAUD_RATE),
    .CPU_FREQ_HZ   (CPU_FREQ_HZ)
)u_programmer (
    .clk                    (sys_clk), // eski hali: (core_clk)
    .rst_n                  (sys_rst_n), // eski hali: (core_rst_n)
    .mem_req                (programmer_mem.req),
    .mem_we                 (programmer_mem.we),
    .mem_addr               (programmer_mem.addr),
    .mem_wdata              (programmer_mem.wdata),
    .mem_wstrb              (programmer_mem.wstrb),
    .ram_prog_rx_i          (ram_prog_rx_i),
    .system_reset_no        (system_reset_n),
    .programming_state_on   (programmer_active)
);

// 	BootLoader bootLoader(
//         .clk_i                    (sys_clk),
//         .rst_n_i                  (sys_rst_n),
// 
//         .mem_req_o                (programmer_mem.req),
//         .mem_we_o                 (programmer_mem.we),
//         .mem_addr_o               (programmer_mem.addr),
//         .mem_wdata_o              (programmer_mem.wdata),
//         .mem_wstrb_o              (programmer_mem.wstrb),
// 
//         .system_reset_n_o        (system_reset_n),
//         .programming_state_on   (programmer_active)
//     );
    
    
    assign sel_mem.req   = programmer_active ? programmer_mem.req   : core_mem.req;
    assign sel_mem.we    = programmer_active ? programmer_mem.we    : core_mem.we;
    assign sel_mem.addr  = programmer_active ? programmer_mem.addr  : core_mem.addr;
    assign sel_mem.wdata = programmer_active ? programmer_mem.wdata : core_mem.wdata;
    assign sel_mem.wstrb = programmer_active ? programmer_mem.wstrb : core_mem.wstrb;
    
    assign programmer_mem.rvalid = 1'b0;
    assign programmer_mem.rdata  = '0;
    assign programmer_mem.gnt    = programmer_active && sel_mem.gnt;
    
    assign core_mem.rvalid = ~programmer_active && sel_mem.rvalid;
    assign core_mem.rdata  = {128{~programmer_active}} & sel_mem.rdata;
    assign core_mem.gnt    = ~programmer_active && sel_mem.gnt; // eski hali: programmer_active && sel_mem.gnt
    
    
    teknofest_memory #(
        .USE_SRAM   (USE_SRAM),
        .MEM_DEPTH  (16),
		  .MEM_START_ADRS('h80000000)
    )u_teknofest_memory(
        .clk_i  (sys_clk),
        .rst_ni (sys_rst_n),
        .req    (sel_mem.req   ),
        .gnt    (sel_mem.gnt   ),
        .we     (sel_mem.we    ),
        .addr   (sel_mem.addr  ),
        .wdata  (sel_mem.wdata ),
        .wstrb  (sel_mem.wstrb ),
        .rdata  (sel_mem.rdata ),
        .rvalid (sel_mem.rvalid),
        .sys_rst (sys_rst_n),
        .sys_clk,
        .ui_clk,
        .ui_rst_n,
        .ddr2_dq,     
        .ddr2_dqs_n,  
        .ddr2_dqs_p,  
        .ddr2_addr,   
        .ddr2_ba,     
        .ddr2_ras_n,  
        .ddr2_cas_n,  
        .ddr2_we_n,   
        .ddr2_reset_n,
        .ddr2_ck_p,   
        .ddr2_ck_n,   
        .ddr2_cke,    
        .ddr2_cs_n,   
        .ddr2_dm,     
        .ddr2_odt     
    );
    
    
   

endmodule
