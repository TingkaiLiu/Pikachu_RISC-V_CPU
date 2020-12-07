/* A register array to be used for tag arrays, LRU array, etc. */

module pht_array #(
    parameter s_index = 5
)
(
    clk,
    rst,
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
input rst;
input load;
input [s_index-1:0] bpindex;
input [s_index-1:0] rindex;
input [s_index-1:0] windex;
input  [1:0] datain;
output logic [1:0] bpdataout;
output logic [1:0] dataout;

logic [1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;

always_comb begin
    bpdataout = (load  & (bpindex == windex)) ? datain : data[bpindex];
    dataout = (load  & (rindex == windex)) ? datain : data[rindex];
end
// assign dataout = data[rindex];

always_ff @(posedge clk)
begin
    if (rst) begin
        // for (int i = 0; i < num_sets; ++i)
        //     data[i] <= 2'b01;
        data <= '{num_sets{2'b00}};
    end
    else begin
        if(load)
            data[windex] <= datain;
    end
end

endmodule : pht_array
