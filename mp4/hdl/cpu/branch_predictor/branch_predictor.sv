import rv32i_types::*;
import rv32i_packet::*;

module branch_predictor #(
    parameter s_bhr = 2
)
(
    clk,
    rst,
    load_buffer,
    if_pc,
    if_pred_pc,
    wb_pkt
);

input  clk;
input  rst;
input  load_buffer;
input  [31:0] if_pc;
output [31:0] if_pred_pc;
input  rv32i_packet_t wb_pkt;

// array
logic load;
logic [s_bhr-1:0] bhr_in, bhr_out;
logic [1:0] pht_in, pht_out;
logic [31:0] btb_in, btb_out;
logic [s_bhr-1:0] rindex;
logic [s_bhr-1:0] windex;

// for branch predict
logic [1:0] pht_out_pred;
logic [31:0] btb_out_pred;
logic [s_bhr-1:0] bpindex;

assign bpindex = if_pc[s_bhr-1:0] ^ bhr_out;
assign if_pred_pc = (pht_out_pred[1]) ? btb_out_pred : if_pc + 4;

// for update tables
logic actl_take;
assign actl_take = (wb_pkt.data.pc + 4 == wb_pkt.data.next_pc) ? 1'b0 : 1'b1;
logic update;
assign update = (load_buffer && wb_pkt.valid && 
    ((wb_pkt.inst.opcode == op_br) || (wb_pkt.inst.opcode == op_jal) || (wb_pkt.inst.opcode == op_jalr))) ? 1'b1 : 1'b0;
assign rindex = wb_pkt.data.pc[s_bhr-1:0] ^ bhr_out;

// update logic
always_ff @(posedge clk) begin
    if (update) begin
        load <= 1'b1;
        windex <= wb_pkt.data.pc[s_bhr-1:0] ^ bhr_out;
        bhr_in <= (bhr_out << 1) | {{(s_bhr-1){1'b0}}, actl_take};
        if (actl_take) begin
            case (pht_out)
                2'b00: pht_in <= 2'b01;
                2'b01: pht_in <= 2'b10;
                2'b10: pht_in <= 2'b11;
                2'b11: pht_in <= 2'b11;
            endcase
        end
        else begin
            case (pht_out)
                2'b00: pht_in <= 2'b00;
                2'b01: pht_in <= 2'b00;
                2'b10: pht_in <= 2'b01;
                2'b11: pht_in <= 2'b10;
            endcase
        end
        btb_in <= (actl_take) ? wb_pkt.data.next_pc : btb_out;
    end 
    else begin
        load <= 1'b0;
        windex <= windex;
        bhr_in <= bhr_out;
        pht_in <= pht_out;
        btb_in <= btb_out;
    end
end

bhr_reg   #(s_bhr) BHR (.*, .load, .in(bhr_in), .out(bhr_out));
pht_array #(s_bhr) PHT (.*, .load, .bpindex, .rindex, .windex, .datain(pht_in), .bpdataout(pht_out_pred), .dataout(pht_out));
btb_array #(s_bhr) BTB (.*, .load, .bpindex, .rindex, .windex, .datain(btb_in), .bpdataout(btb_out_pred), .dataout(btb_out));

endmodule : branch_predictor