import rv32i_types::*;
import rv32i_packet::*;

module mp4(
    input logic clk, rst,

    // Memory
    output rv32i_word inst_mem_address,
    output logic inst_mem_read,
    output logic inst_mem_write,
    output logic [3:0] inst_mem_byte_enable,
    input rv32i_word inst_mem_rdata,
    output rv32i_word inst_mem_wdata,
    input logic inst_mem_resp,

    output rv32i_word data_mem_address,
    output logic data_mem_read,
    output logic data_mem_write,
    output logic [3:0] data_mem_byte_enable,
    input rv32i_word data_mem_rdata,
    output rv32i_word data_mem_wdata,
    input logic data_mem_resp
);

cpu cpu0(.*);

endmodule : mp4
