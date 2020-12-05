/* A register array to be used for tag arrays, LRU array, etc. */

module Darray #(
    parameter s_index = 3,
    parameter width = 1
)
(
    clk,
    load,
    rindex,
    windex,
    datain,
    dataout
);

localparam num_sets = 2**s_index;

input clk;
input load;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] = '{default: '0};

// always_comb begin
//     // dataout = (load  & (rindex == windex)) ? datain : data[rindex];
//     dataout = data[rindex];
// end

always_ff @(posedge clk) begin
    dataout <= (load) ? datain : data[rindex];
    
    if(load)
        data[windex] <= datain;
end

endmodule : Darray
