package wemux;
typedef enum bit[1:0] { 
    zeros = 2'b00
    ,ones = 2'b01
    ,mem_byte_enable256_from_cpu = 2'b10
} wemux_sel_t;
endpackage

package dimux;
typedef enum bit { 
    mem_wdata256_from_cpu = 1'b0
    ,line_o_from_memory = 1'b1
} dimux_sel_t;
endpackage

package domux;
typedef enum bit {
    data_array_0 = 1'b0
    ,data_array_1 = 1'b1
} domux_sel_t;
endpackage

package addrmux;
typedef enum bit[1:0] {
    cache_0 = 2'b00
    ,cache_1 = 2'b01
    ,from_cpu = 2'b10
} addrmux_sel_t;
endpackage