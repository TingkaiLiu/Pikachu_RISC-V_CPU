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
assign wb_pkt = dut.cpu0.WB0.wb_in;

assign rvfi.commit = dut.cpu0.load_buffers && (wb_pkt.data.instruction != 32'h00000013); // Set high when a valid instruction is modifying regfile or PC
assign rvfi.halt = wb_pkt.inst.opcode == op_br && 
                    (wb_pkt.inst.rs1 == wb_pkt.inst.rs2) && 
                    (wb_pkt.data.pc == wb_pkt.data.alu_out);  // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO

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
assign rvfi.load_regfile = wb_pkt.ctrl.load_regfile;
assign rvfi.rd_addr = wb_pkt.inst.rd;
assign rvfi.rd_wdata = dut.cpu0.WB0.regfilemux_out;
assign rvfi.pc_rdata = wb_pkt.data.pc;
assign rvfi.pc_wdata = (wb_pkt.inst.opcode == op_jal 
                     || wb_pkt.inst.opcode == op_jalr
                     || (wb_pkt.inst.opcode == op_br && wb_pkt.data.br_en)) ? wb_pkt.data.alu_out : (wb_pkt.data.pc + 4);
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

// assign itf.inst_read  = 
// assign itf.inst_addr  = 
// assign itf.inst_resp  = 
// assign itf.inst_rdata = 
// assign itf.data_read  = 
// assign itf.data_write = 
// assign itf.data_mbe   = 
// assign itf.data_addr  = 
// assign itf.data_wdata = 
// assign itf.data_resp  = 
// assign itf.data_rdata = 
/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.cpu0.regfile0.data;

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