/* A register array to be used for tag arrays, LRU array, etc. */

module btb_array #(
    parameter s_index = 3
)
(
    clk,
    load,
    bpindex,
    rindex,
    windex,
    datain,
    bpdataout,
    dataout
);

localparam num_sets = 2**s_index;

input clk;
input load;
input [s_index-1:0] bpindex;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [31:0] datain;
output logic [31:0] bpdataout;
output logic [31:0] dataout;

logic [31:0] data [num_sets-1:0] = '{default: '0};

always_comb begin
    bpdataout = (load  & (bpindex == windex)) ? datain : data[bpindex];
    dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end

always_ff @(posedge clk) begin
    if(load)
        data[windex] <= datain;
end

endmodule : btb_array
