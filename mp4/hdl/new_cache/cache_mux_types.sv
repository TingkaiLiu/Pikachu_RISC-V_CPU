package wemux;
typedef enum bit[1:0] { 
    zeros = 2'b00
    ,ones = 2'b01
    ,mbe = 2'b10
} wemux_sel_t;
endpackage

package nwemux;
typedef enum bit { 
    zeros = 1'b0
    ,ones = 1'b1
} nwemux_sel_t;
endpackage

package dimux;
typedef enum bit { 
    mem_wdata256_from_cpu = 1'b0
    ,pmem_rdata_from_mem = 1'b1
} dimux_sel_t;
endpackage

package domux;
typedef enum bit [2:0] {
    data_array_0 = 3'b000
    ,data_array_1 = 3'b001
    ,data_array_2 = 3'b010
    ,data_array_3 = 3'b011
} domux_sel_t;
endpackage

package pwdatamux;
typedef enum bit [2:0] {
    next_data_array_0 = 3'b000
    ,next_data_array_1 = 3'b001
    ,next_data_array_2 = 3'b010
    ,next_data_array_3 = 3'b011
    ,domux_out = 3'b100
} pwdatamux_sel_t;
endpackage

package addrmux;
typedef enum bit [2:0] {
    cache_0 = 3'b000
    ,cache_1 = 3'b001
    ,cache_2 = 3'b010
    ,cache_3 = 3'b011
    ,from_cpu = 3'b100
} addrmux_sel_t;
endpackage

package paddrmux;
typedef enum bit [2:0] {
    next_cache_0 = 3'b000
    ,next_cache_1 = 3'b001
    ,next_cache_2 = 3'b010
    ,next_cache_3 = 3'b011
    ,addrmux_out = 3'b100
    ,prefetch_line = 3'b101
} paddrmux_sel_t;
endpackage