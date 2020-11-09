import rv32i_types::*;
import rv32i_packet::*;

module MEM
(
    input clk,
    input rst,
    // input rv32i_ctrl_packet_t ctrl,
    input rv32i_packet_t mem_in,
    output rv32i_packet_t mem_out,
    // Data Cache
    output rv32i_word data_mem_address,
    output rv32i_word data_mem_wdata,
    input rv32i_word data_mem_rdata
);

assign inst_mem_address = mem_in.data.alu_out;
assign data_mem_wdata = mem_in.data.rs2_out;
assign mem_out.data.mdrreg_out = data_mem_rdata;

endmodule