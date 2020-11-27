/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
import rv32i_types::*;

module Icache_datapath #(
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
    // from controller
    input logic load_prefetch_line,
    output logic pref_hit,
    input dimux::dimux_sel_t dimux_sel,
    input domux::domux_sel_t domux_sel,
    input pwdatamux::pwdatamux_sel_t pwdatamux_sel,
    input addrmux::addrmux_sel_t addrmux_sel,
    input paddrmux::paddrmux_sel_t paddrmux_sel,
    input wemux::wemux_sel_t wemux_sel [3:0],
    input nwemux::nwemux_sel_t nwemux_sel [3:0],

    input logic lru_load,
    input logic [3:0] valid_load,
    input logic [3:0] dirty_load,
    input logic [3:0] tag_load,

    input logic nlru_load,
    input logic [3:0] nvalid_load,
    input logic [3:0] ndirty_load,
    input logic [3:0] ntag_load,

    input logic [2:0] lru_i,
    input logic [3:0] valid_i,
    input logic [3:0] dirty_i,

    input logic [2:0] nlru_i,
    input logic [3:0] nvalid_i,
    input logic [3:0] ndirty_i,
    // to controller
    output logic [2:0] lru_o,
    output logic [3:0] valid_o,
    output logic [3:0] dirty_o,
    output logic [3:0] hit_o,

    output logic [2:0] nlru_o,
    output logic [3:0] nvalid_o,
    output logic [3:0] ndirty_o,
    output logic [3:0] nhit_o,
    // bus adaptor
    input rv32i_word mem_address,
    input rv32i_word mem_byte_enable256,
    input llc_cacheline mem_wdata256,
    output llc_cacheline mem_rdata256,
    // cacheline adaptor
    input llc_cacheline pmem_rdata,
    output llc_cacheline pmem_wdata,
    output rv32i_word pmem_address
);

// from mem_address
logic [s_index-1:0] set;
logic [s_tag-1:0] tag;
assign set = mem_address[s_offset+s_index-1:s_offset];
assign tag = mem_address[31:s_offset+s_index];

// next line
rv32i_word next_line_address;
assign next_line_address = mem_address + 6'b100000;
logic [s_index-1:0] next_set;
logic [s_tag-1:0] next_tag;
assign next_set = next_line_address[s_offset+s_index-1:s_offset];
assign next_tag = next_line_address[31:s_offset+s_index];

// mux
logic [s_line-1:0] dimux_out;
logic [s_line-1:0] domux_out;
logic [s_line-1:0] pwdatamux_out;
rv32i_word addrmux_in [3:0];
rv32i_word paddrmux_in [3:0];
rv32i_word addrmux_out;
rv32i_word paddrmux_out;
logic [s_mask-1:0] wemux_out [3:0];
logic [s_mask-1:0] nwemux_out [3:0];

// load_prefetch_line
rv32i_word prefetch_line_address;
rv32i_word prefetch_wb_line_address [3:0];
logic [s_index-1:0] pref_set;
logic [s_tag-1:0] pref_tag;
always_ff @(posedge clk) begin
    if (load_prefetch_line)
    begin
        prefetch_line_address <= next_line_address;
        prefetch_wb_line_address[0] <= paddrmux_in[0];
        prefetch_wb_line_address[1] <= paddrmux_in[1];
        prefetch_wb_line_address[2] <= paddrmux_in[2];
        prefetch_wb_line_address[3] <= paddrmux_in[3];
        pref_set <= next_set;
        pref_tag <= next_tag;
    end
end  

// array
logic [s_tag-1:0] tag_out [3:0];
logic [s_tag-1:0] ntag_out [3:0];
logic [s_line-1:0] data_out [3:0];
logic [s_line-1:0] ndata_out [3:0];

// output
assign mem_rdata256 = domux_out;
assign pmem_wdata = pwdatamux_out;
assign pmem_address = paddrmux_out;

always_comb
begin
    for (int i = 0; i < 4; i++) begin
        addrmux_in[i] = {tag_out[i], set, 5'b0};
        paddrmux_in[i] = {ntag_out[i], next_set, 5'b0};
        hit_o[i] = (tag == tag_out[i]) && valid_o[i];
        nhit_o[i] = (next_tag == ntag_out[i]) && nvalid_o[i];
    end
end
assign pref_hit = (tag == pref_tag) && (set == pref_set);

Iarray #(s_index, 3) LRUA(.*, .next_load(nlru_load), .next_datain(nlru_i), .next_dataout(nlru_o), .load(lru_load), .datain(lru_i), .dataout(lru_o));

Idata_array DataA0(.*, .next_write_en(nwemux_out[0]), .next_datain(pmem_rdata), .next_dataout(ndata_out[0]), .write_en(wemux_out[0]), .datain(dimux_out), .dataout(data_out[0]));
Idata_array DataA1(.*, .next_write_en(nwemux_out[1]), .next_datain(pmem_rdata), .next_dataout(ndata_out[1]), .write_en(wemux_out[1]), .datain(dimux_out), .dataout(data_out[1]));
Idata_array DataA2(.*, .next_write_en(nwemux_out[2]), .next_datain(pmem_rdata), .next_dataout(ndata_out[2]), .write_en(wemux_out[2]), .datain(dimux_out), .dataout(data_out[2]));
Idata_array DataA3(.*, .next_write_en(nwemux_out[3]), .next_datain(pmem_rdata), .next_dataout(ndata_out[3]), .write_en(wemux_out[3]), .datain(dimux_out), .dataout(data_out[3]));

Iarray ValidA0(.*, .next_load(nvalid_load[0]), .next_datain(nvalid_i[0]), .next_dataout(nvalid_o[0]), .load(valid_load[0]), .datain(valid_i[0]), .dataout(valid_o[0]));
Iarray ValidA1(.*, .next_load(nvalid_load[1]), .next_datain(nvalid_i[1]), .next_dataout(nvalid_o[1]), .load(valid_load[1]), .datain(valid_i[1]), .dataout(valid_o[1]));
Iarray ValidA2(.*, .next_load(nvalid_load[2]), .next_datain(nvalid_i[2]), .next_dataout(nvalid_o[2]), .load(valid_load[2]), .datain(valid_i[2]), .dataout(valid_o[2]));
Iarray ValidA3(.*, .next_load(nvalid_load[3]), .next_datain(nvalid_i[3]), .next_dataout(nvalid_o[3]), .load(valid_load[3]), .datain(valid_i[3]), .dataout(valid_o[3]));

Iarray DirtyA0(.*, .next_load(ndirty_load[0]), .next_datain(ndirty_i[0]), .next_dataout(ndirty_o[0]), .load(dirty_load[0]), .datain(dirty_i[0]), .dataout(dirty_o[0]));
Iarray DirtyA1(.*, .next_load(ndirty_load[1]), .next_datain(ndirty_i[1]), .next_dataout(ndirty_o[1]), .load(dirty_load[1]), .datain(dirty_i[1]), .dataout(dirty_o[1]));
Iarray DirtyA2(.*, .next_load(ndirty_load[2]), .next_datain(ndirty_i[2]), .next_dataout(ndirty_o[2]), .load(dirty_load[2]), .datain(dirty_i[2]), .dataout(dirty_o[2]));
Iarray DirtyA3(.*, .next_load(ndirty_load[3]), .next_datain(ndirty_i[3]), .next_dataout(ndirty_o[3]), .load(dirty_load[3]), .datain(dirty_i[3]), .dataout(dirty_o[3]));

Iarray #(s_index, s_tag) TagA0 (.*, .next_load(ntag_load[0]), .next_datain(pref_tag), .next_dataout(ntag_out[0]), .load(tag_load[0]), .datain(tag), .dataout(tag_out[0]));
Iarray #(s_index, s_tag) TagA1 (.*, .next_load(ntag_load[1]), .next_datain(pref_tag), .next_dataout(ntag_out[1]), .load(tag_load[1]), .datain(tag), .dataout(tag_out[1]));
Iarray #(s_index, s_tag) TagA2 (.*, .next_load(ntag_load[2]), .next_datain(pref_tag), .next_dataout(ntag_out[2]), .load(tag_load[2]), .datain(tag), .dataout(tag_out[2]));
Iarray #(s_index, s_tag) TagA3 (.*, .next_load(ntag_load[3]), .next_datain(pref_tag), .next_dataout(ntag_out[3]), .load(tag_load[3]), .datain(tag), .dataout(tag_out[3]));

always_comb begin : MUXES
    for (int i = 0; i < 4; i++) begin
        wemux_out[i] = {s_mask{1'b0}};
        nwemux_out[i] = {s_mask{1'b0}};
    end
    
    dimux_out = mem_wdata256;
    domux_out = data_out[0];
    pwdatamux_out = domux_out;
    addrmux_out = {mem_address[31:s_offset], 5'b0};
    paddrmux_out = addrmux_out;
    
    for (int i = 0; i < 4; i++) begin
        unique case (wemux_sel[i])
            wemux::zeros: wemux_out[i] = {s_mask{1'b0}};
            wemux::ones:  wemux_out[i] = {s_mask{1'b1}};
            wemux::mbe:   wemux_out[i] = mem_byte_enable256;
            default: ;
        endcase
        unique case (nwemux_sel[i])
            nwemux::zeros: nwemux_out[i] = {s_mask{1'b0}};
            nwemux::ones:  nwemux_out[i] = {s_mask{1'b1}};
            default: ;
        endcase
    end

    unique case(dimux_sel)
        dimux::mem_wdata256_from_cpu: dimux_out = mem_wdata256;
        dimux::pmem_rdata_from_mem:   dimux_out = pmem_rdata;
        default: ;
    endcase

    unique case(domux_sel)
        domux::data_array_0: domux_out = data_out[0];
        domux::data_array_1: domux_out = data_out[1];
        domux::data_array_2: domux_out = data_out[2];
        domux::data_array_3: domux_out = data_out[3];
        default: ;
    endcase

    unique case(pwdatamux_sel)
        pwdatamux::next_data_array_0: pwdatamux_out = ndata_out[0];
        pwdatamux::next_data_array_1: pwdatamux_out = ndata_out[1];
        pwdatamux::next_data_array_2: pwdatamux_out = ndata_out[2];
        pwdatamux::next_data_array_3: pwdatamux_out = ndata_out[3];
        default: ;
    endcase

    unique case(addrmux_sel)
        addrmux::cache_0: addrmux_out = addrmux_in[0];
        addrmux::cache_1: addrmux_out = addrmux_in[1];
        addrmux::cache_2: addrmux_out = addrmux_in[2];
        addrmux::cache_3: addrmux_out = addrmux_in[3];
        default: ;
    endcase

    unique case(paddrmux_sel)
        paddrmux::next_cache_0: paddrmux_out = prefetch_wb_line_address[0];
        paddrmux::next_cache_1: paddrmux_out = prefetch_wb_line_address[1];
        paddrmux::next_cache_2: paddrmux_out = prefetch_wb_line_address[2];
        paddrmux::next_cache_3: paddrmux_out = prefetch_wb_line_address[3];
        paddrmux::prefetch_line:paddrmux_out = {prefetch_line_address[31:s_offset], 5'b0};
        default: ;
    endcase

end

endmodule : Icache_datapath
