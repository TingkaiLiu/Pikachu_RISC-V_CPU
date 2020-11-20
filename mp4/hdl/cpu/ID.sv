import rv32i_types::*;
import rv32i_packet::*;

module ID
(
    input clk,
    input rst,
    
    input rv32i_packet_t id_in,
    output rv32i_packet_t id_out, // contains only the new values from this stage

    // Control hazard
    input logic correct_pc_prediction,

    // Data hazard
    input rv32i_packet_t ex_in, mem_in, wb_in,
    input logic br_en,
    input rv32i_word alu_out,
    input rv32i_word data_mem_rdata,
    input logic [31:0] regfile_in,
    
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

// Handle data hazard: nested if for priority handling
always_comb begin    
    id_out.data.rs1_out = reg_a;
    id_out.data.rs2_out = reg_b;
    
    // rs1
    if (rs1) begin // won't forward for x0
        // From EX
        if (ex_in.valid && ex_in.ctrl.wb && rs1 == ex_in.inst.rd) begin
            case (ex_in.ctrl.regfilemux_sel) 
                regfilemux::alu_out: id_out.data.rs1_out = alu_out;
                regfilemux::br_en: id_out.data.rs1_out = {31'b0, br_en};
                regfilemux::u_imm: id_out.data.rs1_out = ex_in.inst.u_imm;
                regfilemux::pc_plus4: id_out.data.rs1_out = ex_in.data.pc + 4;
            endcase
        end
        // From MEM
        else if (mem_in.valid && mem_in.ctrl.wb && rs1 == mem_in.inst.rd) begin
            case (mem_in.ctrl.regfilemux_sel)
                regfilemux::lb: begin
                    case (mem_in.data.rmask)
                        4'b0001: id_out.data.rs1_out = {{24{data_mem_rdata[7]}}, data_mem_rdata[7:0]};
                        4'b0010: id_out.data.rs1_out = {{24{data_mem_rdata[15]}}, data_mem_rdata[15:8]};
                        4'b0100: id_out.data.rs1_out = {{24{data_mem_rdata[23]}}, data_mem_rdata[23:16]};
                        4'b1000: id_out.data.rs1_out = {{24{data_mem_rdata[31]}}, data_mem_rdata[31:24]};
                        default: $fatal("ID: Bad rmask of lb!\n");
                    endcase
                end
                regfilemux::lbu: begin
                    case (mem_in.data.rmask)
                        4'b0001: id_out.data.rs1_out = {24'b0, data_mem_rdata[7:0]};
                        4'b0010: id_out.data.rs1_out = {24'b0, data_mem_rdata[15:8]};
                        4'b0100: id_out.data.rs1_out = {24'b0, data_mem_rdata[23:16]};
                        4'b1000: id_out.data.rs1_out = {24'b0, data_mem_rdata[31:24]};
                        default: $fatal("ID: Bad rmask of lbu!\n");
                    endcase
                end
                regfilemux::lh: begin
                    case (mem_in.data.rmask)
                        4'b0011: id_out.data.rs1_out = {{16{data_mem_rdata[15]}}, data_mem_rdata[15:0]};
                        4'b1100: id_out.data.rs1_out = {{16{data_mem_rdata[31]}}, data_mem_rdata[31:16]};
                        default: $fatal("ID: Bad rmask of lh!\n");
                    endcase
                end
                regfilemux::lhu: begin
                    case(mem_in.data.rmask)
                        4'b0011: id_out.data.rs1_out = {16'b0, data_mem_rdata[15:0]};
                        4'b1100: id_out.data.rs1_out = {16'b0, data_mem_rdata[31:16]};
                        default: $fatal("ID: Bad rmask of lhu!\n");
                    endcase
                end
            endcase
        end
        // From WB
        else if (wb_in.valid && wb_in.ctrl.wb && rs1 == wb_in.inst.rd) begin
            id_out.data.rs1_out = regfile_in;
        end
    end

    // rs2
    if (rs2) begin // won't forward for x0
        // From EX
        if (ex_in.valid && ex_in.ctrl.wb && rs2 == ex_in.inst.rd) begin
            case (ex_in.ctrl.regfilemux_sel) 
                regfilemux::alu_out: id_out.data.rs2_out = alu_out;
                regfilemux::br_en: id_out.data.rs2_out = {31'b0, br_en};
                regfilemux::u_imm: id_out.data.rs2_out = ex_in.inst.u_imm;
                regfilemux::pc_plus4: id_out.data.rs2_out = ex_in.data.pc + 4;
            endcase
        end
        // From MEM
        else if (mem_in.valid && mem_in.ctrl.wb && rs2 == mem_in.inst.rd) begin
            case (mem_in.ctrl.regfilemux_sel) 
                regfilemux::lb: begin
                    case (mem_in.data.rmask)
                        4'b0001: id_out.data.rs2_out = {{24{data_mem_rdata[7]}}, data_mem_rdata[7:0]};
                        4'b0010: id_out.data.rs2_out = {{24{data_mem_rdata[15]}}, data_mem_rdata[15:8]};
                        4'b0100: id_out.data.rs2_out = {{24{data_mem_rdata[23]}}, data_mem_rdata[23:16]};
                        4'b1000: id_out.data.rs2_out = {{24{data_mem_rdata[31]}}, data_mem_rdata[31:24]};
                        default: $fatal("ID: Bad rmask of lb!\n");
                    endcase
                end
                regfilemux::lbu: begin
                    case (mem_in.data.rmask)
                        4'b0001: id_out.data.rs2_out = {24'b0, data_mem_rdata[7:0]};
                        4'b0010: id_out.data.rs2_out = {24'b0, data_mem_rdata[15:8]};
                        4'b0100: id_out.data.rs2_out = {24'b0, data_mem_rdata[23:16]};
                        4'b1000: id_out.data.rs2_out = {24'b0, data_mem_rdata[31:24]};
                        default: $fatal("ID: Bad rmask of lbu!\n");
                    endcase
                end
                regfilemux::lh: begin
                    case (mem_in.data.rmask)
                        4'b0011: id_out.data.rs2_out = {{16{data_mem_rdata[15]}}, data_mem_rdata[15:0]};
                        4'b1100: id_out.data.rs2_out = {{16{data_mem_rdata[31]}}, data_mem_rdata[31:16]};
                        default: $fatal("ID: Bad rmask of lh!\n");
                    endcase
                end
                regfilemux::lhu: begin
                    case(mem_in.data.rmask)
                        4'b0011: id_out.data.rs2_out = {16'b0, data_mem_rdata[15:0]};
                        4'b1100: id_out.data.rs2_out = {16'b0, data_mem_rdata[31:16]};
                        default: $fatal("ID: Bad rmask of lhu!\n");
                    endcase
                end
            endcase
        end
        // From WB
        else if (wb_in.valid && wb_in.ctrl.wb && rs2 == wb_in.inst.rd) begin
            id_out.data.rs2_out = regfile_in;
        end
    end
end

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