import rv32i_types::*;
import rv32i_packet::*;

module ex_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

rv32i_ctrl_packet_t ctrl;
rv32i_packet_t ex_in;
rv32i_packet_t ex_out;
// From other stages
rv32i_word from_exmem;
rv32i_word from_memwb;

EX dut(.*);

endtask

task automatic test_alu(
    alu_ops aluop_feed,
    alumux::alumux1_sel_t alumux1_sel_feed,
    alumux::alumux2_sel_t alumux2_sel_feed,
    forward::forward_t alumux1_fw_feed,
    forward::forward_t alumux2_fw_feed,
    
    rv32i_word from_exmem_feed,
    rv32i_word from_memwb_feed,
    rv32i_word rs1_out_feed,
    rv32i_word rs2_out_feed,
    rv32i_word pc_feed,
    rv32i_word i_imm_feed,
    rv32i_word u_imm_feed,
    rv32i_word b_imm_feed,
    rv32i_word s_imm_feed,
    rv32i_word j_imm_feed,

    rv32i_word alumux1_out_exp,
    rv32i_word alumux2_out_exp,
    rv32i_word alu_out_exp,
    int line
);
    @(posedge clk);
    ctrl.aluop = aluop_feed;
    ctrl.alumux1_sel = alumux1_sel_feed;
    ctrl.alumux2_sel = alumux2_sel_feed;
    ctrl.alumux1_fw = alumux1_fw_feed;
    ctrl.alumux2_fw = alumux2_fw_feed;

    from_exmem = from_exmem_feed;
    from_memwb = from_memwb_feed;
    ex_in.data.rs1_out = rs1_out_feed;
    ex_in.data.rs2_out = rs2_out_feed;
    ex_in.data.pc = pc_feed;
    ex_in.inst.i_imm = i_imm_feed;
    ex_in.inst.u_imm = u_imm_feed;
    ex_in.inst.b_imm = b_imm_feed;
    ex_in.inst.s_imm = s_imm_feed;
    ex_in.inst.j_imm = j_imm_feed;
    @(posedge clk);

    if (ex_out.data.alu_out != alu_out_exp) $fatal("%0t %s %0d: alu_out error, exp: %x, actual: %x", $time, `__FILE__, line, alu_out_exp, ex_out.data.alu_out);
    if (dut.alumux1_out != alumux1_out_exp) $fatal("%0t %s %0d: alumux1_out error, exp: %x, actual: %x", $time, `__FILE__, line, alumux1_out_exp, dut.alumux1_out);
    if (dut.alumux2_out != alumux2_out_exp) $fatal("%0t %s %0d: alumux2_out error, exp: %x, actual: %x", $time, `__FILE__, line, alumux2_out_exp, dut.alumux2_out);
    
    @(posedge clk);
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // TEST:
    test_alu(
    alu_add, // aluop_feed,
    alumux::rs1_out, // alumux1_sel_feed,
    alumux::rs2_out, // alumux2_sel_feed,
    forward::from_idex, // alumux1_fw_feed,
    forward::from_idex, // alumux2_fw_feed,
    
    32'h00000000, // from_exmem_feed,
    32'h11111111, // from_memwb_feed,
    32'h22222222, // rs1_out_feed,
    32'h33333333, // rs2_out_feed,
    32'h44444444, // pc_feed,
    32'h55555555, // i_imm_feed,
    32'h66666666, // u_imm_feed,
    32'h77777777, // b_imm_feed,
    32'h88888888, // s_imm_feed,
    32'h99999999, // j_imm_feed,

    32'h22222222, // alumux1_out_exp,
    32'h33333333, // alumux2_out_exp,
    32'h55555555, // alu_out_exp,
    `__LINE__
    );

    test_alu(
    alu_xor, // aluop_feed,
    alumux::rs1_out, // alumux1_sel_feed,
    alumux::rs2_out, // alumux2_sel_feed,
    forward::from_exmem, // alumux1_fw_feed,
    forward::from_memwb, // alumux2_fw_feed,
    
    32'h00000000, // from_exmem_feed,
    32'h11111111, // from_memwb_feed,
    32'h22222222, // rs1_out_feed,
    32'h33333333, // rs2_out_feed,
    32'h44444444, // pc_feed,
    32'h55555555, // i_imm_feed,
    32'h66666666, // u_imm_feed,
    32'h77777777, // b_imm_feed,
    32'h88888888, // s_imm_feed,
    32'h99999999, // j_imm_feed,

    32'h00000000, // alumux1_out_exp,
    32'h11111111, // alumux2_out_exp,
    32'h11111111, // alu_out_exp,
    `__LINE__
    );
    
    $finish;
end

endmodule