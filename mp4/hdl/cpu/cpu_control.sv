/*
    CPU control 
    Created by Tingkai Liu on Nov 8, 2020
*/

/*
    Unlike traditional control, our control handle the whole packet 
    and pass the control part to corresponding components
*/

module cpu_control(
    input logic clk, rst,
    
    // For ID to access control rom
    // input rv32i_opcode opcode, 
    // input logic [2:0] funct3, 
    // input logic [6:0] funct7,
    // output rv32i_ctrl_packet_t ctrl,
    
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
    output pcmux::pcmux_sel_t pc_mux_sel, // IF control: only useful for handling branch 
    // output rv32i_ctrl_packet_t id_ctrl, // constant output, but assigned by control for consistency
    output rv32i_ctrl_packet_t ex_ctrl,
    output rv32i_ctrl_packet_t mem_ctrl,
    output rv32i_ctrl_packet_t wb_ctrl,

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

// Move the pipeline
assign load_buffers = inst_mem_resp && (!id_ex.ctrl.mem || edata_mem_resp);

// Buffers
assign if_id_sel = buffer_load_mux::load_ifid;
assign id_ex_sel = buffer_load_mux::load_idex;
assign ex_mem_sel = id_ex.ctrl.ex ? buffer_load_mux::exmem : buffer_load_mux::use_old;
assign mem_wb_sel = id_ex.ctrl.mem ? buffer_load_mux::memwb : buffer_load_mux::use_old;

// IF TODO: use a module to handle control hazard?
always_comb begin
    pc_mux_sel = pcmux::pc_plus4;
    inst_mem_read = !load_buffers;
    inst_mem_write = 0;
    inst_mem_byte_enable = 0;

    case (id_ex.inst.opcode)
        op_jal: pc_mux_sel = pcmux::alu_out;
        op_jalr: pcmux::alu_mod2;
        op_br: if (br_en) pc_mux_sel = pcmux::alu_out;
        default: ;
    endcase
end

// EX
assign ex_ctrl = id_ex.ctrl;

// MEM
assign mem_ctrl = ex_mem.ctrl;
assign data_mem_read = ex_mem.ctrl.data_mem_read;
assign data_mem_write = ex_mem.ctrl.data_mem_write;
assign data_mem_byte_enable = ex_mem.ctrl.data_mem_byte_enable;

// WB
assign wb_ctrl = mem_wb.ctrl;


endmodule : cpu_control
