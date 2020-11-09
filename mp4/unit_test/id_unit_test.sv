import rv32i_types::*;
import rv32i_packet::*;

module id_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

rv32i_packet_t ir_in;
rv32i_packet_t ir_out;
// Connection with control rom 
rv32i_opcode opcode;
logic [2:0] funct3;
logic [6:0] funct7;
rv32i_ctrl_packet_t ctrl;
// Connection with regfile
logic [4:0] rs1;
logic [4:0] rs2;
rv32i_word reg_a;
rv32i_word reg_b;

ID id(.*);

task automatic test_id
(
    logic [31:0] instruction_feed,
    rv32i_opcode opcode_exp,
    logic [2:0] funct3_exp,
    logic [6:0] funct7_exp,
    rv32i_reg rs1_exp,
    rv32i_reg rs2_exp,
    int line
);
    @(posedge clk);
    ir_in.data.instruction = instruction_feed;
    @(posedge clk);
    if (opcode != opcode_exp) $fatal("%0t %s %0d: opcode error, exp: %x, actual: %x", $time, `__FILE__, line, opcode_exp, opcode);
    if (funct3 != funct3_exp) $fatal("%0t %s %0d: funct3 error, exp: %x, actual: %x", $time, `__FILE__, line, funct3_exp, funct3);
    if (funct7 != funct7_exp) $fatal("%0t %s %0d: funct7 error, exp: %x, actual: %x", $time, `__FILE__, line, funct7_exp, funct7);
    if (rs1 != rs1_exp) $fatal("%0t %s %0d: rs1 error, exp: %x, actual: %x", $time, `__FILE__, line, rs1_exp, rs1);
    if (rs2 != rs2_exp) $fatal("%0t %s %0d: rs2 error, exp: %x, actual: %x", $time, `__FILE__, line, rs2_exp, rs2);
    @(posedge clk);
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    // TEST: test decode
    test_id(
        32'hF0F0F0F0,   // instruction_feed
        rv32i_opcode'(7'b1110000),     // opcode_exp
        3'b111,         // funct3_exp
        7'b1111000,     // funct7_exp
        5'b00001,       // rs1_exp
        5'b01111,       // rs2_exp
        `__LINE__
    );

    $finish;
end

endmodule