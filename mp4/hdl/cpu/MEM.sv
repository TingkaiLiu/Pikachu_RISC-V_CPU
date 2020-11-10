import rv32i_types::*;
import rv32i_packet::*;

module MEM
(
    input clk,
    input rst,
    // input rv32i_ctrl_packet_t ctrl,
    input rv32i_packet_t mem_in,
    output rv32i_packet_t mem_out,
    // Data Cache
    output rv32i_word data_mem_address,
    output rv32i_word data_mem_wdata,
    input rv32i_word data_mem_rdata,
    output logic [3:0] data_mem_byte_enable
);

assign inst_mem_address = mem_in.data.alu_out;
assign data_mem_wdata = mem_in.data.rs2_out;
assign mem_out.data.mdrreg_out = data_mem_rdata;

logic [1:0] mem_offset; // The low 2 bit of the address
assign mem_offset = mem_in.data.alu_out[1:0];

always_comb begin
    data_mem_byte_enable = 0;

    case (mem_in.inst.opcode)
        op_load: begin
            mem_out.data.wmask = 0;
            case (load_funct3_t'(mem_in.inst.funct3))
                lw: mem_out.rmask = 4'b1111;
                lh, lhu: mem_out.data.rmask = (4'b0011 << mem_offset);
                lb, lbu: mem_out.data.rmask = (4'b0001 << mem_offset);
            endcase
        end
        op_store: begin
            mem_out.data.rmask = 0;
            case (store_funct3_t'(mem_in.inst.funct3))
                sw: mem_out.data.wmask = 4'b1111;
                sh: mem_out.data.wmask = (4'b0011 << mem_offset);
                sb: mem_out.data.wmask = (4'b0001 << mem_offset);
            endcase

            data_mem_byte_enable = mem_out.data.wmask;
        end
        default: $fatal("Bad opcode in MEM!\n");
    endcase
end


endmodule
