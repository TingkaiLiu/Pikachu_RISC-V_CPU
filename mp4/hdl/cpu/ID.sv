import rv32i_types::*;
import rv32i_packet::*;

module ID
(
    input clk,
    input rst,
    
    input rv32i_packet_t id_in,
    output rv32i_packet_t id_out, // contains only the new values from this stage

    input logic correct_pc_prediction,
    
    // Connection with control rom 
    output rv32i_opcode opcode, 
    output logic [2:0] funct3, 
    output logic [6:0] funct7,
    input rv32i_ctrl_packet_t ctrl,
    
    // Connection with regfile
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    input rv32i_word reg_a,
    input rv32i_word reg_b
);

// For control hazard, see whether the current inst is valid
assign id_out.valid = correct_pc_prediction && id_in.valid;

// Decode the instruction
logic [31:0] data;
assign data = id_in.data.instruction;

assign id_out.inst.funct3 = data[14:12];
assign id_out.inst.funct7 = data[31:25];
assign id_out.inst.opcode = rv32i_opcode'(data[6:0]);
assign id_out.inst.i_imm = {{21{data[31]}}, data[30:20]};
assign id_out.inst.s_imm = {{21{data[31]}}, data[30:25], data[11:7]};
assign id_out.inst.b_imm = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
assign id_out.inst.u_imm = {data[31:12], 12'h000};
assign id_out.inst.j_imm = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
assign id_out.inst.rs1 = data[19:15];
assign id_out.inst.rs2 = data[24:20];
assign id_out.inst.rd = data[11:7];

// Coneection with control rom
assign opcode = rv32i_opcode'(data[6:0]);
assign funct3 = data[14:12];
assign funct7 = data[31:25];
assign id_out.ctrl = ctrl;

// Connect with regfile
assign rs1 = id_out.inst.rs1;
assign rs2 = id_out.inst.rs2;
assign id_out.data.rs1_out = reg_a;
assign id_out.data.rs2_out = reg_b;

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
assign id_out.inst.trap = trap;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);

always_comb
begin : trap_check
    trap = 0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: ;
                lh, lhu: ;
                lb, lbu: ;
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: ;
                sh: ;
                sb: ;
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end
/*****************************************************************************/



endmodule