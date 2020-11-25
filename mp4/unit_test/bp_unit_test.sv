import rv32i_types::*;
import rv32i_packet::*;

module bp_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

logic load_buffer;
logic [31:0] if_pc;
logic [31:0] if_pred_pc;
rv32i_packet_t wb_pkt;

branch_predictor dut(
    .*
);

task automatic test_bp_predict
(
    logic [31:0] if_pc_feed,
    logic [31:0] exp_if_pred_pc,
    int line
);
    @(posedge clk);
    load_buffer = 1'b0;
    if_pc = if_pc_feed;
    @(posedge clk);
    if (if_pred_pc != exp_if_pred_pc) 
        $fatal("%0t %s %0d: pred_take error, exp: %x, actual: %x", $time, `__FILE__, line, exp_if_pred_pc, if_pred_pc);
    @(posedge clk);
endtask

task automatic test_bp_update
(
    logic [31:0] wb_pc,
    logic [31:0] wb_next_pc,
    rv32i_opcode wb_opcode,
    int line
);
    @(posedge clk);
    load_buffer = 1'b1;
    wb_pkt.valid = 1'b1;
    wb_pkt.data.pc = wb_pc;
    wb_pkt.data.next_pc = wb_next_pc;
    wb_pkt.inst.opcode = wb_opcode;
    @(posedge clk);
    load_buffer = 1'b0;
    wb_pkt.valid = 1'b0;
    @(posedge clk);
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    
    // TEST: 
    test_bp_predict(32'h00001110, 32'h00001114, `__LINE__);
    test_bp_predict(32'h00001111, 32'h00001115, `__LINE__);
    test_bp_predict(32'h00001112, 32'h00001116, `__LINE__);
    test_bp_predict(32'h00001113, 32'h00001117, `__LINE__);

    test_bp_update(32'h00001111, 32'h11112222, op_br, `__LINE__);
    // 00 ^ 01 = 01 - 10
    // bhr = 01
    test_bp_predict(32'h00001110, 32'h11112222, `__LINE__);
    test_bp_predict(32'h00001111, 32'h00001115, `__LINE__);
    test_bp_predict(32'h00001112, 32'h00001116, `__LINE__);
    test_bp_predict(32'h00001113, 32'h00001117, `__LINE__);

    test_bp_update(32'h00001110, 32'h11112222, op_jal, `__LINE__);
    // 01 ^ 00 = 01 - 11
    // bhr = 11
    test_bp_predict(32'h00001110, 32'h00001114, `__LINE__);
    test_bp_predict(32'h00001111, 32'h00001115, `__LINE__);
    test_bp_predict(32'h00001112, 32'h11112222, `__LINE__);
    test_bp_predict(32'h00001113, 32'h00001117, `__LINE__);

    test_bp_update(32'h00001112, 32'h00001116, op_jal, `__LINE__);
    // 11 ^ 10 = 01 - 10
    // bhr = 10
    test_bp_predict(32'h00001110, 32'h00001114, `__LINE__);
    test_bp_predict(32'h00001111, 32'h00001115, `__LINE__);
    test_bp_predict(32'h00001112, 32'h00001116, `__LINE__);
    test_bp_predict(32'h00001113, 32'h11112222, `__LINE__);

    test_bp_update(32'h00001113, 32'h00001117, op_jal, `__LINE__);
    // 10 ^ 11 = 01 - 01
    // bhr = 00
    test_bp_predict(32'h00001110, 32'h00001114, `__LINE__);
    test_bp_predict(32'h00001111, 32'h00001115, `__LINE__);
    test_bp_predict(32'h00001112, 32'h00001116, `__LINE__);
    test_bp_predict(32'h00001113, 32'h00001117, `__LINE__);

    $finish;
end

endmodule