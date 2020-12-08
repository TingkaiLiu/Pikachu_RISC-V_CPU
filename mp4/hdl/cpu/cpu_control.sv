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
    output logic load_pc, // sepecial for pc and if_id for stalling
    output buffer_load_mux::buffer_sel_t if_id_sel, // constant output, but assigned by control for consistency
    output buffer_load_mux::buffer_sel_t id_ex_sel, // constant output
    output buffer_load_mux::buffer_sel_t ex_mem_sel,
    output buffer_load_mux::buffer_sel_t mem_wb_sel,

    // Get control from buffers
    input rv32i_packet_t if_id,
    input rv32i_packet_t id_ex,
    input rv32i_packet_t ex_mem,
    input rv32i_packet_t mem_wb,

    // Special: from EX
    input logic br_en,
    input correct_pc_prediction,

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

// Fast decode for rs1, rs2, and opcode
logic [4:0] rs1, rs2;
rv32i_opcode opcode;
assign rs1 = if_id.data.instruction[19:15];
assign rs2 = if_id.data.instruction[24:20];
assign opcode = rv32i_opcode'(if_id.data.instruction[6:0]);

// Move the pipeline
assign load_buffers = inst_mem_resp && (!ex_mem.valid || !ex_mem.ctrl.mem || data_mem_resp);

// Buffer select
assign if_id_sel = buffer_load_mux::load_ifid;

assign ex_mem_sel = buffer_load_mux::load_exmem; // For LUI: won't overwrite needed data, but get prediction result
assign mem_wb_sel = (ex_mem.valid && ex_mem.ctrl.mem) ? buffer_load_mux::load_memwb : buffer_load_mux::use_old;

// Check for data hazard and stalling: one of the sr is the dr for previous ld
always_comb begin
    load_pc = load_buffers;
    id_ex_sel = buffer_load_mux::load_idex;
    
    // rs1
    // if (rs1 && opcode!=op_lui && opcode!=op_auipc && opcode!=op_jal) begin // won't forward for x0 or r1 has no meaning 
    if (rs1) begin
        if (correct_pc_prediction && id_ex.valid && id_ex.ctrl.wb && id_ex.ctrl.mem && rs1 == id_ex.inst.rd) begin
            id_ex_sel = buffer_load_mux::load_invalid;
            load_pc = 0;
        end
    end

    // rs2
    // if (rs2 && (opcode==op_br || opcode==op_store || opcode==op_reg)) begin // won't forward for x0 or rs2 has no meaning
    if (rs2) begin
        if (correct_pc_prediction && id_ex.valid && id_ex.ctrl.wb && id_ex.ctrl.mem && rs2 == id_ex.inst.rd) begin
            id_ex_sel = buffer_load_mux::load_invalid;
            load_pc = 0;
        end
    end
end

// IF
assign inst_mem_read = 1'b1;
assign inst_mem_write = 1'b0;

assign pcmux_sel = (!correct_pc_prediction && id_ex.valid) ? pcmux::correct : pcmux::predict;
// always_comb begin
//     pcmux_sel = pcmux::predict;

//     if (!correct_pc_prediction && id_ex.valid) begin
//         case (id_ex.inst.opcode)
//             op_jal: pcmux_sel = pcmux::alu_out;
//             op_jalr: pcmux_sel = pcmux::alu_mod2;
//             op_br: pcmux_sel = pcmux::alu_out;
//             default: pcmux_sel = pcmux::pc_plus4;
//         endcase
//     end
    
// end

// EX
assign ex_ctrl = id_ex.ctrl;

// MEM
assign mem_ctrl = ex_mem.ctrl;
assign data_mem_read = ex_mem.valid && ex_mem.ctrl.data_mem_read;
assign data_mem_write = ex_mem.valid && ex_mem.ctrl.data_mem_write;

// WB
assign wb_ctrl = mem_wb.ctrl;
// valid is handled inside WB

endmodule : cpu_control
