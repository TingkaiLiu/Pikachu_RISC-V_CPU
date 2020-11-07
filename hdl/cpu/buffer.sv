import rv32i_types::*;
import rv32i_packet::*;
import buffer_load;

module buffer
(
    input logic clk,
    input logic rst,
    input buffer_load_t load,
    input rv32i_packet_t packet_in_old,
    input rv32i_packet_t packet_in_new,
    output rv32i_packet_t packet_out
);



endmodule