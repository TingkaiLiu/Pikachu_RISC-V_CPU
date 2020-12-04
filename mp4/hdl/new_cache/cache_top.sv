import rv32i_types::*;

module cache_top(
    input clk,
    input rst,
    // CPU - I-Cache
    input rv32i_word inst_mem_address,
    input logic inst_mem_read,
    input logic inst_mem_write,
    input logic [3:0] inst_mem_byte_enable,
    output rv32i_word inst_mem_rdata,
    input rv32i_word inst_mem_wdata,
    output logic inst_mem_resp,
    // CPU - D-Cache
    input rv32i_word data_mem_address,
    input logic data_mem_read,
    input logic data_mem_write,
    input logic [3:0] data_mem_byte_enable,
    output rv32i_word data_mem_rdata,
    input rv32i_word data_mem_wdata,
    output logic data_mem_resp,
    // Adaptor - Memory
    output logic mem_read,
    output logic mem_write,
    output logic [63:0] mem_wdata,
    input logic [63:0] mem_rdata,
    output logic [31:0] mem_address,
    input logic mem_resp
);

// I-Cache - Arbiter
logic imem_read;
logic imem_write;
llc_cacheline imem_rdata;
llc_cacheline imem_wdata;
logic imem_resp;
rv32i_word imem_address;
// L1 D-Cache - L2 D-cache
logic dmem1_read;
logic dmem1_write;
llc_cacheline dmem1_rdata;
llc_cacheline dmem1_wdata;
logic dmem1_resp;
rv32i_word dmem1_address;
// L2 D-Cache - Arbiter
logic dmem_read;
logic dmem_write;
llc_cacheline dmem_rdata;
llc_cacheline dmem_wdata;
logic dmem_resp;
rv32i_word dmem_address;
// Arbiter - Adaptor
logic mmem_read;
logic mmem_write;
llc_cacheline mmem_rdata;
llc_cacheline mmem_wdata;
logic mmem_resp;
rv32i_word mmem_address;

Icache Icache(
    .*,
    // CPU
    .mem_address        (inst_mem_address),
    .mem_byte_enable    (inst_mem_byte_enable),
    .mem_wdata          (inst_mem_wdata),
    .mem_rdata          (inst_mem_rdata),
    .mem_read           (inst_mem_read),
    .mem_write          (inst_mem_write),
    .mem_resp           (inst_mem_resp),
    // Arbiter
    .pmem_read          (imem_read),
    .pmem_write         (imem_write),
    .pmem_rdata         (imem_rdata),
    .pmem_wdata         (imem_wdata),
    .pmem_resp          (imem_resp),
    .pmem_address       (imem_address)
);
cache Dcache1(
    .*,
    // CPU
    .mem_address        (data_mem_address),
    .mem_byte_enable    (data_mem_byte_enable),
    .mem_wdata          (data_mem_wdata),
    .mem_rdata          (data_mem_rdata),
    .mem_read           (data_mem_read),
    .mem_write          (data_mem_write),
    .mem_resp           (data_mem_resp),
    // L2 D-Cache
    .pmem_read          (dmem1_read),
    .pmem_write         (dmem1_write),
    .pmem_rdata         (dmem1_rdata),
    .pmem_wdata         (dmem1_wdata),
    .pmem_resp          (dmem1_resp),
    .pmem_address       (dmem1_address)
);
cache2 Dcache2(
    .*,
    // L-1 D-Cache
    .mem_address        (dmem1_address),
    // .mem_byte_enable    (data_mem_byte_enable),
    .mem_wdata          (dmem1_wdata),
    .mem_rdata          (dmem1_rdata),
    .mem_read           (dmem1_read),
    .mem_write          (dmem1_write),
    .mem_resp           (dmem1_resp),
    // Arbiter
    .pmem_read          (dmem_read),
    .pmem_write         (dmem_write),
    .pmem_rdata         (dmem_rdata),
    .pmem_wdata         (dmem_wdata),
    .pmem_resp          (dmem_resp),
    .pmem_address       (dmem_address)
);

// cache Icache(
//     .clk                    (clk),

//     .mem_address            (inst_mem_address),
//     .mem_byte_enable_cpu    (inst_mem_byte_enable),
//     .mem_wdata_cpu          (inst_mem_wdata),
//     .mem_rdata_cpu          (inst_mem_rdata),
//     .mem_read               (inst_mem_read),
//     .mem_write              (inst_mem_write),
//     .mem_resp               (inst_mem_resp),

//     .pmem_read              (imem_read),
//     .pmem_write             (imem_write),
//     .pmem_rdata             (imem_rdata),
//     .pmem_wdata             (imem_wdata),
//     .pmem_resp              (imem_resp),
//     .pmem_address           (imem_address)
// );
// cache Dcache(
//     .clk                    (clk),

//     .mem_address            (data_mem_address),
//     .mem_byte_enable_cpu    (data_mem_byte_enable),
//     .mem_wdata_cpu          (data_mem_wdata),
//     .mem_rdata_cpu          (data_mem_rdata),
//     .mem_read               (data_mem_read),
//     .mem_write              (data_mem_write),
//     .mem_resp               (data_mem_resp),

//     .pmem_read              (dmem_read),
//     .pmem_write             (dmem_write),
//     .pmem_rdata             (dmem_rdata),
//     .pmem_wdata             (dmem_wdata),
//     .pmem_resp              (dmem_resp),
//     .pmem_address           (dmem_address)
// );

arbiter arbiter(.*);
cacheline_adaptor cacheline_adaptor(
    .clk,
    .reset_n    (~rst),
    // Arbiter
    .line_i     (mmem_wdata),
    .line_o     (mmem_rdata),
    .address_i  (mmem_address),
    .read_i     (mmem_read),
    .write_i    (mmem_write),
    .resp_o     (mmem_resp),
    // Memory
    .burst_i    (mem_rdata),
    .burst_o    (mem_wdata),
    .address_o  (mem_address),
    .read_o     (mem_read),
    .write_o    (mem_write),
    .resp_i     (mem_resp)
);

endmodule