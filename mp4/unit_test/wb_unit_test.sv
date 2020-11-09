import rv32i_types::*;
import rv32i_packet::*;

module wb_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

rv32i_ctrl_packet_t ctrl;
rv32i_packet_t wb_in;
// Regfile
rv32i_word regfile_in;
rv32i_reg dest;

WB dut(.*);

task automatic test_wb(
    regfilemux::regfilemux_sel_t regfilemux_sel_feed,
    logic [4:0] data_mem_byte_enable_feed,
    rv32i_word alu_out_feed,
    logic br_en_feed,
    rv32i_word u_imm_feed,
    rv32i_word mdrreg_out_feed,
    rv32i_word pc_feed,
    rv32i_reg rd_feed,

    rv32i_word regfile_in_exp,
    rv32i_reg dest_exp,
    int line
);
    @(posedge clk);
    ctrl.regfilemux_sel = regfilemux_sel_feed;
    ctrl.data_mem_byte_enable = data_mem_byte_enable_feed;
    wb_in.data.alu_out = alu_out_feed;
    wb_in.data.br_en = br_en_feed;
    wb_in.inst.u_imm = u_imm_feed;
    wb_in.data.mdrreg_out = mdrreg_out_feed;
    wb_in.data.pc = pc_feed;
    wb_in.inst.rd = rd_feed;
    @(posedge clk);

    if (dest != dest_exp) $fatal("%0t %s %0d: dest error, exp: %x, actual: %x", $time, `__FILE__, line, dest_exp, dest);
    if (regfile_in != regfile_in_exp) $fatal("%0t %s %0d: regfile_in error, exp: %x, actual: %x", $time, `__FILE__, line, regfile_in_exp, regfile_in);
    
    @(posedge clk);
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // TEST: pc_plus4
    test_wb(
    regfilemux::pc_plus4, // regfilemux_sel_feed,
    4'b1111,
    32'h00000000, // alu_out_feed,
    1'b1, // br_en_feed,
    32'h11111111, // u_imm_feed,
    32'h22334455, // mdrreg_out_feed,
    32'h66666666, // pc_feed,
    5'b11100, // rd_feed,

    32'h6666666A, // regfile_in_exp,
    5'b11100, // dest_exp,
    `__LINE__
    );
    
    // TEST: mem_byte_enable
    test_wb(
    regfilemux::lb, // regfilemux_sel_feed,
    4'b0010,
    32'h00000000, // alu_out_feed,
    1'b1, // br_en_feed,
    32'h11111111, // u_imm_feed,
    32'h22334455, // mdrreg_out_feed,
    32'h66666666, // pc_feed,
    5'b11100, // rd_feed,

    32'h00000044, // regfile_in_exp,
    5'b11100, // dest_exp,
    `__LINE__
    );

    $finish;
end

endmodule