/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst,
    // from datapath
    input logic lru_i,
    input logic [1:0] valid_i,
    input logic [1:0] dirty_i,
    input logic [1:0] cmp_i,
    // to datapath
    output dimux::dimux_sel_t dimux_sel,
    output domux::domux_sel_t domux_sel,
    output wemux::wemux_sel_t wemux_sel [1:0],
    output addrmux::addrmux_sel_t addrmux_sel,
    output logic lru_load,
    output logic [1:0] valid_load,
    output logic [1:0] dirty_load,
    output logic [1:0] tag_load,
    output logic lru_o,
    output logic [1:0] valid_o,
    output logic [1:0] dirty_o,
    // CPU
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,
    // cacheline adaptor
    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write
);

logic hit0; 
assign hit0 = valid_i[0] && cmp_i[0];
logic hit1; 
assign hit1 = valid_i[1] && cmp_i[1];

enum int unsigned {
    /* List of states */
    hit_check_state,
    write_back_state,
    read_back_state
} state, next_state;

function void set_defaults();
    dimux_sel = dimux::mem_wdata256_from_cpu;
    domux_sel = domux::data_array_0;
    wemux_sel[0] = wemux::zeros;
    wemux_sel[1] = wemux::zeros;
    addrmux_sel = addrmux::from_cpu;
    lru_load = 1'b0;
    lru_o = 1'b0;
    valid_load = 2'b00;
    valid_o = 2'b00;
    dirty_load = 2'b00;
    dirty_o = 2'b00;
    tag_load = 2'b00;
    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
endfunction

/*****************************************************************************/

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    /* Actions for each state */
    case (state)
        hit_check_state:
            if (mem_read || mem_write) begin
                if (hit0 || hit1) begin
                    lru_o = hit0;
                    lru_load = 1'b1;
                    mem_resp = 1'b1;
                    if (mem_read)
                        domux_sel = domux::domux_sel_t'(hit1);
                    else begin
                        dimux_sel = dimux::mem_wdata256_from_cpu;
                        wemux_sel[hit1] = wemux::mbe;
                        dirty_o[hit1] = 1'b1;
                        dirty_load[hit1] = 1'b1;
                    end
                end
            end
        write_back_state:
        begin
            domux_sel = domux::domux_sel_t'(lru_i);
            pmem_write = 1'b1;
            if (!lru_i)
                addrmux_sel = addrmux::cache_0;
            else
                addrmux_sel = addrmux::cache_1;
        end
        read_back_state:
        begin
            if (!lru_i)
            begin
                wemux_sel[0] = wemux::ones;
                dimux_sel = dimux::pmem_rdata_from_mem;   
                pmem_read = 1'b1;
                valid_o[0] = 1'b1;
                valid_load[0] = 1'b1;
                dirty_o[0] = 1'b0;
                dirty_load[0] = 1'b1;
                tag_load[0] = 1'b1;
            end
            else
            begin
                wemux_sel[1] = wemux::ones;
                dimux_sel = dimux::pmem_rdata_from_mem;   
                pmem_read = 1'b1;
                valid_o[1] = 1'b1;
                valid_load[1] = 1'b1;
                dirty_o[1] = 1'b0;
                dirty_load[1] = 1'b1;
                tag_load[1] = 1'b1;
            end
        end
        default: ;
    endcase
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
	  next_state = state;
     case (state)
        hit_check_state:
            if (mem_read || mem_write) begin
                if (!(hit0 || hit1))
                begin
                    if (dirty_i[lru_i] && valid_i[lru_i])
                        next_state = write_back_state;
                    else
                        next_state = read_back_state;
                end
            end
        write_back_state:
            if (pmem_resp)
                next_state = read_back_state;
        read_back_state:
            if (pmem_resp)
                next_state = hit_check_state;
        default: ;
     endcase
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    if (rst)
        state <= hit_check_state;
    else
        state <= next_state;
end

endmodule : cache_control
