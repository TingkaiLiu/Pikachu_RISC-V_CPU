import rv32i_types::*;
import rv32i_packet::*;

module ID
(
    input clk,
    input rst,
    input rv32i_ctrl_packet_t ctrl,
    input rv32i_packet_t packet_in,
    output rv32i_packet_t packet_out,
    // Regfile
    output [4:0] rs1,
    output [4:0] rs2,
    input rv32i_word reg_a,
    input rv32i_word reg_b
);

assign packet_out.data.rs1_out = reg_a;
assign packet_out.data.rs2_out = reg_b;
assign rs1 = packet_out.inst.rs1;
assign rs2 = packet_out.inst.rs2;

ir IR(.*, 
      .load(ctrl.load_ir),
      .in(packet_in.data.instruction),
      .out(packet_out.inst)
);

endmodule