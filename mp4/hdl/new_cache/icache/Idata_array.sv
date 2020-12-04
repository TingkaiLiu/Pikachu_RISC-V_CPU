/* A special register array specifically for your
data arrays. This module supports a write mask to
help you update the values in the array. */

module Idata_array #(
    parameter s_offset = 5,
    parameter s_index = 3
)
(
    clk,
    next_write_en,
    next_set,
    pref_set,
    next_datain,
    next_dataout,
    write_en,
    set,
    datain,
    dataout
);

localparam s_mask   = 2**s_offset;
localparam s_line   = 8*s_mask;
localparam num_sets = 2**s_index;

input clk;
input [s_mask-1:0] next_write_en;
input [s_index-1:0] next_set;
input [s_index-1:0] pref_set;
input [s_line-1:0] next_datain;
output logic [s_line-1:0] next_dataout;
input [s_mask-1:0] write_en;
input [s_index-1:0] set;
input [s_line-1:0] datain;
output logic [s_line-1:0] dataout;

logic [s_line-1:0] data [num_sets-1:0] = '{default: '0};

always_comb begin
    for (int i = 0; i < s_mask; i++) begin
        dataout[8*i +: 8] = (write_en[i]) ? datain[8*i +: 8] : data[set][8*i +: 8];
        next_dataout[8*i +: 8] = (next_write_en[i] && (next_set == pref_set)) ? next_datain[8*i +: 8] : data[next_set][8*i +: 8];
    end
end

always_ff @(posedge clk) begin
    for (int i = 0; i < s_mask; i++) begin
        data[set][8*i +: 8] <= write_en[i] ? datain[8*i +: 8] : data[set][8*i +: 8];
        data[pref_set][8*i +: 8] <= next_write_en[i] ? next_datain[8*i +: 8] : data[pref_set][8*i +: 8];
    end
end

endmodule : Idata_array
