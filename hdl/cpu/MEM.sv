import rv32i_types::*;
import rv32i_packet::*;

module MEM
(
    input clk,
    input rst,
    // input rv32i_ctrl_packet_t ctrl,
    output rv32i_packet_t packet_out,
    // From other stages
    input rv32i_word alu_out;
    input rv32i_word rs2_out;
    // Data Cache
    output rv32i_word data_mem_address,
    output rv32i_word data_mem_wdata,
    input rv32i_word data_mem_rdata
);

assign inst_mem_address = alu_out;
assign data_mem_wdata = rs2_out;
assign packet_out.data.mdrreg_out = data_mem_rdata;

endmodule