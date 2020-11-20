`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;
import rv32i_packet::*;

module EX
(
    input clk,
    input rst,
    input rv32i_ctrl_packet_t ctrl,
    input rv32i_packet_t ex_in,
    output rv32i_packet_t ex_out,

    // Spcial output
    output logic br_en,
    output rv32i_word alu_out,
    output logic correct_pc_prediction,
    
    // From other stages
    input rv32i_word from_exmem,
    input rv32i_word from_memwb
);

rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word cmpmux_out;

assign ex_out.data.alu_out = alu_out;
assign ex_out.data.br_en = br_en;
assign ex_out.data.correct_pc_prediction = correct_pc_prediction;

// Handle control hazard
always_comb begin
    correct_pc_prediction = 1;
    ex_out.data.next_pc = ex_in.data.next_pc;

    if (ex_in.valid) begin // For invalid inst, won't let it affect others
        case (ex_in.inst.opcode)
            op_jal: begin
                correct_pc_prediction = (alu_out == ex_in.data.next_pc);
                ex_out.data.next_pc = alu_out;
            end
            op_jalr: begin
                correct_pc_prediction = ({alu_out[31:1], 1'b0} == ex_in.data.next_pc);
                ex_out.data.next_pc = {alu_out[31:1], 1'b0};
            end 
            op_br: begin
                if (br_en) begin
                    correct_pc_prediction = (alu_out == ex_in.data.next_pc);
                    ex_out.data.next_pc = alu_out;
                end
            end 
            default: ;
        endcase
    end
    
end

rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word pc_out;
rv32i_word i_imm;
rv32i_word u_imm;
rv32i_word b_imm;
rv32i_word s_imm;
rv32i_word j_imm;

assign rs1_out = ex_in.data.rs1_out;
assign rs2_out = ex_in.data.rs2_out;
assign pc_out = ex_in.data.pc;
assign i_imm = ex_in.inst.i_imm;
assign u_imm = ex_in.inst.u_imm;
assign b_imm = ex_in.inst.b_imm;
assign s_imm = ex_in.inst.s_imm;
assign j_imm = ex_in.inst.j_imm;

alu ALU(
    .aluop(ctrl.aluop),
    .a(alumux1_out),
    .b(alumux2_out),
    .f(alu_out)
);

cmp CMP(
    .cmpop(ctrl.cmpop),
    .a(rs1_out),
    .b(cmpmux_out),
    .br_en
);

always_comb begin : ALUMUXES

    cmpmux_out = rs2_out;
	alumux1_out = rs1_out;
	alumux2_out = i_imm;

	unique case(ctrl.cmpmux_sel)
        cmpmux::rs2_out: cmpmux_out = rs2_out;
        cmpmux::i_imm: cmpmux_out = i_imm;
        default: `BAD_MUX_SEL;
    endcase

    unique case(ctrl.alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_out;
        alumux::pc_out: alumux1_out = pc_out;
    default: `BAD_MUX_SEL;
    endcase

    unique case(ctrl.alumux2_sel)
        alumux::i_imm: alumux2_out = i_imm;
        alumux::u_imm: alumux2_out = u_imm;
        alumux::b_imm: alumux2_out = b_imm;
        alumux::s_imm: alumux2_out = s_imm;
        alumux::j_imm: alumux2_out = j_imm;
        alumux::rs2_out: alumux2_out = rs2_out;
        default: `BAD_MUX_SEL;
    endcase
    
end

endmodule