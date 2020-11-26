/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module Icache_control (
    input logic clk,
    input logic rst,
    // from datapath
    input logic [2:0] lru_i,
    input logic [3:0] valid_i,
    input logic [3:0] dirty_i,
    input logic [3:0] hit_i,

    input logic [2:0] nlru_i,
    input logic [3:0] nvalid_i,
    input logic [3:0] ndirty_i,
    input logic [3:0] nhit_i,
    // to datapath
    output logic load_prefetch_line,
    input logic pref_hit,
    output dimux::dimux_sel_t dimux_sel,
    output domux::domux_sel_t domux_sel,
    pwdatamux::pwdatamux_sel_t pwdatamux_sel,
    output addrmux::addrmux_sel_t addrmux_sel,
    output paddrmux::paddrmux_sel_t paddrmux_sel,
    output wemux::wemux_sel_t wemux_sel [3:0],
    output nwemux::nwemux_sel_t nwemux_sel [3:0],

    output logic lru_load,
    output logic [3:0] valid_load,
    output logic [3:0] dirty_load,
    output logic [3:0] tag_load,

    output logic nlru_load,
    output logic [3:0] nvalid_load,
    output logic [3:0] ndirty_load,
    output logic [3:0] ntag_load,

    output logic [2:0] lru_o,
    output logic [3:0] valid_o,
    output logic [3:0] dirty_o,

    output logic [2:0] nlru_o,
    output logic [3:0] nvalid_o,
    output logic [3:0] ndirty_o,
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

logic [1:0] nrpl_way_num;
always_comb begin
    nrpl_way_num = 2'b00;
    case (lru_i)
        // X11 - 0
        3'b011: nrpl_way_num = 2'b00;
        3'b111: nrpl_way_num = 2'b00;
        // X01 - 1
        3'b001: nrpl_way_num = 2'b01;
        3'b101: nrpl_way_num = 2'b01;
        // 1X0 - 2
        3'b100: nrpl_way_num = 2'b10;
        3'b110: nrpl_way_num = 2'b10;
        // 0X0 - 3
        3'b000: nrpl_way_num = 2'b11;
        3'b010: nrpl_way_num = 2'b11;
        default: ;
    endcase
end

logic [1:0] prefetch_rpl_way_num;
always_ff @(posedge clk) begin
    if (load_prefetch_line)
        prefetch_rpl_way_num <= nrpl_way_num;
end

// to avoid circular assignment
always_ff @(posedge clk) begin
    case (hit_i)
        4'b0001: begin lru_o[1] <= 1'b0; lru_o[0] <= 1'b0; lru_o[2] <= lru_i[2]; end
        4'b0010: begin lru_o[1] <= 1'b1; lru_o[0] <= 1'b0; lru_o[2] <= lru_i[2]; end
        4'b0100: begin lru_o[2] <= 1'b0; lru_o[0] <= 1'b1; lru_o[1] <= lru_i[1]; end
        4'b1000: begin lru_o[2] <= 1'b1; lru_o[0] <= 1'b1; lru_o[1] <= lru_i[1]; end
        default: lru_o <= lru_i;
    endcase
end

enum int unsigned {
    /* List of states */
    hit_check_state,
    write_back_state,
    read_back_state,
    prefetch_write_back_state,
    prefetch_read_back_state
} state, next_state;

function void set_defaults();
    load_prefetch_line = 1'b0;
    dimux_sel = dimux::mem_wdata256_from_cpu;
    domux_sel = domux::data_array_0;
    pwdatamux_sel = pwdatamux::domux_out;
    addrmux_sel = addrmux::from_cpu;
    paddrmux_sel = paddrmux::addrmux_out;
    for (int i = 0; i < 4; i++) begin
        wemux_sel[i] = wemux::zeros;
        nwemux_sel[i] = nwemux::zeros;
    end

    lru_load = 1'b0;
    valid_load  = 4'b0000;
    valid_o     = 4'b0000;
    dirty_load  = 4'b0000;
    dirty_o     = 4'b0000;
    tag_load    = 4'b0000;

    nlru_load = 1'b0;
    nvalid_load  = 4'b0000;
    nvalid_o     = 4'b0000;
    ndirty_load  = 4'b0000;
    ndirty_o     = 4'b0000;
    ntag_load    = 4'b0000;

    mem_resp = 1'b0;
    pmem_read = 1'b0;
    pmem_write = 1'b0;
endfunction

function void set_curr_hit();
    if (mem_read || mem_write) begin
        if (hit_i != 4'b0000 && hit_way_num != prefetch_rpl_way_num) begin
            lru_load = 1'b1;
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
                    lru_load = 1'b1;
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
            dimux_sel = dimux::pmem_rdata_from_mem;   
            wemux_sel  [rpl_way_num] = wemux::ones;
            if (pmem_resp) begin
                valid_load [rpl_way_num] = 1'b1;
                dirty_load [rpl_way_num] = 1'b1; 
                tag_load   [rpl_way_num] = 1'b1;
            end
            valid_o    [rpl_way_num] = 1'b1;
            dirty_o    [rpl_way_num] = 1'b0;
        end
        prefetch_write_back_state:
        begin
            set_curr_hit();
            pmem_write = 1'b1;
            ndirty_o    [prefetch_rpl_way_num] = 1'b0;
            pwdatamux_sel = pwdatamux::pwdatamux_sel_t'(prefetch_rpl_way_num);
            paddrmux_sel = paddrmux::paddrmux_sel_t'(prefetch_rpl_way_num);
        end
        prefetch_read_back_state:
        begin
            set_curr_hit();
            pmem_read = 1'b1;
            paddrmux_sel = paddrmux::prefetch_line;
            nwemux_sel [prefetch_rpl_way_num] = nwemux::ones;
            if (pmem_resp) begin
                nvalid_load [prefetch_rpl_way_num] = 1'b1;
                ndirty_load [prefetch_rpl_way_num] = 1'b1;
                ntag_load   [prefetch_rpl_way_num] = 1'b1;
            end
            nvalid_o    [prefetch_rpl_way_num] = 1'b1;
            ndirty_o    [prefetch_rpl_way_num] = 1'b0;
        end
        // hit_check_state:
        //     if (mem_read || mem_write) begin
        //         if (hit_i != 4'b0000) begin
        //             lru_load = 1'b1;
        //             mem_resp = 1'b1;

        //             if (mem_read)
        //                 domux_sel = domux::domux_sel_t'(hit_way_num);
        //             else if (mem_write) begin
        //                 dimux_sel = dimux::mem_wdata256_from_cpu;
        //                 wemux_sel  [hit_way_num] = wemux::mbe;
        //                 dirty_load [hit_way_num] = 1'b1;
        //                 dirty_o    [hit_way_num] = 1'b1;
        //             end
        //         end
        //     end
        // write_back_state:
        // begin
        //     pmem_write = 1'b1;
        //     domux_sel = domux::domux_sel_t'(rpl_way_num);
        //     addrmux_sel = addrmux::addrmux_sel_t'(rpl_way_num);
        // end
        // read_back_state:
        // begin
        //     pmem_read = 1'b1;
        //     dimux_sel = dimux::pmem_rdata_from_mem;   
        //     wemux_sel  [rpl_way_num] = wemux::ones;
        //     if (pmem_resp) begin
        //         valid_load [rpl_way_num] = 1'b1;
        //         dirty_load [rpl_way_num] = 1'b1; 
        //         tag_load   [rpl_way_num] = 1'b1;
        //     end
        //     valid_o    [rpl_way_num] = 1'b1;
        //     dirty_o    [rpl_way_num] = 1'b0;
        // end
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
                // if line_i is a miss
                if (hit_i == 4'b0000) begin
                    if (dirty_i[rpl_way_num] && valid_i[rpl_way_num])
                        next_state = write_back_state;
                    else
                        next_state = read_back_state;
                end 
                else begin // if line_i is a hit
                    // if line_i + 1 is a miss
                    if (nhit_i == 4'b0000) begin
                        load_prefetch_line = 1'b1;
                        if (ndirty_i[nrpl_way_num] && nvalid_i[nrpl_way_num])
                            next_state = prefetch_write_back_state;
                        else
                            next_state = prefetch_read_back_state;
                    end
                end
                
            end
        write_back_state:
            if (pmem_resp)
                next_state = read_back_state;
        read_back_state:
            if (pmem_resp)
                next_state = hit_check_state;
        prefetch_write_back_state:
            if (pmem_resp)
                if (pref_hit == 1'b0)
                    next_state = hit_check_state;
                else
                    next_state = prefetch_read_back_state;
        prefetch_read_back_state:
            if (pmem_resp)
                next_state = hit_check_state;
        
        // hit_check_state:
        //     if (mem_read || mem_write) begin
        //         if (hit_i == 4'b0000) begin
        //             if (dirty_i[rpl_way_num] && valid_i[rpl_way_num])
        //                 next_state = write_back_state;
        //             else
        //                 next_state = read_back_state;
        //         end
        //     end
        // write_back_state:
        //     if (pmem_resp)
        //         next_state = read_back_state;
        // read_back_state:
        //     if (pmem_resp)
        //         next_state = hit_check_state;
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

endmodule : Icache_control
