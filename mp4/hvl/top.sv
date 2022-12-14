import rv32i_types::*;
import rv32i_packet::*;

module mp4_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);

// For local simulation, add signal for Modelsim to display by default
// Note that this signal does nothing and is not used for anything
bit f;

/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

rv32i_packet_t wb_pkt;
assign wb_pkt = dut.cpu.WB.wb_in;

assign rvfi.commit = dut.cpu.load_buffers && wb_pkt.valid; // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = wb_pkt.valid && (wb_pkt.data.pc == wb_pkt.data.next_pc); // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

// Performance evaluation
// Total branches
int total_branches;
initial total_branches = 0;
always @(posedge itf.clk iff rvfi.commit && 
    (wb_pkt.inst.opcode == op_jal || wb_pkt.inst.opcode == op_jalr || wb_pkt.inst.opcode == op_br)) total_branches <= total_branches + 1;

// Branch predictor
int wrong_prediction;
initial wrong_prediction = 0;
always @(posedge itf.clk iff rvfi.commit && !wb_pkt.data.correct_pc_prediction) wrong_prediction <= wrong_prediction + 1;

// Total memory access
int mem_access;
initial mem_access = 0;
always @(posedge itf.clk iff rvfi.commit && wb_pkt.ctrl.mem) mem_access <= mem_access + 1;

// L1 cache miss
int dl1_miss;
initial dl1_miss = 0;
always @(posedge itf.clk iff dut.cache_top.Dcache2.control.state == 1) dl1_miss <= dl1_miss + 1;

int il1_miss;
initial il1_miss = 0;
always @(posedge itf.clk iff dut.cache_top.Icache2.control.state == 1) il1_miss <= il1_miss + 1;

// L2 cache miss
int dl2_miss;
initial dl2_miss = 0;
always @(posedge itf.clk iff dut.cache_top.Dcache2.control.state == 1 && !dut.cache_top.Dcache2.control.hit_i) 
    dl2_miss <= dl2_miss + 1;

int il2_miss;
initial il2_miss = 0;
always @(posedge itf.clk iff dut.cache_top.Icache2.control.state == 1 && !dut.cache_top.Icache2.control.hit_i) 
    il2_miss <= il2_miss + 1;

// Stall
int stall_count;
initial stall_count = 0;
always @(posedge itf.clk iff dut.cpu.id_ex_sel == buffer_load_mux::load_invalid) stall_count <= stall_count + 1;

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap
Regfile:
    rvfi.rs1_addr
    rvfi.rs2_addr
    rvfi.rs1_rdata
    rvfi.rs2_rdata
    rvfi.load_regfile
    rvfi.rd_addr
    rvfi.rd_wdata

PC:
    rvfi.pc_rdata
    rvfi.pc_wdata

Memory:
    rvfi.mem_addr
    rvfi.mem_rmask
    rvfi.mem_wmask
    rvfi.mem_rdata
    rvfi.mem_wdata

Please refer to rvfi_itf.sv for more information.
*/

assign rvfi.inst = wb_pkt.data.instruction;
assign rvfi.trap = wb_pkt.inst.trap;
assign rvfi.rs1_addr = wb_pkt.inst.rs1;
assign rvfi.rs2_addr = wb_pkt.inst.rs2;
assign rvfi.rs1_rdata = wb_pkt.data.rs1_out;
assign rvfi.rs2_rdata = wb_pkt.data.rs2_out;
assign rvfi.load_regfile = dut.cpu.load_regfile;
assign rvfi.rd_addr = wb_pkt.inst.rd;
assign rvfi.rd_wdata = dut.cpu.regfile_in;
assign rvfi.pc_rdata = wb_pkt.data.pc;
assign rvfi.pc_wdata = wb_pkt.data.next_pc;
assign rvfi.mem_addr = wb_pkt.data.mem_addr;
assign rvfi.mem_rmask = wb_pkt.data.rmask;
assign rvfi.mem_wmask = wb_pkt.data.wmask;
assign rvfi.mem_rdata = wb_pkt.data.mem_rdata;
assign rvfi.mem_wdata = wb_pkt.data.mem_wdata;

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
/*
The following signals need to be set:
icache signals:
    itf.inst_read
    itf.inst_addr
    itf.inst_resp
    itf.inst_rdata

dcache signals:
    itf.data_read
    itf.data_write
    itf.data_mbe
    itf.data_addr
    itf.data_wdata
    itf.data_resp
    itf.data_rdata

Please refer to tb_itf.sv for more information.
*/
assign itf.inst_read  = dut.cache_top.Icache1.mem_read;
assign itf.inst_addr  = dut.cache_top.Icache1.mem_address;
assign itf.inst_resp  = dut.cache_top.Icache1.mem_resp;
assign itf.inst_rdata = dut.cache_top.Icache1.mem_rdata;
assign itf.data_read  = dut.cache_top.Dcache1.mem_read;
assign itf.data_write = dut.cache_top.Dcache1.mem_write;
assign itf.data_mbe   = dut.cache_top.Dcache1.mem_byte_enable;
assign itf.data_addr  = dut.cache_top.Dcache1.mem_address;
assign itf.data_wdata = dut.cache_top.Dcache1.mem_wdata;
assign itf.data_resp  = dut.cache_top.Dcache1.mem_resp;
assign itf.data_rdata = dut.cache_top.Dcache1.mem_rdata;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.cpu.regfile.data;

/*********************** Instantiate your design here ************************/
/*
The following signals need to be connected to your top level:
Clock and reset signals:
    itf.clk
    itf.rst

Burst Memory Ports:
    itf.mem_read
    itf.mem_write
    itf.mem_wdata
    itf.mem_rdata
    itf.mem_addr
    itf.mem_resp

Please refer to tb_itf.sv for more information.
*/

mp4 dut(
    .clk                    (itf.clk), 
    .rst                    (itf.rst),

    // Memory
    .mem_read               (itf.mem_read),
    .mem_write              (itf.mem_write),
    .mem_wdata              (itf.mem_wdata),
    .mem_rdata              (itf.mem_rdata),
    .mem_address            (itf.mem_addr),
    .mem_resp               (itf.mem_resp)
);

/***************************** End Instantiation *****************************/

endmodule