/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */
import rv32i_types::*;
import cache_types::*;

module cache #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input logic clk,
    input logic rst,
    // CPU
    input rv32i_word mem_address,
    input [3:0] mem_byte_enable,
    input rv32i_word mem_wdata,
    output rv32i_word mem_rdata,
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,
    // cacheline adaptor
    output logic pmem_read,
    output logic pmem_write,
    input llc_cacheline pmem_rdata,
    output llc_cacheline pmem_wdata,
    input logic pmem_resp,
    output rv32i_word pmem_address
);

// bus adaptor
rv32i_word mem_byte_enable256;
llc_cacheline mem_wdata256;
llc_cacheline mem_rdata256;
// signals between controller and datapath
logic [1:0] cmp_d2c;
logic [1:0] data_read;
dimux::dimux_sel_t dimux_sel;
domux::domux_sel_t domux_sel;
wemux::wemux_sel_t wemux_sel [1:0];
addrmux::addrmux_sel_t addrmux_sel;
logic lru_read;
logic lru_load;
logic lru_d2c;
logic lru_c2d;
logic [1:0] valid_read;
logic [1:0] valid_load;
logic [1:0] valid_d2c;
logic [1:0] valid_c2d;
logic [1:0] dirty_read;
logic [1:0] dirty_load;
logic [1:0] dirty_d2c;
logic [1:0] dirty_c2d;
logic [1:0] tag_read;
logic [1:0] tag_load;

cache_control control
(
    .clk,
    .rst,
    // from datapath
    .lru_i(lru_d2c),
    .valid_i(valid_d2c),
    .dirty_i(dirty_d2c),
    .cmp_i(cmp_d2c),
    // to datapath
    .data_read,
    .dimux_sel,
    .domux_sel,
    .wemux_sel,
    .addrmux_sel,
    .lru_read,
    .lru_load,
    .valid_read,
    .valid_load,
    .dirty_read,
    .dirty_load,
    .tag_read,
    .tag_load,
    .lru_o(lru_c2d),
    .valid_o(valid_c2d),
    .dirty_o(dirty_c2d),
    // CPU
    .mem_read,
    .mem_write,
    .mem_resp,
    // cacheline adaptor
    .pmem_resp,
    .pmem_read,
    .pmem_write
);

cache_datapath datapath
(
    .clk,
    .rst,
    // from controller
    .data_read,
    .dimux_sel,
    .domux_sel,
    .wemux_sel,
    .addrmux_sel,
    .lru_read,
    .lru_load,
    .valid_read,
    .valid_load,
    .dirty_read,
    .dirty_load,
    .tag_read,
    .tag_load,
    .lru_i(lru_c2d),
    .valid_i(valid_c2d),
    .dirty_i(dirty_c2d),
    // to controller
    .lru_o(lru_d2c),
    .valid_o(valid_d2c),
    .dirty_o(dirty_d2c),
    .cmp_o(cmp_d2c),
    // CPU
    .address_i(mem_address),
    // bus adaptor
    .mem_byte_enable256,
    .mem_wdata256,
    .mem_rdata256,
    // cacheline adaptor
    .pmem_rdata,
    .pmem_wdata,
    .pmem_address
);

bus_adapter bus_adapter
(
    .mem_wdata256,
    .mem_rdata256,
    .mem_wdata,
    .mem_rdata,
    .mem_byte_enable,
    .mem_byte_enable256,
    .address(mem_address)
);

endmodule : cache
