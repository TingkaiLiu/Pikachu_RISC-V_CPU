/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
import rv32i_types::*;

module cache_datapath #(
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
    input dimux::dimux_sel_t dimux_sel,
    input domux::domux_sel_t domux_sel,
    input wemux::wemux_sel_t wemux_sel[1:0],
    input addrmux::addrmux_sel_t addrmux_sel,
    input logic lru_load,
    input logic [1:0] valid_load,
    input logic [1:0] dirty_load,
    input logic [1:0] tag_load,
    input logic lru_i,
    input logic [1:0] valid_i,
    input logic [1:0] dirty_i,
    // to controller
    output logic lru_o,
    output logic [1:0] valid_o,
    output logic [1:0] dirty_o,
    output logic [1:0] cmp_o,
    // CPU
    input rv32i_word address_i,
    // bus adaptor
    input rv32i_word mem_byte_enable256,
    input llc_cacheline mem_wdata256,
    output llc_cacheline mem_rdata256,
    // cacheline adaptor
    input llc_cacheline pmem_rdata,
    output llc_cacheline pmem_wdata,
    output rv32i_word pmem_address
);

logic [s_offset-1:0] offset;
logic [s_index-1:0] set;
logic [s_tag-1:0] tag;
logic [s_tag-1:0] tag_out [1:0];

logic [s_mask-1:0] wemux_out [1:0];
logic [s_line-1:0] dimux_out;
logic [s_line-1:0] domux_out, domux_out_buf;
logic [s_line-1:0] data_out[1:0], _data_out[1:0]; //_ for buf

assign mem_rdata256 = domux_out;
assign pmem_wdata = domux_out_buf;

assign offset = address_i[s_offset-1:0];
assign set = address_i[s_offset+s_index-1:s_offset];
assign tag = address_i[31:s_offset+s_index];

rv32i_word in_address, cache_address0, cache_address1;
assign in_address = {address_i[31:s_offset], 5'b0};

// For cutting crtical path: buffer the address and data to mem
always_ff @ (posedge clk) begin
    cache_address0 <= {tag_out[0], set, 5'b0};
    cache_address1 <= {tag_out[1], set, 5'b0};
    _data_out <= data_out;
end


always_comb
begin
    cmp_o[0] = (tag == tag_out[0]) ? 1'b1:1'b0;
    cmp_o[1] = (tag == tag_out[1]) ? 1'b1:1'b0;
end

data_array DataA0(
    .clk,
    .rst,
    .write_en(wemux_out[0]),
    .rindex(set),
    .windex(set),
    .datain(dimux_out),
    .dataout(data_out[0])
);

data_array DataA1(
    .clk,
    .rst,
    .write_en(wemux_out[1]),
    .rindex(set),
    .windex(set),
    .datain(dimux_out),
    .dataout(data_out[1])
);

array LRUA(
    .clk,
    .rst,
    .load(lru_load),
    .rindex(set),
    .windex(set),
    .datain(lru_i),
    .dataout(lru_o)
);

array ValidA0(
    .clk,
    .rst,
    .load(valid_load[0]),
    .rindex(set),
    .windex(set),
    .datain(valid_i[0]),
    .dataout(valid_o[0])
);

array ValidA1(
    .clk,
    .rst,
    .load(valid_load[1]),
    .rindex(set),
    .windex(set),
    .datain(valid_i[1]),
    .dataout(valid_o[1])
);

array DirtyA0(
    .clk,
    .rst,
    .load(dirty_load[0]),
    .rindex(set),
    .windex(set),
    .datain(dirty_i[0]),
    .dataout(dirty_o[0])
);

array DirtyA1(
    .clk,
    .rst,
    .load(dirty_load[1]),
    .rindex(set),
    .windex(set),
    .datain(dirty_i[1]),
    .dataout(dirty_o[1])
);

array #(s_index, s_tag) TagA0
(
    .clk,
    .rst,
    .load(tag_load[0]),
    .rindex(set),
    .windex(set),
    .datain(tag),
    .dataout(tag_out[0])
);

array #(s_index, s_tag) TagA1
(
    .clk,
    .rst,
    .load(tag_load[1]),
    .rindex(set),
    .windex(set),
    .datain(tag),
    .dataout(tag_out[1])
);

always_comb begin : MUXES
	 wemux_out[0] = {s_mask{1'b0}};
	 wemux_out[1] = {s_mask{1'b0}};
	 dimux_out = mem_wdata256;
     domux_out = data_out[0];
     domux_out_buf = _data_out[0];
     pmem_address = in_address;
    unique case (wemux_sel[0])
        wemux::zeros: wemux_out[0] = {s_mask{1'b0}};
        wemux::ones:  wemux_out[0] = {s_mask{1'b1}};
        wemux::mbe: wemux_out[0] = mem_byte_enable256;
        default: wemux_out[0] = {s_mask{1'b0}};
    endcase

    unique case (wemux_sel[1])
        wemux::zeros: wemux_out[1] = {s_mask{1'b0}};
        wemux::ones:  wemux_out[1] = {s_mask{1'b1}};
        wemux::mbe: wemux_out[1] = mem_byte_enable256;
        default: wemux_out[1] = {s_mask{1'b0}};
    endcase

    unique case(dimux_sel)
        dimux::mem_wdata256_from_cpu: dimux_out = mem_wdata256;
        dimux::pmem_rdata_from_mem: dimux_out = pmem_rdata;
        default: dimux_out = mem_wdata256;
    endcase

    unique case(domux_sel)
        domux::data_array_0: domux_out = data_out[0];
        domux::data_array_1: domux_out = data_out[1];
        default: domux_out = data_out[0];
    endcase

    unique case(domux_sel)
        domux::data_array_0: domux_out_buf = _data_out[0];
        domux::data_array_1: domux_out_buf = _data_out[1];
        default: domux_out_buf = _data_out[0];
    endcase

    unique case(addrmux_sel)
        addrmux::cache_0: pmem_address = cache_address0;
        addrmux::cache_1: pmem_address = cache_address1;
        default: pmem_address = in_address;
    endcase

end

endmodule : cache_datapath
