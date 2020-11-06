import rv32i_types::*;
import rv32i_packet::*;

module ID
(
    input clk,
    input rst,
    input rv32i_ctrl_packet_t ctrl,
    output rv32i_packet_t packet_out,
    // From other stages
    input rv32i_word instruction,
    // Regfile
    output [4:0] rs1,
    output [4:0] rs2,
    input rv32i_word reg_a,
    input rv32i_word reg_b
);

assign packet_out.data.rs1_out = reg_a;
assign packed_out.data.rs2_out = reg_b;
assign rs1 = packet_out.ctrl.rs1;
assign rs2 = packet_out.ctrl.rs2;

ir IR(.*, 
      .load(ctrl.load_ir),
      .in(instruction),
      .out(packet_out.ctrl)
);

endmodule