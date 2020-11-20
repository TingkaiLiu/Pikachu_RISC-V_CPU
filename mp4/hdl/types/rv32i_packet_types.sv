package rv32i_packet;

import rv32i_types::*;

// The components of a instruction
typedef struct packed {
    logic [2:0] funct3;
    logic [6:0] funct7;
    rv32i_opcode opcode;
    rv32i_word i_imm;
    rv32i_word s_imm;
    rv32i_word b_imm;
    rv32i_word u_imm;
    rv32i_word j_imm;
    logic [4:0] rs1;
    logic [4:0] rs2;
    logic [4:0] rd;
    logic trap;
} rv32i_inst_packet_t;

// The data passed in the pipeline, filled by different stages
typedef struct packed {
    // IF
    rv32i_word pc;
    rv32i_word instruction; // raw instuction
    rv32i_word next_pc; // for branch pridiction and control hazard
    // ID
    rv32i_word rs1_out;
    rv32i_word rs2_out;
    // EX
    rv32i_word alu_out;
    logic br_en;
    // MEM
    rv32i_word mdrreg_out;
    logic [3:0] rmask;
    logic [3:0] wmask;
    rv32i_word mem_addr;
    rv32i_word mem_rdata;
    rv32i_word mem_wdata;
} rv32i_data_packet_t;

// The packet gnerated by ID, handled by control logic
typedef struct packed {
    // IF
    // logic load_pc,
    // pcmux::pcmux_sel_t pcmux_sel,
    // logic inst_mem_read,
    // logic inst_mem_write,
    // logic [3:0] inst_mem_byte_enable,
    // EX
    logic ex; // Indicate whether EX stage is needed
    alu_ops aluop;
    alumux::alumux1_sel_t alumux1_sel;
    alumux::alumux2_sel_t alumux2_sel;
    branch_funct3_t cmpop;
    cmpmux::cmpmux_sel_t cmpmux_sel;
    logic correct_pc_prediction; // For control hazard
    // MEM
    logic mem; // Indicate whether MEM stage is needed. 
    logic data_mem_read;
    logic data_mem_write;
    // WB
    logic wb; // Indicate whether WB stage is needed. Same value as load_regfile...
    regfilemux::regfilemux_sel_t regfilemux_sel;
    logic load_regfile;
    // FWU
    forward::forward_t alumux1_fw;
    forward::forward_t alumux2_fw;
} rv32i_ctrl_packet_t;

// The packet passed in the pipeline and stored by the buffers
typedef struct packed {
    logic valid; // For control hazard
    rv32i_data_packet_t data;
    rv32i_inst_packet_t inst; // decoded instruction
    rv32i_ctrl_packet_t ctrl;
} rv32i_packet_t;

endpackage : rv32i_packet