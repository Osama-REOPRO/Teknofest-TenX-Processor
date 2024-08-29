module KSA_Level_1(input C_in,
  input  wire [31:0]in_a,
  input  wire [31:0]in_b,
  output wire [31:0]out_p_1,
  output wire [31:0]out_g_1,
  output C_out);
assign C_out = C_in;
GP_Block pg_0(in_a[0], in_b[0], out_p_1[0], out_g_1[0]);
GP_Block pg_1(in_a[1], in_b[1], out_p_1[1], out_g_1[1]);
GP_Block pg_2(in_a[2], in_b[2], out_p_1[2], out_g_1[2]);
GP_Block pg_3(in_a[3], in_b[3], out_p_1[3], out_g_1[3]);
GP_Block pg_4(in_a[4], in_b[4], out_p_1[4], out_g_1[4]);
GP_Block pg_5(in_a[5], in_b[5], out_p_1[5], out_g_1[5]);
GP_Block pg_6(in_a[6], in_b[6], out_p_1[6], out_g_1[6]);
GP_Block pg_7(in_a[7], in_b[7], out_p_1[7], out_g_1[7]);
GP_Block pg_8(in_a[8], in_b[8], out_p_1[8], out_g_1[8]);
GP_Block pg_9(in_a[9], in_b[9], out_p_1[9], out_g_1[9]);
GP_Block pg_10(in_a[10], in_b[10], out_p_1[10], out_g_1[10]);
GP_Block pg_11(in_a[11], in_b[11], out_p_1[11], out_g_1[11]);
GP_Block pg_12(in_a[12], in_b[12], out_p_1[12], out_g_1[12]);
GP_Block pg_13(in_a[13], in_b[13], out_p_1[13], out_g_1[13]);
GP_Block pg_14(in_a[14], in_b[14], out_p_1[14], out_g_1[14]);
GP_Block pg_15(in_a[15], in_b[15], out_p_1[15], out_g_1[15]);
GP_Block pg_16(in_a[16], in_b[16], out_p_1[16], out_g_1[16]);
GP_Block pg_17(in_a[17], in_b[17], out_p_1[17], out_g_1[17]);
GP_Block pg_18(in_a[18], in_b[18], out_p_1[18], out_g_1[18]);
GP_Block pg_19(in_a[19], in_b[19], out_p_1[19], out_g_1[19]);
GP_Block pg_20(in_a[20], in_b[20], out_p_1[20], out_g_1[20]);
GP_Block pg_21(in_a[21], in_b[21], out_p_1[21], out_g_1[21]);
GP_Block pg_22(in_a[22], in_b[22], out_p_1[22], out_g_1[22]);
GP_Block pg_23(in_a[23], in_b[23], out_p_1[23], out_g_1[23]);
GP_Block pg_24(in_a[24], in_b[24], out_p_1[24], out_g_1[24]);
GP_Block pg_25(in_a[25], in_b[25], out_p_1[25], out_g_1[25]);
GP_Block pg_26(in_a[26], in_b[26], out_p_1[26], out_g_1[26]);
GP_Block pg_27(in_a[27], in_b[27], out_p_1[27], out_g_1[27]);
GP_Block pg_28(in_a[28], in_b[28], out_p_1[28], out_g_1[28]);
GP_Block pg_29(in_a[29], in_b[29], out_p_1[29], out_g_1[29]);
GP_Block pg_30(in_a[30], in_b[30], out_p_1[30], out_g_1[30]);
GP_Block pg_31(in_a[31], in_b[31], out_p_1[31], out_g_1[31]);    
endmodule
module KSA_Level_2(
  input  wire        C_in,
  input  wire [31:0] in_p,
  input  wire [31:0] in_g,
  output wire        C_out,
  output wire [30:0] out_p,
  output wire [31:0] out_g,
  output wire [31:0] out_p_save);
    assign C_out= C_in;
    
wire [31:0] Gij;
wire [30:0] Pij;

assign C_out     = C_in;
assign out_p_save  = in_p[31:0];
assign Gij[0]    = C_in;
assign Gij[31:1] = in_g[30:0];
assign Pij       = in_p[30:0];  
    
Greyblock  GB_0(Gij[0], in_p[0], in_g[0], out_g[0]);
BlackBlock bb_0(Pij[0], Gij[1], in_p[1], in_g[1], out_g[1], out_p[0]);
BlackBlock bb_1(Pij[1], Gij[2], in_p[2], in_g[2], out_g[2], out_p[1]);
BlackBlock bb_2(Pij[2], Gij[3], in_p[3], in_g[3], out_g[3], out_p[2]);
BlackBlock bb_3(Pij[3], Gij[4], in_p[4], in_g[4], out_g[4], out_p[3]);
BlackBlock bb_4(Pij[4], Gij[5], in_p[5], in_g[5], out_g[5], out_p[4]);
BlackBlock bb_5(Pij[5], Gij[6], in_p[6], in_g[6], out_g[6], out_p[5]);
BlackBlock bb_6(Pij[6], Gij[7], in_p[7], in_g[7], out_g[7], out_p[6]);
BlackBlock bb_7(Pij[7], Gij[8], in_p[8], in_g[8], out_g[8], out_p[7]);
BlackBlock bb_8(Pij[8], Gij[9], in_p[9], in_g[9], out_g[9], out_p[8]);
BlackBlock bb_9(Pij[9], Gij[10], in_p[10], in_g[10], out_g[10], out_p[9]);
BlackBlock bb_10(Pij[10], Gij[11], in_p[11], in_g[11], out_g[11], out_p[10]);
BlackBlock bb_11(Pij[11], Gij[12], in_p[12], in_g[12], out_g[12], out_p[11]);
BlackBlock bb_12(Pij[12], Gij[13], in_p[13], in_g[13], out_g[13], out_p[12]);
BlackBlock bb_13(Pij[13], Gij[14], in_p[14], in_g[14], out_g[14], out_p[13]);
BlackBlock bb_14(Pij[14], Gij[15], in_p[15], in_g[15], out_g[15], out_p[14]);
BlackBlock bb_15(Pij[15], Gij[16], in_p[16], in_g[16], out_g[16], out_p[15]);
BlackBlock bb_16(Pij[16], Gij[17], in_p[17], in_g[17], out_g[17], out_p[16]);
BlackBlock bb_17(Pij[17], Gij[18], in_p[18], in_g[18], out_g[18], out_p[17]);
BlackBlock bb_18(Pij[18], Gij[19], in_p[19], in_g[19], out_g[19], out_p[18]);
BlackBlock bb_19(Pij[19], Gij[20], in_p[20], in_g[20], out_g[20], out_p[19]);
BlackBlock bb_20(Pij[20], Gij[21], in_p[21], in_g[21], out_g[21], out_p[20]);
BlackBlock bb_21(Pij[21], Gij[22], in_p[22], in_g[22], out_g[22], out_p[21]);
BlackBlock bb_22(Pij[22], Gij[23], in_p[23], in_g[23], out_g[23], out_p[22]);
BlackBlock bb_23(Pij[23], Gij[24], in_p[24], in_g[24], out_g[24], out_p[23]);
BlackBlock bb_24(Pij[24], Gij[25], in_p[25], in_g[25], out_g[25], out_p[24]);
BlackBlock bb_25(Pij[25], Gij[26], in_p[26], in_g[26], out_g[26], out_p[25]);
BlackBlock bb_26(Pij[26], Gij[27], in_p[27], in_g[27], out_g[27], out_p[26]);
BlackBlock bb_27(Pij[27], Gij[28], in_p[28], in_g[28], out_g[28], out_p[27]);
BlackBlock bb_28(Pij[28], Gij[29], in_p[29], in_g[29], out_g[29], out_p[28]);
BlackBlock bb_29(Pij[29], Gij[30], in_p[30], in_g[30], out_g[30], out_p[29]);
BlackBlock bb_30(Pij[30], Gij[31], in_p[31], in_g[31], out_g[31], out_p[30]);
    
endmodule
module KSA_Level_3(input wire C_in, input wire [30:0]in_p,input wire [31:0]in_g,input  wire [31:0] in_p_save,output wire C_out, output wire [28:0]out_p,
                   output wire [31:0]out_g,output wire [31:0]out_p_save);
                   
wire [30:0] Gij;
wire [28:0] Pij;

assign C_out = C_in;
assign out_p_save  = in_p_save[31:0];
assign Gij[0]    = C_in;
assign Gij[30:1] = in_g[29:0];
assign Pij       = in_p[28:0];
assign out_g[0]   = in_g[0];


Greyblock gb0(Gij[0], in_p[0], in_g[1], out_g[1]);
Greyblock gb1(Gij[1], in_p[1], in_g[2], out_g[2]);                   
BlackBlock bb_0(Pij[0], Gij[2], in_p[2], in_g[3], out_g[3], out_p[0]);
BlackBlock bb_1(Pij[1], Gij[3], in_p[3], in_g[4], out_g[4], out_p[1]);
BlackBlock bb_2(Pij[2], Gij[4], in_p[4], in_g[5], out_g[5], out_p[2]);
BlackBlock bb_3(Pij[3], Gij[5], in_p[5], in_g[6], out_g[6], out_p[3]);
BlackBlock bb_4(Pij[4], Gij[6], in_p[6], in_g[7], out_g[7], out_p[4]);
BlackBlock bb_5(Pij[5], Gij[7], in_p[7], in_g[8], out_g[8], out_p[5]);
BlackBlock bb_6(Pij[6], Gij[8], in_p[8], in_g[9], out_g[9], out_p[6]);
BlackBlock bb_7(Pij[7], Gij[9], in_p[9], in_g[10], out_g[10], out_p[7]);
BlackBlock bb_8(Pij[8], Gij[10], in_p[10], in_g[11], out_g[11], out_p[8]);
BlackBlock bb_9(Pij[9], Gij[11], in_p[11], in_g[12], out_g[12], out_p[9]);
BlackBlock bb_10(Pij[10], Gij[12], in_p[12], in_g[13], out_g[13], out_p[10]);
BlackBlock bb_11(Pij[11], Gij[13], in_p[13], in_g[14], out_g[14], out_p[11]);
BlackBlock bb_12(Pij[12], Gij[14], in_p[14], in_g[15], out_g[15], out_p[12]);
BlackBlock bb_13(Pij[13], Gij[15], in_p[15], in_g[16], out_g[16], out_p[13]);
BlackBlock bb_14(Pij[14], Gij[16], in_p[16], in_g[17], out_g[17], out_p[14]);
BlackBlock bb_15(Pij[15], Gij[17], in_p[17], in_g[18], out_g[18], out_p[15]);
BlackBlock bb_16(Pij[16], Gij[18], in_p[18], in_g[19], out_g[19], out_p[16]);
BlackBlock bb_17(Pij[17], Gij[19], in_p[19], in_g[20], out_g[20], out_p[17]);
BlackBlock bb_18(Pij[18], Gij[20], in_p[20], in_g[21], out_g[21], out_p[18]);
BlackBlock bb_19(Pij[19], Gij[21], in_p[21], in_g[22], out_g[22], out_p[19]);
BlackBlock bb_20(Pij[20], Gij[22], in_p[22], in_g[23], out_g[23], out_p[20]);
BlackBlock bb_21(Pij[21], Gij[23], in_p[23], in_g[24], out_g[24], out_p[21]);
BlackBlock bb_22(Pij[22], Gij[24], in_p[24], in_g[25], out_g[25], out_p[22]);
BlackBlock bb_23(Pij[23], Gij[25], in_p[25], in_g[26], out_g[26], out_p[23]);
BlackBlock bb_24(Pij[24], Gij[26], in_p[26], in_g[27], out_g[27], out_p[24]);
BlackBlock bb_25(Pij[25], Gij[27], in_p[27], in_g[28], out_g[28], out_p[25]);
BlackBlock bb_26(Pij[26], Gij[28], in_p[28], in_g[29], out_g[29], out_p[26]);
BlackBlock bb_27(Pij[27], Gij[29], in_p[29], in_g[30], out_g[30], out_p[27]);
BlackBlock bb_28(Pij[28], Gij[30], in_p[30], in_g[31], out_g[31], out_p[28]);


                   
endmodule                                    
module KSA_Level_4(
  input  wire   C_in,
  input  wire   [28:0] in_p,
  input  wire   [31:0] in_g,
  input  wire   [31:0] in_p_save,
  output wire   C_out,
  output wire   [24:0] out_p,
  output wire   [31:0] out_g,
  output wire   [31:0] out_p_save);


wire [28:0] Gij;
wire [24:0] Pij;

assign C_out = C_in;
assign out_p_save  = in_p_save[31:0];
assign Gij[0]    = C_in;
assign Gij[28:1] = in_g[27:0];
assign Pij = in_p[24:0];
assign out_g[2:0] = in_g[2:0];


Greyblock gb_0(Gij[0], in_p[0], in_g[3], out_g[3]);
Greyblock gb_1(Gij[1], in_p[1], in_g[4], out_g[4]);
Greyblock gb_2(Gij[2], in_p[2], in_g[5], out_g[5]);
Greyblock gb_3(Gij[3], in_p[3], in_g[6], out_g[6]);
BlackBlock bb_0(Pij[0], Gij[4], in_p[4], in_g[7], out_g[7], out_p[0]);
BlackBlock bb_1(Pij[1], Gij[5], in_p[5], in_g[8], out_g[8], out_p[1]);
BlackBlock bb_2(Pij[2], Gij[6], in_p[6], in_g[9], out_g[9], out_p[2]);
BlackBlock bb_3(Pij[3], Gij[7], in_p[7], in_g[10], out_g[10], out_p[3]);
BlackBlock bb_4(Pij[4], Gij[8], in_p[8], in_g[11], out_g[11], out_p[4]);
BlackBlock bb_5(Pij[5], Gij[9], in_p[9], in_g[12], out_g[12], out_p[5]);
BlackBlock bb_6(Pij[6], Gij[10], in_p[10], in_g[13], out_g[13], out_p[6]);
BlackBlock bb_7(Pij[7], Gij[11], in_p[11], in_g[14], out_g[14], out_p[7]);
BlackBlock bb_8(Pij[8], Gij[12], in_p[12], in_g[15], out_g[15], out_p[8]);
BlackBlock bb_9(Pij[9], Gij[13], in_p[13], in_g[16], out_g[16], out_p[9]);
BlackBlock bb_10(Pij[10], Gij[14], in_p[14], in_g[17], out_g[17], out_p[10]);
BlackBlock bb_11(Pij[11], Gij[15], in_p[15], in_g[18], out_g[18], out_p[11]);
BlackBlock bb_12(Pij[12], Gij[16], in_p[16], in_g[19], out_g[19], out_p[12]);
BlackBlock bb_13(Pij[13], Gij[17], in_p[17], in_g[20], out_g[20], out_p[13]);
BlackBlock bb_14(Pij[14], Gij[18], in_p[18], in_g[21], out_g[21], out_p[14]);
BlackBlock bb_15(Pij[15], Gij[19], in_p[19], in_g[22], out_g[22], out_p[15]);
BlackBlock bb_16(Pij[16], Gij[20], in_p[20], in_g[23], out_g[23], out_p[16]);
BlackBlock bb_17(Pij[17], Gij[21], in_p[21], in_g[24], out_g[24], out_p[17]);
BlackBlock bb_18(Pij[18], Gij[22], in_p[22], in_g[25], out_g[25], out_p[18]);
BlackBlock bb_19(Pij[19], Gij[23], in_p[23], in_g[26], out_g[26], out_p[19]);
BlackBlock bb_20(Pij[20], Gij[24], in_p[24], in_g[27], out_g[27], out_p[20]);
BlackBlock bb_21(Pij[21], Gij[25], in_p[25], in_g[28], out_g[28], out_p[21]);
BlackBlock bb_22(Pij[22], Gij[26], in_p[26], in_g[29], out_g[29], out_p[22]);
BlackBlock bb_23(Pij[23], Gij[27], in_p[27], in_g[30], out_g[30], out_p[23]);
BlackBlock bb_24(Pij[24], Gij[28], in_p[28], in_g[31], out_g[31], out_p[24]);

endmodule
module KSA_Level_5(
  input  wire        C_in,
  input  wire [24:0] in_p,
  input  wire [31:0] in_g,
  input  wire [31:0] in_p_save,
  output wire        C_out,
  output wire [16:0] out_p,
  output wire [31:0] out_g,
  output wire [31:0] out_p_save);


wire [24:0] Gij;
wire [16:0] Pij;

assign C_out      = C_in;
assign out_p_save  = in_p_save[31:0];
assign Gij[0]    = C_in;
assign Gij[24:1] = in_g[23:0];
assign Pij       = in_p[16:0];
assign out_g[6:0] = in_g[6:0];


Greyblock gb_0(Gij[0], in_p[0], in_g[7], out_g[7]);
Greyblock gb_1(Gij[1], in_p[1], in_g[8], out_g[8]);
Greyblock gb_2(Gij[2], in_p[2], in_g[9], out_g[9]);
Greyblock gb_3(Gij[3], in_p[3], in_g[10], out_g[10]);
Greyblock gb_4(Gij[4], in_p[4], in_g[11], out_g[11]);
Greyblock gb_5(Gij[5], in_p[5], in_g[12], out_g[12]);
Greyblock gb_6(Gij[6], in_p[6], in_g[13], out_g[13]);
Greyblock gb_7(Gij[7], in_p[7], in_g[14], out_g[14]);
BlackBlock bb_0(Pij[0], Gij[8], in_p[8], in_g[15], out_g[15], out_p[0]);
BlackBlock bb_1(Pij[1], Gij[9], in_p[9], in_g[16], out_g[16], out_p[1]);
BlackBlock bb_2(Pij[2], Gij[10], in_p[10], in_g[17], out_g[17], out_p[2]);
BlackBlock bb_3(Pij[3], Gij[11], in_p[11], in_g[18], out_g[18], out_p[3]);
BlackBlock bb_4(Pij[4], Gij[12], in_p[12], in_g[19], out_g[19], out_p[4]);
BlackBlock bb_5(Pij[5], Gij[13], in_p[13], in_g[20], out_g[20], out_p[5]);
BlackBlock bb_6(Pij[6], Gij[14], in_p[14], in_g[21], out_g[21], out_p[6]);
BlackBlock bb_7(Pij[7], Gij[15], in_p[15], in_g[22], out_g[22], out_p[7]);
BlackBlock bb_8(Pij[8], Gij[16], in_p[16], in_g[23], out_g[23], out_p[8]);
BlackBlock bb_9(Pij[9], Gij[17], in_p[17], in_g[24], out_g[24], out_p[9]);
BlackBlock bb_10(Pij[10], Gij[18], in_p[18], in_g[25], out_g[25], out_p[10]);
BlackBlock bb_11(Pij[11], Gij[19], in_p[19], in_g[26], out_g[26], out_p[11]);
BlackBlock bb_12(Pij[12], Gij[20], in_p[20], in_g[27], out_g[27], out_p[12]);
BlackBlock bb_13(Pij[13], Gij[21], in_p[21], in_g[28], out_g[28], out_p[13]);
BlackBlock bb_14(Pij[14], Gij[22], in_p[22], in_g[29], out_g[29], out_p[14]);
BlackBlock bb_15(Pij[15], Gij[23], in_p[23], in_g[30], out_g[30], out_p[15]);
BlackBlock bb_16(Pij[16], Gij[24], in_p[24], in_g[31], out_g[31], out_p[16]);



endmodule
module KSA_Level_6(
  input  wire        C_in,
  input  wire [16:0] in_p,
  input  wire [31:0] in_g,
  input  wire [31:0] in_p_save,
  output wire        C_out,
  output wire [31:0] out_p,
  output wire [31:0] out_g);

wire [16:0] Gij;

assign C_out       = C_in;
assign out_p       = in_p_save[31:0];
assign Gij[0]     = C_in;
assign Gij[16:1]  = in_g[15:0];
assign out_g[15:0] = in_g[15:0];

Greyblock gb_1(Gij[1], in_p[1], in_g[16], out_g[16]);
Greyblock gb_2(Gij[2], in_p[2], in_g[17], out_g[17]);
Greyblock gb_3(Gij[3], in_p[3], in_g[18], out_g[18]);
Greyblock gb_4(Gij[4], in_p[4], in_g[19], out_g[19]);
Greyblock gb_5(Gij[5], in_p[5], in_g[20], out_g[20]);
Greyblock gb_6(Gij[6], in_p[6], in_g[21], out_g[21]);
Greyblock gb_7(Gij[7], in_p[7], in_g[22], out_g[22]);
Greyblock gb_8(Gij[8], in_p[8], in_g[23], out_g[23]);
Greyblock gb_9(Gij[9], in_p[9], in_g[24], out_g[24]);
Greyblock gb_10(Gij[10], in_p[10], in_g[25], out_g[25]);
Greyblock gb_11(Gij[11], in_p[11], in_g[26], out_g[26]);
Greyblock gb_12(Gij[12], in_p[12], in_g[27], out_g[27]);
Greyblock gb_13(Gij[13], in_p[13], in_g[28], out_g[28]);
Greyblock gb_14(Gij[14], in_p[14], in_g[29], out_g[29]);
Greyblock gb_15(Gij[15], in_p[15], in_g[30], out_g[30]);
Greyblock gb_16(Gij[16], in_p[16], in_g[31], out_g[31]);


endmodule
module KSA_Level_7(
  input  wire        C_in,
  input  wire [31:0] in_p,
  input  wire [31:0] in_g,
  output wire [31:0] sum_out,
  output wire        C_out);

assign C_out= in_g[31];
assign sum_out[0]    = C_in ^ in_p[0];
assign sum_out[31:1] = in_g[30:0] ^ in_p[31:1];



endmodule




module Kogge_Stone_Adder_32bit (
  input  wire        c0,
  input  wire [31:0] in_A,
  input  wire [31:0] in_B,
  output wire [31:0] sum_out,
  output wire        C_out
);

wire [31:0] p1;
wire [31:0] g1;
wire        c1;

wire [30:0] p2;
wire [31:0] g2;
wire        c2;
wire [31:0] ps1;

wire [28:0] p3;
wire [31:0] g3;
wire        c3;
wire [31:0] ps2;

wire [24:0] p4;
wire [31:0] g4;
wire        c4;
wire [31:0] ps3;

wire [16:0] p5;
wire [31:0] g5;
wire        c5;
wire [31:0] ps4;

wire [31:0] p6;
wire [31:0] g6;
wire        c6;

KSA_Level_1 s1(c0, in_A, in_B, p1, g1, c1);
KSA_Level_2 s2(c1, p1, g1, c2, p2, g2, ps1);
KSA_Level_3 s3(c2, p2, g2, ps1, c3, p3, g3, ps2);
KSA_Level_4 s4(c3, p3, g3, ps2, c4, p4, g4, ps3);
KSA_Level_5 s5(c4, p4, g4, ps3, c5, p5, g5, ps4);
KSA_Level_6 s6(c5, p5, g5, ps4, c6, p6, g6);
KSA_Level_7 s7(c6, p6, g6, sum_out, C_out);
endmodule

module GP_Block(input wire A,B,output wire OP,OG); 
    assign OP = A ^ B;
    assign OG = A & B;
endmodule

module BlackBlock(input wire in_pi,in_gi,in_pj,in_gj,output wire out_g,out_p); 
    
    assign out_g = in_gj | (in_gi & in_pj);
    assign out_p = in_pj & in_pi;
endmodule

module Greyblock(input wire in_gi,in_pj,in_gj,output wire out_g); 
    assign out_g = in_gj | (in_gi & in_pj);
endmodule

//module Sum_block(input wire in_Carry,in_pi,output wire Sum_i); 
//    assign Sum_i = in_pi^in_Carry;
//endmodule
