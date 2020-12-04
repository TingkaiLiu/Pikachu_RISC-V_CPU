/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input logic clk,
    input logic rst,
    // from datapath
    input logic [2:0] lru_i,
    input logic [3:0] valid_i,
    input logic [3:0] dirty_i,
    input logic [3:0] hit_i,
    // to datapath
    output dimux::dimux_sel_t dimux_sel,
    output domux::domux_sel_t domux_sel,
    output addrmux::addrmux_sel_t addrmux_sel,
    output wemux::wemux_sel_t wemux_sel [3:0],
    output logic [3:0] valid_load,
    output logic [3:0] dirty_load,
    output logic [3:0] tag_load,
    output logic [3:0] valid_o,
    output logic [3:0] dirty_o,
    // CPU
    input logic mem_read,
    input logic mem_write,
    output logic mem_resp,
    // cacheline adaptor
    input logic pmem_resp,
    output logic pmem_read,
    output logic pmem_write
);

logic [1:0] hit_way_num;
always_comb begin
    hit_way_num = 2'b00;
    case (hit_i)
        4'b0001: hit_way_num = 2'b00;
        4'b0010: hit_way_num = 2'b01;
        4'b0100: hit_way_num = 2'b10;
        4'b1000: hit_way_num = 2'b11;
        default: ;
    endcase
end

logic [1:0] rpl_way_num;
always_comb begin
    rpl_way_num = 2'b00;
    case (lru_i)
        // X11 - 0
        3'b011: rpl_way_num = 2'b00;
        3'b111: rpl_way_num = 2'b00;
        // X01 - 1
        3'b001: rpl_way_num = 2'b01;
        3'b101: rpl_way_num = 2'b01;
        // 1X0 - 2
        3'b100: rpl_way_num = 2'b10;
        3'b110: rpl_way_num = 2'b10;
        // 0X0 - 3
        3'b000: rpl_way_num = 2'b11;
        3'b010: rpl_way_num = 2'b11;
        default: ;
    endcase
end

enum int unsigned {
    /* List of states */
    hit_check_state,
    write_back_state,
    read_back_state
} state, next_state;

function void set_defaults();
    dimux_sel = dimux::mem_wdata256_from_cpu;
    domux_sel = domux::data_array_0;
    addrmux_sel = addrmux::from_cpu;
    wemux_sel[0] = wemux::zeros;
    wemux_sel[1] = wemux::zeros;
    wemux_sel[2] = wemux::zeros;
    wemux_sel[3] = wemux::zeros;
    valid_load  = 4'b0000;
    valid_o     = 4'b0000;
    dirty_load  = 4'b0000;
    dirty_o     = 4'b0000;
    tag_load    = 4'b0000;
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
                if (hit_i != 4'b0000) begin
                    mem_resp = 1'b1;

                    if (mem_read)
                        domux_sel = domux::domux_sel_t'(hit_way_num);
                    else if (mem_write) begin
                        dimux_sel = dimux::mem_wdata256_from_cpu;
                        wemux_sel  [hit_way_num] = wemux::mbe;
                        dirty_load [hit_way_num] = 1'b1;
                        dirty_o    [hit_way_num] = 1'b1;
                    end
                end
            end
        write_back_state:
        begin
            pmem_write = 1'b1;
            domux_sel = domux::domux_sel_t'(rpl_way_num);
            addrmux_sel = addrmux::addrmux_sel_t'(rpl_way_num);
        end
        read_back_state:
        begin
            pmem_read = 1'b1;
            if (pmem_resp) begin
                dimux_sel = dimux::pmem_rdata_from_mem;   
                wemux_sel  [rpl_way_num] = wemux::ones;
                valid_load [rpl_way_num] = 1'b1;
                dirty_load [rpl_way_num] = 1'b1;
                tag_load   [rpl_way_num] = 1'b1;
                valid_o    [rpl_way_num] = 1'b1;
                dirty_o    [rpl_way_num] = 1'b0;
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
                if (hit_i == 4'b0000) begin
                    if (dirty_i[rpl_way_num] && valid_i[rpl_way_num])
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
