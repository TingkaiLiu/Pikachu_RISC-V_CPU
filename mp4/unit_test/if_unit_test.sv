import rv32i_types::*;
import rv32i_packet::*;

module if_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

// From control
logic if_load_pc;
pcmux::pcmux_sel_t if_pcmux_sel;
// From other stages
rv32i_word if_alu_out;
// I-cache
rv32i_word if_inst_mem_address;
rv32i_word if_inst_mem_rdata;
// To next stage
rv32i_packet_t if_out;

IF dut(
    .*,
    .load_pc(if_load_pc),
    .pcmux_sel(if_pcmux_sel),
    .alu_out(if_alu_out),
    .inst_mem_address(if_inst_mem_address),
    .inst_mem_rdata(if_inst_mem_rdata),
    .if_out
);

task automatic test_if
(
    pcmux::pcmux_sel_t pcmux_sel_feed, 
    logic [31:0] alu_out_feed,
    logic [31:0] inst_mem_rdata_feed, 
    logic [31:0] pc_exp,
    logic [31:0] inst_exp,
    int line
);
    @(posedge clk);
    if_load_pc = 1'b1;
    if_pcmux_sel = pcmux_sel_feed;
    if_alu_out = alu_out_feed;
    if_inst_mem_rdata = inst_mem_rdata_feed;
    @(posedge clk);
    if_load_pc = 1'b0;
    @(posedge clk);
    if (if_out.data.instruction != inst_exp) $fatal("%0t %s %0d: instruction error, exp: %x, actual: %x", $time, `__FILE__, line, inst_exp, if_out.data.instruction);
    if (if_out.data.pc != pc_exp) $fatal("%0t %s %0d: pc error, exp: %x, actual: %x", $time, `__FILE__, line, pc_exp, if_out.data.pc);
    @(posedge clk);
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    
    // TEST: test pc_plus4
    test_if(
        pcmux::pc_plus4,// pcmux_sel_feed
        32'hAABBCCDD,   // alu_out_feed
        32'h11111111,   // inst_mem_rdata_feed
        32'h00000064,   // pc_exp
        32'h11111111,   // inst_exp
        `__LINE__
    );

    // TEST: test alu_out
    test_if(
        pcmux::alu_out,
        32'hAABBCCDD,   // alu_out_feed
        32'h22222222,   // inst_mem_rdata_feed
        32'hAABBCCDD,   // pc_exp
        32'h22222222,   // inst_exp
        `__LINE__
    );

    // TEST: test alu_mod2
    test_if(
        pcmux::alu_mod2,
        32'hAABBCCDF,   // alu_out_feed
        32'h22222222,   // inst_mem_rdata_feed
        32'hAABBCCDE,   // pc_exp
        32'h22222222,   // inst_exp
        `__LINE__
    );

    // TEST: test bad pcmux_sel
    // test_if(
    //     2'b11,
    //     32'hAABBCCD7,   // alu_out_feed
    //     32'h22222222,   // inst_mem_rdata_feed
    //     32'hXXXXXXXX,   // pc_exp
    //     32'h22222222,   // inst_exp
    //     `__LINE__
    // );

    $finish;
end

endmodule