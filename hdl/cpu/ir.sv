import rv32i_types::*;
import rv32i_packet::*;

module ir
(
    input clk,
    input rst,
    input load,
    input [31:0] in,
    output rv32i_ctrl_pkt_t ctrl
    // output [2:0] funct3,
    // output [6:0] funct7,
    // output rv32i_opcode opcode,
    // output [31:0] i_imm,
    // output [31:0] s_imm,
    // output [31:0] b_imm,
    // output [31:0] u_imm,
    // output [31:0] j_imm,
    // output [4:0] rs1,
    // output [4:0] rs2,
    // output [4:0] rd
);

logic [31:0] data;

assign ctrl.funct3 = data[14:12];
assign ctrl.funct7 = data[31:25];
assign ctrl.opcode = rv32i_opcode'(data[6:0]);
assign ctrl.i_imm = {{21{data[31]}}, data[30:20]};
assign ctrl.s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign ctrl.b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign ctrl.u_imm = {data[31:12], 12'h000};
assign ctrl.j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign ctrl.rs1 = data[19:15];
assign ctrl.rs2 = data[24:20];
assign ctrl.rd = data[11:7];

//why "=" instead of "<="
always_ff @(posedge clk)
begin
    if (rst)
    begin
        data <= '0;
    end
    else if (load == 1)
    begin
        data <= in;
    end
    else
    begin
        data <= data;
    end
end

endmodule : ir
