/*
    The top level of cpu
    Created by Tingkai Liu on Nov 8, 2020
*/

import rv32i_types::*;
import rv32i_packet::*;

module cpu(
    input logic clk, rst,

    // Memory
    output rv32i_word inst_mem_address,
    output logic inst_mem_read,
    output logic inst_mem_write,
    output logic [3:0] inst_mem_byte_enable,
    input rv32i_word inst_mem_rdata,
    output rv32i_word inst_mem_wdata,
    input logic inst_mem_resp,

    output rv32i_word data_mem_address,
    output logic data_mem_read,
    output logic data_mem_write,
    output logic [3:0] data_mem_byte_enable,
    input rv32i_word data_mem_rdata,
    output rv32i_word data_mem_wdata,
    input logic data_mem_resp
);

// Internal connections
// Buffers loads
logic load_buffers;
logic load_pc;
buffer_load_mux::buffer_sel_t if_id_sel;
buffer_load_mux::buffer_sel_t id_ex_sel;
buffer_load_mux::buffer_sel_t ex_mem_sel;
buffer_load_mux::buffer_sel_t mem_wb_sel;

rv32i_packet_t if_id;
rv32i_packet_t id_ex;
rv32i_packet_t ex_mem;
rv32i_packet_t mem_wb;

logic br_en;
rv32i_word alu_out;
logic correct_pc_prediction;
logic [3:0] rmask;

pcmux::pcmux_sel_t pcmux_sel;
rv32i_ctrl_packet_t ex_ctrl;
rv32i_ctrl_packet_t mem_ctrl;
rv32i_ctrl_packet_t wb_ctrl;

rv32i_packet_t if_out, id_in, id_out, ex_in, ex_out, mem_in, mem_out, wb_in;

// Connection with control rom 
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
rv32i_ctrl_packet_t ctrl;

// Connection with regfile
logic load_regfile;
logic [31:0] regfile_in;
logic [4:0] rs1, rs2, dest;
logic [31:0] reg_a, reg_b;

cpu_control control(.*);

control_rom control_rom0(.*);

assign id_in = if_id;
assign ex_in = id_ex;
assign mem_in = ex_mem;
assign wb_in = mem_wb;

// Datapath 
IF IF(.*);

buffer IF_ID(
    .*, .load(load_pc), .buffer_sel(if_id_sel),
    .packet_in_old(0), .packet_in_new(if_out), .packet_out(if_id)
);

ID ID(.*);

regfile regfile(
    .*, .load(load_regfile), .in(regfile_in),
    .src_a(rs1), .src_b(rs2)
);

buffer ID_EX(
    .*, .load(load_buffers), .buffer_sel(id_ex_sel),
    .packet_in_old(id_in), .packet_in_new(id_out), .packet_out(id_ex)
);

EX EX(.*, .ctrl(ex_ctrl), .from_exmem(0), .from_memwb(0)); // TODO:

buffer EX_MEM(
    .*, .load(load_buffers), .buffer_sel(ex_mem_sel),
    .packet_in_old(ex_in), .packet_in_new(ex_out), .packet_out(ex_mem)
);

MEM MEM(.*, .ctrl(mem_ctrl));

buffer MEM_WB(
    .*, .load(load_buffers), .buffer_sel(mem_wb_sel),
    .packet_in_old(mem_in), .packet_in_new(mem_out), .packet_out(mem_wb)
);

WB WB(.*, .ctrl(wb_ctrl));


endmodule : cpu