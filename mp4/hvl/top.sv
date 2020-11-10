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

mp4 dut(
    .clk                    (itf.clk), 
    .rst                    (itf.rst),

    // Memory
    .inst_mem_address       (itf.inst_addr),
    .inst_mem_read          (itf.inst_read),
    .inst_mem_write         (), // hang
    .inst_mem_byte_enable   (), // hang
    .inst_mem_rdata         (itf.inst_rdata),
    .inst_mem_wdata         (), // hang
    .inst_mem_resp          (itf.inst_resp),

    .data_mem_address       (itf.data_addr),
    .data_mem_read          (itf.data_read),
    .data_mem_write         (itf.data_write),
    .data_mem_byte_enable   (itf.data_mbe),
    .data_mem_rdata         (itf.data_rdata),
    .data_mem_wdata         (itf.data_wdata),
    .data_mem_resp          (itf.data_resp)
);

/************************ Signals necessary for monitor **********************/
// This section not required until CP2

assign rvfi.commit = 0; // Set high when a valid instruction is modifying regfile or PC

// Set high when you detect an infinite loop
assign rvfi.halt = dut.cpu0.EX0.ex_in.inst.opcode == op_br && 
                    (dut.cpu0.EX0.ex_in.inst.rs1 == dut.cpu0.EX0.ex_in.inst.rs2) && 
                    (dut.cpu0.EX0.ex_in.data.pc == dut.cpu0.EX0.alu_out);   

initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

/*
The following signals need to be set:
Instruction and trap:
    rvfi.inst
    rvfi.trap

Regfile:
    rvfi.rs1_addr
    rvfi.rs2_add
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

// assign rvfi.inst = dut.cpu0.WB0.wb_in.data.instruction;
// // assign rvfi.trap = 
// assign rvfi.rs1_addr = dut.cpu0.WB0.wb_in.inst.rs1;
// assign rvfi.rs2_addr = dut.cpu0.WB0.wb_in.inst.rs2;
// assign rvfi.rs1_rdata = dut.cpu0.WB0.wb_in.data.rs1_out;
// assign rvfi.rs2_rdata = dut.cpu0.WB0.wb_in.data.rs2_out;
// assign rvfi.load_regfile = dut.cpu0.WB0.wb_in.ctrl.load_regfile;
// assign rvfi.rd_addr = dut.cpu0.WB0.wb_in.inst.rd;
// assign rvfi.rd_wdata = dut.cpu0.WB0.regfile_in;
// assign rvfi.pc_rdata = 
// assign rvfi.pc_wdata = 
// assign rvfi.mem_addr = 
// assign rvfi.mem_rmask = 
// assign rvfi.mem_wmask = 
// assign rvfi.mem_rdata = 
// assign rvfi.mem_wdata = 

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

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = '{default: '0};

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

assign itf.mem_read = itf.data_read;
assign itf.mem_write = itf.data_write;
assign itf.mem_addr = itf.data_addr;
assign itf.mem_wdata = itf.data_wdata;
assign itf.mem_resp = itf.data_resp;
assign itf.mem_rdata = itf.data_rdata;

/***************************** End Instantiation *****************************/

endmodule
