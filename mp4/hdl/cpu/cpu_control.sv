/*
    CPU control 
    Created by Tingkai Liu on Nov 8, 2020
*/

/*
    Unlike traditional control, our control handle the whole packet 
    and pass the control part to corresponding components
*/

import rv32i_types::*;
import rv32i_packet::*;

module cpu_control(
    input logic clk, rst,
    
    // Buffers loads
    output logic load_buffers, // load all buffer, which is equivilant to move the pipeline
    output buffer_load_mux::buffer_sel_t if_id_sel, // constant output, but assigned by control for consistency
    output buffer_load_mux::buffer_sel_t id_ex_sel, // constant output
    output buffer_load_mux::buffer_sel_t ex_mem_sel,
    output buffer_load_mux::buffer_sel_t mem_wb_sel,

    // Get control from buffers
    // input rv32i_packet_t if_id,
    input rv32i_packet_t id_ex,
    input rv32i_packet_t ex_mem,
    input rv32i_packet_t mem_wb,

    // Special: from EX
    input logic br_en,

    // Stages
    output pcmux::pcmux_sel_t pcmux_sel, // IF control: only useful for handling branch 
    // output rv32i_ctrl_packet_t id_ctrl, // constant output, but assigned by control for consistency
    output rv32i_ctrl_packet_t ex_ctrl,
    output rv32i_ctrl_packet_t mem_ctrl,
    output rv32i_ctrl_packet_t wb_ctrl,

    // Memory
    output logic inst_mem_read,
    output logic inst_mem_write,
    input logic inst_mem_resp,

    output logic data_mem_read,
    output logic data_mem_write,
    input logic data_mem_resp
);

// Move the pipeline
always_ff @ (posedge clk)
begin
    load_buffers <= inst_mem_resp && (!ex_mem.ctrl.mem || data_mem_resp);
    inst_mem_read <= !load_buffers;
end

// Buffers
assign if_id_sel = buffer_load_mux::load_ifid;
assign id_ex_sel = buffer_load_mux::load_idex;
assign ex_mem_sel = id_ex.ctrl.ex ? buffer_load_mux::load_exmem : buffer_load_mux::use_old;
assign mem_wb_sel = ex_mem.ctrl.mem ? buffer_load_mux::load_memwb : buffer_load_mux::use_old;

assign inst_mem_write = 0;
// IF TODO: use a module to handle control hazard?
always_comb begin
    pcmux_sel = pcmux::pc_plus4;

    case (id_ex.inst.opcode)
        op_jal: pcmux_sel = pcmux::alu_out;
        op_jalr: pcmux_sel = pcmux::alu_mod2;
        op_br: if (br_en) pcmux_sel = pcmux::alu_out;
        default: ;
    endcase
end

// EX
assign ex_ctrl = id_ex.ctrl;

// MEM
assign mem_ctrl = ex_mem.ctrl;
assign data_mem_read = ex_mem.ctrl.data_mem_read;
assign data_mem_write = ex_mem.ctrl.data_mem_write;

// WB
assign wb_ctrl = mem_wb.ctrl;


endmodule : cpu_control
