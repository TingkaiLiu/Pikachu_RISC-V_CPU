import rv32i_types::*;

module arbiter
(
    input clk,
    input rst,
    // I-Cache
    input logic imem_read,
    output llc_cacheline imem_rdata,
    output logic imem_resp,
    input rv32i_word imem_address,
    // D-Cache
    input logic dmem_read,
    input logic dmem_write,
    output llc_cacheline dmem_rdata,
    input llc_cacheline dmem_wdata,
    output logic dmem_resp,
    input rv32i_word dmem_address,
    // Memory
    output logic mmem_read,
    output logic mmem_write,
    input llc_cacheline mmem_rdata,
    output llc_cacheline mmem_wdata,
    input logic mmem_resp,
    output rv32i_word mmem_address
);

enum int unsigned {
    /* List of states */
    wait_state,
    i_mem_state,
    i_fin_state,
    d_mem_state,
    d_fin_state
} state, next_state;

assign imem_rdata = mmem_rdata;
assign dmem_rdata = mmem_rdata;
assign mmem_wdata = dmem_wdata;

function void set_defaults();
    imem_resp = 1'b0;
    dmem_resp = 1'b0;
    mmem_read = 1'b0;
    mmem_write = 1'b0;
    mmem_address = imem_address;
endfunction

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case (state)
        wait_state: ;
        i_mem_state:
            mmem_read = imem_read;
        d_mem_state:
        begin
            mmem_read = dmem_read;
            mmem_write = dmem_write;
            mmem_address = dmem_address;
        end
        i_fin_state:
            imem_resp = 1'b1;
        d_fin_state:
            dmem_resp = 1'b1;
        default: ;
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	next_state = state;
    case (state)
        wait_state:
            if (imem_read)
                next_state = i_mem_state;
            else if (dmem_read || dmem_write)
                next_state = d_mem_state;
        i_mem_state:
            if (mmem_resp)
                next_state = i_fin_state;
        d_mem_state:
            if (mmem_resp)
                next_state = d_fin_state;
        i_fin_state:
            if (imem_read)
                next_state = i_mem_state;
            else if (dmem_read || dmem_write)
                next_state = d_mem_state;
            else
                next_state = wait_state;
        d_fin_state:
            if (imem_read)
                next_state = i_mem_state;
            else if (dmem_read || dmem_write)
                next_state = d_mem_state;
            else
                next_state = wait_state;
        default: ;
    endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst)
        state <= wait_state;
    else
        state <= next_state;
end

endmodule