import rv32i_types::*;
import rv32i_packet::*;

module IF
(
    input clk,
    input rst,
    input rv32i_ctrl_packet_t ctrl,
    // input rv32i_packet_t packet_in,
    output rv32i_packet_t packet_out,
    // From other stages
    input rv32i_word alu_out,
    // Instraction Cache
    output rv32i_word inst_mem_address,
    input rv32i_word inst_mem_rdata
);

rv32i_word pcmux_out;
rv32i_word pc_out;

assign inst_mem_address = pc_out;
assign packet_out.data.pc_out = pc_out;
assign packet_out.data.instruction = inst_mem_rdata;

pc_register PC
(
    .*,
    .load(ctrl.load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

always_comb begin : PCMUX
	pcmux_out = pc_out;
    unique case (ctrl.pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = {alu_out[31:1], 1'b0};
        default: pcmux_out = pc_out + 4;
    endcase
end

endmodule