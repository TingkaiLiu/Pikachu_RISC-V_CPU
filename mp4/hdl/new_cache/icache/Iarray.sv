/* A register array to be used for tag arrays, LRU array, etc. */

module Iarray #(
    parameter s_index = 3,
    parameter width = 1
)
(
    clk,
    next_load,
    next_set,
    pref_set,
    next_datain,
    next_dataout,
    load,
    set,
    windex,
    datain,
    dataout
);

localparam num_sets = 2**s_index;

input clk;
input next_load;
input [s_index-1:0] next_set;
input [s_index-1:0] pref_set;
input [width-1:0] next_datain;
output logic [width-1:0] next_dataout;
input load;
input [s_index-1:0] set;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] = '{default: '0};

always_comb begin
    dataout = (load && (set == windex)) ? datain : data[set];
    next_dataout = (next_load && (next_set == pref_set)) ? next_datain : data[next_set];
end

always_ff @(posedge clk) begin
    if(load)
        data[windex] <= datain;
    if(next_load)
        data[pref_set] <= next_datain;
end

endmodule : Iarray
