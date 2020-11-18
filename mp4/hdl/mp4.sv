import rv32i_types::*;

module mp4(
    input logic clk, rst,

    // Memory
    output logic mem_read,
    output logic mem_write,
    output logic [63:0] mem_wdata,
    input logic [63:0] mem_rdata,
    output logic [31:0] mem_address,
    input logic mem_resp
);

// CPU - I-Cache
rv32i_word inst_mem_address;
logic inst_mem_read;
logic inst_mem_write;
logic [3:0] inst_mem_byte_enable;
rv32i_word inst_mem_rdata;
rv32i_word inst_mem_wdata;
logic inst_mem_resp;
// CPU - D-Cache
rv32i_word data_mem_address;
logic data_mem_read;
logic data_mem_write;
logic [3:0] data_mem_byte_enable;
rv32i_word data_mem_rdata;
rv32i_word data_mem_wdata;
logic data_mem_resp;

cpu cpu(.*);
cache_top cache_top(.*);

endmodule : mp4
