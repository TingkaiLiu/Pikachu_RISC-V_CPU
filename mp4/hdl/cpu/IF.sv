import rv32i_types::*;
import rv32i_packet::*;

module IF
(
    input clk,
    input rst,

    // From control
    input logic load_pc,
    input pcmux::pcmux_sel_t pcmux_sel,

    // From other stages
    input rv32i_word alu_out,
    logic correct_pc_prediction,

    // I-cache
    output rv32i_word inst_mem_address,
    input rv32i_word inst_mem_rdata,
    output logic [3:0] inst_mem_byte_enable,
    // To next stage
    output rv32i_packet_t if_out
);

rv32i_word pcmux_out;
rv32i_word pc_out;

assign inst_mem_address = pc_out;
assign inst_mem_byte_enable = 0;

assign if_out.data.pc = pc_out;
assign if_out.data.instruction = inst_mem_rdata;

assign if_out.valid = correct_pc_prediction;
assign if_out.data.next_pc = pc_out + 4; // TODO: Change after added branch prediction


pc_register PC
(
    .*,
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

always_comb begin : PCMUX
	pcmux_out = pc_out;
    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
        default: pcmux_out = pc_out + 4;
    endcase
end : PCMUX

endmodule