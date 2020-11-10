/*
    The control ROM that accepet opcode, funct3, and funct7 as input, 
    and output all the mux control needed. 

    Created by Tingkai Liu on Nov 9, 2020
*/

import rv32i_types::*;
import rv32i_packet::*;

module control_rom(
    input rv32i_opcode opcode, 
    input logic [2:0] funct3, 
    input logic [6:0] funct7,

    output rv32i_ctrl_packet_t ctrl
);

function void set_defaults();
    // IF
    // ctrl.load_pc = 0;
    // ctrl.pcmux_sel = pcmux::pc_plus4;
    // ctrl.inst_mem_read = 0;
    // ctrl.inst_mem_write = 0; 
    // ctrl.inst_mem_byte_enable = 0;
    // EX
    ctrl.ex = 0;
    ctrl.aluop = alu_add;
    ctrl.alumux1_sel = alumux::rs1_out;
    ctrl.alumux2_sel = alumux::i_imm;
    ctrl.cmpop = beq;
    ctrl.cmpmux_sel = cmpmux::rs2_out;
    // MEM
    ctrl.mem = 0;
    ctrl.data_mem_read = 0;
    ctrl.data_mem_write = 0;
    // WB
    ctrl.wb = 0;
    ctrl.regfilemux_sel = regfilemux::alu_out;
    ctrl.load_regfile = 0;
    // FWU TODO:
    ctrl.alumux1_fw = forward::from_idex;
    ctrl.alumux2_fw = forward::from_idex;

endfunction

function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, alu_ops op);
    ctrl.alumux1_sel = sel1;
    ctrl.alumux2_sel = sel2;
    ctrl.aluop = op;
endfunction

function void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
    ctrl.cmpmux_sel = sel;
    ctrl.cmpop = op;
endfunction

function void loadRegfile(regfilemux::regfilemux_sel_t sel);
    ctrl.load_regfile = 1'b1;
    ctrl.regfilemux_sel = sel;
endfunction

always_comb begin
    set_defaults();

    case (opcode)
        op_lui: begin
            ctrl.ex = 0;
            ctrl.mem = 0;

            ctrl.wb = 1;
            ctrl.load_regfile = 1;
            ctrl.regfilemux_sel = regfilemux::u_imm;
        end
        op_auipc: begin
            ctrl.ex = 1;
            setALU(alumux::pc_out, alumux::u_imm, alu_add);

            ctrl.mem = 0;

            ctrl.wb = 1;
            loadRegfile(regfilemux::alu_out);
        end
        op_jal: begin
            ctrl.ex = 1;
            setALU(alumux::pc_out, alumux::j_imm, alu_add);

            ctrl.mem = 0;

            ctrl.wb = 1;
            loadRegfile(regfilemux::pc_plus4);
        end
        op_jalr: begin
            ctrl.ex = 1;
            setALU(alumux::rs1_out, alumux::i_imm, alu_add);

            ctrl.mem = 0;

            ctrl.wb = 1;
            loadRegfile(regfilemux::pc_plus4);
        end
        op_br: begin
            ctrl.ex = 1;
            setCMP(cmpmux::rs2_out, branch_funct3_t'(funct3));

            ctrl.ex = 0;
            ctrl.wb = 0;
        end
        op_load: begin
            ctrl.ex = 1;
            setALU(alumux::rs1_out, alumux::i_imm, alu_add);

            ctrl.mem = 1;
            ctrl.data_mem_read = 1;

            ctrl.wb = 1;
            unique case (load_funct3_t'(funct3))
                lb: loadRegfile(regfilemux::lb);
                lh: loadRegfile(regfilemux::lh);
                lw: loadRegfile(regfilemux::lw);             
                lbu: loadRegfile(regfilemux::lbu);
                lhu: loadRegfile(regfilemux::lhu);
            endcase
            
        end
        op_store: begin
            ctrl.ex = 1;
            setALU(alumux::rs1_out, alumux::s_imm, alu_add);

            ctrl.mem = 1;
            ctrl.data_mem_write = 1;

            ctrl.wb = 0;
        end
        op_imm: begin
            ctrl.ex = 1;
            ctrl.mem = 0;
            ctrl.wb = 1;

            unique case (arith_funct3_t'(funct3))
                add: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_add);
                    loadRegfile(regfilemux::alu_out);
                end
                sll: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_sll);
                    loadRegfile(regfilemux::alu_out);
                end
                slt: begin
                    setCMP(cmpmux::i_imm, blt);
                    loadRegfile(regfilemux::br_en);
                end
                sltu: begin
                    setCMP(cmpmux::i_imm, bltu);
                    loadRegfile(regfilemux::br_en);
                end
                axor: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_xor);
                    loadRegfile(regfilemux::alu_out);
                end
                sr: begin
                    setALU(alumux::rs1_out, alumux::i_imm, funct7[5] ? alu_sra : alu_srl);
                    loadRegfile(regfilemux::alu_out);
                end
                aor: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_or);
                    loadRegfile(regfilemux::alu_out);
                end
                aand: begin
                    setALU(alumux::rs1_out, alumux::i_imm, alu_and);
                    loadRegfile(regfilemux::alu_out);
                end
                default: ;
            endcase

        end
        op_reg: begin
            ctrl.ex = 1;
            ctrl.mem = 0;
            ctrl.wb = 1;
            
            unique case (arith_funct3_t'(funct3))
                add: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, funct7[5] ? alu_sub : alu_add);
                    loadRegfile(regfilemux::alu_out);
                end
                sll: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_sll);
                    loadRegfile(regfilemux::alu_out);
                end
                slt: begin
                    setCMP(cmpmux::rs2_out, blt);
                    loadRegfile(regfilemux::br_en);
                end
                sltu: begin
                    setCMP(cmpmux::rs2_out, bltu);
                    loadRegfile(regfilemux::br_en);
                end
                axor: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_xor);
                    loadRegfile(regfilemux::alu_out);
                end
                sr: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, funct7[5] ? alu_sra : alu_srl);
                    loadRegfile(regfilemux::alu_out);
                end
                aor: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_or);
                    loadRegfile(regfilemux::alu_out);
                end
                aand: begin
                    setALU(alumux::rs1_out, alumux::rs2_out, alu_and);
                    loadRegfile(regfilemux::alu_out);
                end
                default: ;
            endcase
        end

        default: $fatal("unknown opcode\n");
    endcase
end

endmodule : control_rom
