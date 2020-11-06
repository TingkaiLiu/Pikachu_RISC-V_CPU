package rv32i_packet;

import rv32i_types::*;

typedef struct packed {
    rv32i_word pc_out;
    rv32i_word instruction;
    rv32i_word rs1_out;
    rv32i_word rs2_out;
    rv32i_word mdrreg_out;
} rv32i_data_packet_t;

typedef struct packed {
    // IF
    logic load_pc;
    pcmux::pcmux_sel_t pcmux_sel;
    logic inst_mem_read,
    logci inst_mem_resp,
    // ID
    logic load_ir;
    // EX
    alu_ops aluop,
    alumux::alumux1_sel_t alumux1_sel,
    alumux::alumux2_sel_t alumux2_sel,
    branch_funct3_t cmpop,
    cmpmux::cmpmux_sel_t cmpmux_sel,
    logic br_en;
    // FWU
    forward::forward_t alumux1_fw,
    forward::forward_t alumux2_fw,
    // MEM
    logic data_mem_read,
    logic data_mem_write,
    logic data_mem_resp,
    // WB
    regfilemux::regfilemux_sel_t regfilemux_sel,
    logic [3:0] mem_byte_enable,
    logic load_regfile,
    logic [4:0] dest,
    // IR
    logic [2:0] funct3,
    logic [6:0] funct7,
    logic rv32i_opcode opcode,
    logic [31:0] i_imm,
    logic [31:0] s_imm,
    logic [31:0] b_imm,
    logic [31:0] u_imm,
    logic [31:0] j_imm,
    logic [4:0] rs1,
    logic [4:0] rs2,
    logic [4:0] rd
} rv32i_ctrl_packet_t;

typedef struct packed {
    rv32i_data_packet_t data,
    rv32i_ctrl_packet_t ctrl
} rv32i_packet_t;

endpackage : rv32i_packet;