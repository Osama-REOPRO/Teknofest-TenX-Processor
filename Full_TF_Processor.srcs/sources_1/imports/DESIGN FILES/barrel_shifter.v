module barrel_shift_32bit_rotate (
    input [31:0] in, 
    input [4:0] ctrl,
     input direction, 
     output [31:0] out);
  wire [31:0] stage16, stage8, stage4, stage2, stage1;

  // 16-bit shift
  generate
    genvar i;
    for (i = 0; i < 32; i = i + 1) begin: stage16_gen
      if (i < 16) begin
        Mux_2_by_1 mux_stage16(in[i], direction ? in[i+16] : in[(i+16)%32], ctrl[4], stage16[i]);
      end else begin
        Mux_2_by_1 mux_stage16(in[i], direction ? in[i-16] : in[(i+16)%32], ctrl[4], stage16[i]);
      end
    end
  endgenerate

  // 8-bit shift
  generate
    for (i = 0; i < 32; i = i + 1) begin: stage8_gen
      if (i < 8) begin
        Mux_2_by_1 mux_stage8(stage16[i], direction ? stage16[i+8] : stage16[(i+24)%32], ctrl[3], stage8[i]);
      end else begin
        Mux_2_by_1 mux_stage8(stage16[i], direction ? stage16[i-8] : stage16[(i+24)%32], ctrl[3], stage8[i]);
      end
    end
  endgenerate

  // 4-bit shift
  generate
    for (i = 0; i < 32; i = i + 1) begin: stage4_gen
      if (i < 4) begin
        Mux_2_by_1 mux_stage4(stage8[i], direction ? stage8[i+4] : stage8[(i+28)%32], ctrl[2], stage4[i]);
      end else begin
        Mux_2_by_1 mux_stage4(stage8[i], direction ? stage8[i-4] : stage8[(i+28)%32], ctrl[2], stage4[i]);
      end
    end
  endgenerate

  // 2-bit shift
  generate
    for (i = 0; i < 32; i = i + 1) begin: stage2_gen
      if (i < 2) begin
        Mux_2_by_1 mux_stage2(stage4[i], direction ? stage4[i+2] : stage4[(i+30)%32], ctrl[1], stage2[i]);
      end else begin
        Mux_2_by_1 mux_stage2(stage4[i], direction ? stage4[i-2] : stage4[(i+30)%32], ctrl[1], stage2[i]);
      end
    end
  endgenerate

  // 1-bit shift
  generate
    for (i = 0; i < 32; i = i + 1) begin: stage1_gen
      if (i < 1) begin
        Mux_2_by_1 mux_stage1(stage2[i], direction ? stage2[i+1] : stage2[(i+31)%32], ctrl[0], stage1[i]);
      end else begin
        Mux_2_by_1 mux_stage1(stage2[i], direction ? stage2[i-1] : stage2[(i+31)%32], ctrl[0], stage1[i]);
      end
    end
  endgenerate

  assign out = stage1;
endmodule

