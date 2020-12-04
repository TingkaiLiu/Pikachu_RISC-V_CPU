/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */
import rv32i_types::*;

module Dcache_datapath #(
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
    input addrmux::addrmux_sel_t addrmux_sel,
    input wemux::wemux_sel_t wemux_sel [3:0],
    input logic [3:0] valid_load,
    input logic [3:0] dirty_load,
    input logic [3:0] tag_load,
    input logic [3:0] valid_i,
    input logic [3:0] dirty_i,
    // to controller
    output logic [2:0] lru_o,
    output logic [3:0] valid_o,
    output logic [3:0] dirty_o,
    output logic [3:0] hit_o,
    // CPU
    input rv32i_word address_i,
    input logic mem_read,
    input logic mem_write,
    // bus adaptor
    input rv32i_word mem_byte_enable256,
    input llc_cacheline mem_wdata256,
    output llc_cacheline mem_rdata256,
    // cacheline adaptor
    input llc_cacheline pmem_rdata,
    output llc_cacheline pmem_wdata,
    output rv32i_word pmem_address
);

// from address_i
logic [s_index-1:0] set;
logic [s_tag-1:0] tag;
rv32i_word mem_address;
assign set = address_i[s_offset+s_index-1:s_offset];
assign tag = address_i[31:s_offset+s_index];
assign mem_address = {address_i[31:s_offset], 5'b0};

// mux
logic [s_line-1:0] dimux_out;
logic [s_line-1:0] domux_out;
rv32i_word addrmux_in [3:0];
rv32i_word addrmux_out;
logic [s_mask-1:0] wemux_out [3:0];

// array
logic [s_tag-1:0] tag_out [3:0];
logic [s_line-1:0] data_out [3:0];

// output
assign mem_rdata256 = domux_out;
assign pmem_wdata = domux_out;
assign pmem_address = addrmux_out;

always_comb
begin
    for (int i = 0; i < 4; i++) begin
        addrmux_in[i] = {tag_out[i], set, 5'b0};
        hit_o[i] = (tag == tag_out[i]) && valid_o[i];
    end
end

// lru
logic [s_index-1:0] windex;
logic [2:0] lru_i;
logic lru_load;
always_ff @(posedge clk) begin
    if (mem_read || mem_write) begin
        case (hit_o)
            4'b0001: begin windex <= set; lru_i[1] <= 1'b0; lru_i[0] <= 1'b0; lru_i[2] <= lru_o[2]; lru_load <= 1'b1; end
            4'b0010: begin windex <= set; lru_i[1] <= 1'b1; lru_i[0] <= 1'b0; lru_i[2] <= lru_o[2]; lru_load <= 1'b1; end
            4'b0100: begin windex <= set; lru_i[2] <= 1'b0; lru_i[0] <= 1'b1; lru_i[1] <= lru_o[1]; lru_load <= 1'b1; end
            4'b1000: begin windex <= set; lru_i[2] <= 1'b1; lru_i[0] <= 1'b1; lru_i[1] <= lru_o[1]; lru_load <= 1'b1; end
            default: begin lru_i <= lru_o; lru_load <= 1'b0; end
        endcase
    end
end

Darray #(s_index, 3) LRUA(.clk, .load(lru_load), .rindex(set), .windex(windex), .datain(lru_i), .dataout(lru_o));

Ddata_array DataA0(.clk, .write_en(wemux_out[0]), .rindex(set), .windex(set), .datain(dimux_out), .dataout(data_out[0]));
Ddata_array DataA1(.clk, .write_en(wemux_out[1]), .rindex(set), .windex(set), .datain(dimux_out), .dataout(data_out[1]));
Ddata_array DataA2(.clk, .write_en(wemux_out[2]), .rindex(set), .windex(set), .datain(dimux_out), .dataout(data_out[2]));
Ddata_array DataA3(.clk, .write_en(wemux_out[3]), .rindex(set), .windex(set), .datain(dimux_out), .dataout(data_out[3]));

Darray ValidA0(.clk, .load(valid_load[0]), .rindex(set), .windex(set), .datain(valid_i[0]), .dataout(valid_o[0]));
Darray ValidA1(.clk, .load(valid_load[1]), .rindex(set), .windex(set), .datain(valid_i[1]), .dataout(valid_o[1]));
Darray ValidA2(.clk, .load(valid_load[2]), .rindex(set), .windex(set), .datain(valid_i[2]), .dataout(valid_o[2]));
Darray ValidA3(.clk, .load(valid_load[3]), .rindex(set), .windex(set), .datain(valid_i[3]), .dataout(valid_o[3]));

Darray DirtyA0(.clk, .load(dirty_load[0]), .rindex(set), .windex(set), .datain(dirty_i[0]), .dataout(dirty_o[0]));
Darray DirtyA1(.clk, .load(dirty_load[1]), .rindex(set), .windex(set), .datain(dirty_i[1]), .dataout(dirty_o[1]));
Darray DirtyA2(.clk, .load(dirty_load[2]), .rindex(set), .windex(set), .datain(dirty_i[2]), .dataout(dirty_o[2]));
Darray DirtyA3(.clk, .load(dirty_load[3]), .rindex(set), .windex(set), .datain(dirty_i[3]), .dataout(dirty_o[3]));

Darray #(s_index, s_tag) TagA0 (.clk, .load(tag_load[0]), .rindex(set), .windex(set), .datain(tag), .dataout(tag_out[0]));
Darray #(s_index, s_tag) TagA1 (.clk, .load(tag_load[1]), .rindex(set), .windex(set), .datain(tag), .dataout(tag_out[1]));
Darray #(s_index, s_tag) TagA2 (.clk, .load(tag_load[2]), .rindex(set), .windex(set), .datain(tag), .dataout(tag_out[2]));
Darray #(s_index, s_tag) TagA3 (.clk, .load(tag_load[3]), .rindex(set), .windex(set), .datain(tag), .dataout(tag_out[3]));

always_comb begin : MUXES
    wemux_out[0] = {s_mask{1'b0}};
    wemux_out[1] = {s_mask{1'b0}};
    wemux_out[2] = {s_mask{1'b0}};
    wemux_out[3] = {s_mask{1'b0}};
    dimux_out = mem_wdata256;
    domux_out = {s_line{1'b0}};
    addrmux_out = mem_address;

    for (int i = 0; i < 4; i++) begin
        unique case (wemux_sel[i])
            wemux::zeros: wemux_out[i] = {s_mask{1'b0}};
            wemux::ones:  wemux_out[i] = {s_mask{1'b1}};
            wemux::mbe:   wemux_out[i] = mem_byte_enable256;
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

    unique case(addrmux_sel)
        addrmux::cache_0: addrmux_out = addrmux_in[0];
        addrmux::cache_1: addrmux_out = addrmux_in[1];
        addrmux::cache_2: addrmux_out = addrmux_in[2];
        addrmux::cache_3: addrmux_out = addrmux_in[3];
        default: ;
    endcase

end

endmodule : Dcache_datapath
