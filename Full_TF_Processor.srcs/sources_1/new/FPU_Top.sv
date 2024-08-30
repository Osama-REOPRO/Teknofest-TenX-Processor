include "control_signals.vh";
import fp_wire::*; 

module FPU_top
(
    input clk_i,
    input rst_i,
    input [31:0] rs1_i, rs2_i, rs3_i,
    input [4:0] fpu_control_i,

    input [2:0] fcsr_rmode_i,
    input [2:0] isntr_rmode_i,
    input fpu_enable_i,
    output reg [31:0] fpu_result_o,
    output reg [4:0] fpu_flags_o, 
    output reg fpu_ready_o
    );
    
    fp_unit_in_type fp_unit_i;
    fp_unit_out_type fp_unit_o;
    always @(posedge clk_i or negedge rst_i) begin
        if(!rst_i) begin
            //fp_unit_o <= init_fp_unit_out_type;
            fp_unit_i <= init_fp_unit_in_type;
            fpu_result_o <= 0;
            fpu_flags_o <= 0;
            fpu_ready_o <= 1'b1;
        end
        else if (fpu_enable_i) begin
            
            fp_unit_i.fp_exe_i.enable <= 1'b1;
            fp_unit_i.fp_exe_i.data1 <= rs1_i;
            fp_unit_i.fp_exe_i.data2 <= rs2_i;
            fp_unit_i.fp_exe_i.data3 <= rs3_i;
            fp_unit_i.fp_exe_i.fmt <= 0;
            fp_unit_i.fp_exe_i.op.fcvt_op[0] <= fpu_control_i[3];
            case (fpu_control_i)
                `FPU_ADD:       fp_unit_i.fp_exe_i.op.fadd      <= 1;
                `FPU_SUB:       fp_unit_i.fp_exe_i.op.fsub     <= 1;
                `FPU_MUL:       fp_unit_i.fp_exe_i.op.fmul     <= 1;
                `FPU_DIV:       fp_unit_i.fp_exe_i.op.fdiv     <= 1;
                `FPU_SQRT:      fp_unit_i.fp_exe_i.op.fsqrt    <= 1;
                `FPU_FSGNJ:     fp_unit_i.fp_exe_i.op.fsgnj     <= 1;
                `FPU_FMADD:     fp_unit_i.fp_exe_i.op.fmadd    <= 1;
                `FPU_FMSUB:     fp_unit_i.fp_exe_i.op.fmsub    <= 1;
                `FPU_FNMSUB:    fp_unit_i.fp_exe_i.op.fnmsub   <= 1;
                `FPU_FNMADD:    fp_unit_i.fp_exe_i.op.fnmadd   <= 1;
                `FPU_CMP:       fp_unit_i.fp_exe_i.op.fcmp    <= 1;
                `FPU_MIN_MAX:   fp_unit_i.fp_exe_i.op.fmax   <= 1;
                `FPU_CLASS:     fp_unit_i.fp_exe_i.op.fclass   <= 1;
                `FPU_CVT_I2F , `FPU_CVT_I2F_U:  fp_unit_i.fp_exe_i.op.fcvt_i2f <= 1;
                `FPU_CVT_F2I , `FPU_CVT_F2I_U:  fp_unit_i.fp_exe_i.op.fcvt_f2i <= 1;
                `FPU_RETURN_A:  fp_unit_i.fp_exe_i.op.fmv_f2i <= 1;
                //default:        fp_unit_i.fp_exe_i.op <= '0; // Default case to handle undefined op
            endcase
            if(&isntr_rmode_i) fp_unit_i.fp_exe_i.rm <= fcsr_rmode_i;
            else fp_unit_i.fp_exe_i.rm <= isntr_rmode_i;
            
           fpu_ready_o <= 1'b0;
            if(fp_unit_o.fp_exe_o.ready) begin
                fpu_result_o <= fp_unit_o.fp_exe_o.result;
                fpu_flags_o <= fp_unit_o.fp_exe_o.flags;
                fp_unit_i <= init_fp_unit_in_type;
                fp_unit_i.fp_exe_i.enable <= 0;
            end 
            fpu_ready_o <= fp_unit_o.fp_exe_o.ready;
        end else fpu_ready_o <= 1'b0;
    end
    
   fp_unit fp_unit_comp
	(
		.reset ( rst_i ),
		.clock ( clk_i ),
		.fp_unit_i ( fp_unit_i ),
		.fp_unit_o ( fp_unit_o )
	);
    
endmodule
