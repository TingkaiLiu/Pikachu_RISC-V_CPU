`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;
import rv32i_packet::*;

module EX
(
    input clk,
    input rst,
    input rv32i_ctrl_packet_t ctrl,
    output rv32i_packet_t packet_out,
    // From other stages
    input rv32i_packet_t packet_in,
    input rv32i_word from_exmem,
    input rv32i_word from_memwb
);

rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word alu_out;
rv32i_word cmpmux_out;
logic br_en;

assign packet_out.data.alu_out = alu_out;
assign packet_out.ctrl.br_en = br_en;

rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word i_imm;
rv32i_word u_imm;
rv32i_word b_imm;
rv32i_word s_imm;
rv32i_word j_imm;

assign rs1_out = packet_in.data.rs1_out;
assign rs2_out = packet_in.data.rs2_out;
assign i_imm = packet_in.ctrl.i_imm;
assign u_imm = packet_in.ctrl.u_imm;
assign b_imm = packet_in.ctrl.b_imm;
assign s_imm = packet_in.ctrl.s_imm;
assign j_imm = packet_in.ctrl.j_imm;

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

    cmp_mux_out = rs2_out;
	alumux1_out = rs1_out;
	alumux2_out = i_imm;

	unique case(ctrl.cmpmux_sel)
        cmpmux::rs2_out: cmp_mux_out = rs2_out;
        cmpmux::i_imm: cmp_mux_out = i_imm;
        default: `BAD_MUX_SEL;
    endcase

    unique case(ctrl.alumux1_fw)
        forward::from_idex:
            unique case(ctrl.alumux1_sel)
                alumux::rs1_out: alumux1_out = rs1_out;
                alumux::pc_out: alumux1_out = pc_out;
            default: `BAD_MUX_SEL;
            endcase
        forward::from_exmem: alumux1_out = from_exmem;
        forward::from_memwb: alumux1_out = from_memwb;
        default: `BAD_MUX_SEL;
    endcase

    unique case(ctrl.alumux2_fw)
        forward::from_idex:
            unique case(ctrl.alumux2_sel)
                alumux::i_imm: alumux2_out = i_imm;
                alumux::u_imm: alumux2_out = u_imm;
                alumux::b_imm: alumux2_out = b_imm;
                alumux::s_imm: alumux2_out = s_imm;
                alumux::j_imm: alumux2_out = j_imm;
                alumux::rs2_out: alumux2_out = rs2_out;
                default: `BAD_MUX_SEL;
            endcase
        forward::from_exmem: alumux2_out = from_exmem;
        forward::from_memwb: alumux2_out = from_memwb;
        default: `BAD_MUX_SEL;
    endcase
    
end

endmodule