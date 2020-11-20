import rv32i_types::*;
import rv32i_packet::*;

module buffer
(
    input logic clk,
    input logic rst,
    input logic load,
    input buffer_load_mux::buffer_sel_t buffer_sel,
    input rv32i_packet_t packet_in_old, // from previous buffer
    input rv32i_packet_t packet_in_new, // from previous stage
    output rv32i_packet_t packet_out
);

rv32i_packet_t packet, packet_in;

assign packet_out = packet;

always_ff @(posedge clk) begin
    if (rst) packet <= '0;
    else if (load) packet <= packet_in;
end

// Merge new changes into old packet if needed
always_comb begin
    packet_in = packet_in_old;

    case (buffer_sel)
        buffer_load_mux::use_old: ;
        buffer_load_mux::load_ifid: begin
            packet_in.valid = packet_in_new.valid;
            packet_in.data.pc = packet_in_new.data.pc;
            packet_in.data.instruction = packet_in_new.data.instruction;
            packet_in.data.next_pc = packet_in_new.data.next_pc;
        end
        buffer_load_mux::load_idex: begin
            packet_in.valid = packet_in_new.valid;
            packet_in.inst = packet_in_new.inst;
            packet_in.ctrl = packet_in_new.ctrl;
            packet_in.data.rs1_out = packet_in_new.data.rs1_out;
            packet_in.data.rs2_out = packet_in_new.data.rs2_out;
        end
        buffer_load_mux::load_exmem: begin
            packet_in.data.alu_out = packet_in_new.data.alu_out;
            packet_in.data.br_en = packet_in_new.data.br_en;
            packet_in.data.correct_pc_prediction = packet_in_new.data.correct_pc_prediction;
            packet_in.data.next_pc = packet_in_new.data.next_pc;
        end
        buffer_load_mux::load_memwb: begin
            packet_in.data.mdrreg_out = packet_in_new.data.mdrreg_out;
            packet_in.data.rmask = packet_in_new.data.rmask;
            packet_in.data.wmask = packet_in_new.data.wmask;
            packet_in.data.mem_addr = packet_in_new.data.mem_addr;
            packet_in.data.mem_rdata = packet_in_new.data.mem_rdata;
            packet_in.data.mem_wdata = packet_in_new.data.mem_wdata;
        end
        default: $fatal("Bad buffer sel!\n"); 
    endcase
end

endmodule