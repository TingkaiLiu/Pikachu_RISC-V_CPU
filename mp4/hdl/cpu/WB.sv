`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)

import rv32i_types::*;
import rv32i_packet::*;

module WB
(
    input clk,
    input rst,
    input rv32i_ctrl_packet_t ctrl,
    input rv32i_packet_t wb_in,

    // Regfile
    output rv32i_word regfile_in,
    output rv32i_reg dest
);

rv32i_word regfilemux_out;

assign regfile_in = regfilemux_out;
assign dest = wb_in.inst.rd;

rv32i_word alu_out;
rv32i_word br_en;
rv32i_word u_imm;
rv32i_word mdrreg_out;
rv32i_word pc_out;

assign alu_out = wb_in.data.alu_out;
assign br_en = {23'b0, wb_in.data.br_en};
assign u_imm = wb_in.inst.u_imm;
assign mdrreg_out = wb_in.data.mdrreg_out;
assign pc_out = wb_in.data.pc_out;

always_comb begin : REGFILEMUX

    regfilemux_out = alu_out;
    
    unique case (ctrl.regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = br_en;
        regfilemux::u_imm: regfilemux_out = u_imm;
        regfilemux::lw: regfilemux_out = mdrreg_out;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 4;
        regfilemux::lb: begin
            case (ctrl.data_mem_byte_enable)
                4'b0001: regfilemux_out = {{24{mdrreg_out[7]}}, mdrreg_out[7:0]};
                4'b0010: regfilemux_out = {{24{mdrreg_out[15]}}, mdrreg_out[15:8]};
                4'b0100: regfilemux_out = {{24{mdrreg_out[23]}}, mdrreg_out[23:16]};
                4'b1000: regfilemux_out = {{24{mdrreg_out[31]}}, mdrreg_out[31:24]};
                default: regfilemux_out = mdrreg_out;
            endcase
        end
        regfilemux::lbu: begin
            case (ctrl.data_mem_byte_enable)
                4'b0001: regfilemux_out = {24'b0, mdrreg_out[7:0]};
                4'b0010: regfilemux_out = {24'b0, mdrreg_out[15:8]};
                4'b0100: regfilemux_out = {24'b0, mdrreg_out[23:16]};
                4'b1000: regfilemux_out = {24'b0, mdrreg_out[31:24]};
                default: regfilemux_out = mdrreg_out;
            endcase
        end
        regfilemux::lh: begin
            case (ctrl.data_mem_byte_enable)
                4'b0011: regfilemux_out = {{16{mdrreg_out[15]}}, mdrreg_out[15:0]};
                4'b1100: regfilemux_out = {{16{mdrreg_out[31]}}, mdrreg_out[31:16]};
                default: regfilemux_out = mdrreg_out;
            endcase
        end
        regfilemux::lhu: begin
            case(ctrl.data_mem_byte_enable)
                4'b0011: regfilemux_out = {16'b0, mdrreg_out[15:0]};
                4'b1100: regfilemux_out = {16'b0, mdrreg_out[31:16]};
                default: regfilemux_out = mdrreg_out;
            endcase
        end
        default: `BAD_MUX_SEL;
    endcase
end

endmodule