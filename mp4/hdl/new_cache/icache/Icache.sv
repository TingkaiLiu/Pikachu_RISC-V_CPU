/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */
import rv32i_types::*;

module Icache #(
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
logic load_prefetch_line;
logic pref_hit;
dimux::dimux_sel_t dimux_sel;
domux::domux_sel_t domux_sel;
pwdatamux::pwdatamux_sel_t pwdatamux_sel;
addrmux::addrmux_sel_t addrmux_sel;
paddrmux::paddrmux_sel_t paddrmux_sel;
wemux::wemux_sel_t wemux_sel [3:0];
nwemux::nwemux_sel_t nwemux_sel [3:0];

logic lru_load;
logic [3:0] valid_load;
logic [3:0] dirty_load;
logic [3:0] tag_load;

logic nlru_load;
logic [3:0] nvalid_load;
logic [3:0] ndirty_load;
logic [3:0] ntag_load;

logic [2:0] lru_d2c;
logic [2:0] lru_c2d;
logic [3:0] valid_d2c;
logic [3:0] valid_c2d;
logic [3:0] dirty_d2c;
logic [3:0] dirty_c2d;
logic [3:0] hit_d2c;

logic [2:0] nlru_d2c;
logic [2:0] nlru_c2d;
logic [3:0] nvalid_d2c;
logic [3:0] nvalid_c2d;
logic [3:0] ndirty_d2c;
logic [3:0] ndirty_c2d;
logic [3:0] nhit_d2c;

Icache_control control
(
    .*,
    // from datapath
    .lru_i          (lru_d2c),
    .valid_i        (valid_d2c),
    .dirty_i        (dirty_d2c),
    .hit_i          (hit_d2c),

    .nlru_i         (nlru_d2c),
    .nvalid_i       (nvalid_d2c),
    .ndirty_i       (ndirty_d2c),
    .nhit_i         (nhit_d2c),
    // to datapath
    .lru_o          (lru_c2d),
    .valid_o        (valid_c2d),
    .dirty_o        (dirty_c2d),

    .nlru_o         (nlru_c2d),
    .nvalid_o       (nvalid_c2d),
    .ndirty_o       (ndirty_c2d),
    // CPU
    .mem_read,
    .mem_write,
    .mem_resp,
    // cacheline adaptor
    .pmem_resp,
    .pmem_read,
    .pmem_write
);

Icache_datapath datapath
(
    .*,
    // from controller
    .lru_i          (lru_c2d),
    .valid_i        (valid_c2d),
    .dirty_i        (dirty_c2d),

    .nlru_i         (nlru_c2d),
    .nvalid_i       (nvalid_c2d),
    .ndirty_i       (ndirty_c2d),
    // to controller
    .lru_o          (lru_d2c),
    .valid_o        (valid_d2c),
    .dirty_o        (dirty_d2c),
    .hit_o          (hit_d2c),

    .nlru_o         (nlru_d2c),
    .nvalid_o       (nvalid_d2c),
    .ndirty_o       (ndirty_d2c),
    .nhit_o         (nhit_d2c),
    // bus adaptor
    .mem_address,
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
    // CPU
    .address(mem_address),
    .mem_wdata,
    .mem_rdata,
    .mem_byte_enable,
    // Cache
    .mem_wdata256,
    .mem_rdata256,
    .mem_byte_enable256
);

endmodule : Icache
