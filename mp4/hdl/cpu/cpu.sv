/*
    The top level of cpu
    Created by Tingkai Liu on Nov 8, 2020
*/

module cpu(
    input logic clk, rst,

    // Memory
    output logic inst_mem_read,
    output logic inst_mem_write,
    output logic inst_mem_byte_enable,
    input logic inst_mem_resp,

    output logic data_mem_read,
    output logic data_mem_write,
    output logic data_mem_byte_enable,
    input logic data_mem_resp
);

// Internal connections
// Buffers loads
logic load_buffers;
buffer_load_mux::buffer_sel_t if_id_sel;
buffer_load_mux::buffer_sel_t id_ex_sel;
buffer_load_mux::buffer_sel_t ex_mem_sel;
buffer_load_mux::buffer_sel_t mem_wb_sel;

rv32i_packet_t id_ex;
rv32i_packet_t ex_mem;
rv32i_packet_t mem_wb;

logic br_en;
rv32i_word alu_out;

pcmux::pcmux_sel_t pc_mux_sel;
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
logic [4:0] src_a, src_b, dest;
logic [31:0] reg_a, reg_b;

cpu_control control(.*);

control_rom control_rom0(.*);

assign ex_in = id_ex;
assign mem_in = ex_mem;
assign wb_in = mem_wb;

// Datapath 
IF IF0(.*, .load_pc(load_buffers));

buffer IF_ID(
    .*, .load(load_buffers), .buffer_sel(if_id_sel),
    .packet_in_old(0), .packet_in_new(if_out), .packet_out(id_in)
);

ID ID0(.*);

regfile regfile0(.*);

buffer ID_EX(
    .*, .load(load_buffers), .buffer_sel(id_ex_sel),
    .packet_in_old(id_in), .packet_in_new(id_out), .packet_out(id_ex)
);

EX EX0(.*, .ctrl(ex_ctrl));

buffer EX_MEM(
    .*, .load(load_buffers), .buffer_sel(ex_mem_sel),
    .packet_in_old(ex_in), .packet_in_new(ex_out), .packet_out(ex_mem)
);

MEM MEM0(.*, .ctrl(mem_ctrl));

buffer MEM_WB(
    .*, .load(load_buffers), .buffer_sel(mem_wb_sel),
    .packet_in_old(mem_in), .packet_in_new(mem_out), .packet_out(mem_wb)
);

WB WB0(.*, .ctrl(wb_ctrl));


endmodule : cpu