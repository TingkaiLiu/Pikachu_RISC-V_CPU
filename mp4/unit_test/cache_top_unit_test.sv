// Note: This unit test doesn't test the arbiter function. 
//       For arbiter, use arbiter_unit_test.
import rv32i_types::*;

module cache_top_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

// CPU - I-Cache
rv32i_word inst_mem_address;
logic inst_mem_read;
logic inst_mem_write;
logic [3:0] inst_mem_byte_enable;
rv32i_word inst_mem_rdata;
rv32i_word inst_mem_wdata;
logic inst_mem_resp;
// CPU - D-Cache
rv32i_word data_mem_address;
logic data_mem_read;
logic data_mem_write;
logic [3:0] data_mem_byte_enable;
rv32i_word data_mem_rdata;
rv32i_word data_mem_wdata;
logic data_mem_resp;
// Adaptor - Memory
logic mem_read;
logic mem_write;
logic [63:0] mem_wdata;
logic [63:0] mem_rdata;
logic [31:0] mem_address;
logic mem_resp;

cache_top dut(
    .*
);

int delay = 3;
llc_cacheline wb_wdata;

task automatic test_readi_miss
(
    rv32i_word addr,
    llc_cacheline rdata_feed,
    rv32i_word rdata_exp,
    int line
);
    @(posedge clk);
    inst_mem_read = 1'b1;
    inst_mem_address = addr;
    mem_resp = 1'b0;
    @(posedge clk);
    if (mem_resp) $fatal("%0t %s %0d: should not hit", $time, `__FILE__, line);
    repeat (3) @(posedge clk);
    if (~mem_read) $fatal("%0t %s %0d: not reading", $time, `__FILE__, line);
    if (mem_write) $fatal("%0t %s %0d: is writing", $time, `__FILE__, line);
    if ({addr[31:5], 5'b0} != mem_address)  $fatal("%0t %s %0d: mem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr, mem_address);
    repeat (delay) @(posedge clk);
    for (int i = 0; i < 4; ++i) begin
        mem_resp = 1'b1;
        mem_rdata = rdata_feed[64*i + :64];
        @(posedge clk);
    end
    mem_resp = 1'b0;
    @(posedge clk iff inst_mem_resp);
    inst_mem_read = 1'b0;
    if (rdata_exp != inst_mem_rdata)  $fatal("%0t %s %0d: rdata error, exp: %x, actual: %x", $time, `__FILE__, line, rdata_exp, inst_mem_rdata);
endtask

task automatic test_readi_hit
(
    rv32i_word addr,
    rv32i_word rdata_exp,
    int line
);
    @(posedge clk);
    inst_mem_read = 1'b1;
    inst_mem_address = addr;
    @(posedge clk);
    if (~inst_mem_resp) $fatal("%0t %s %0d: should hit", $time, `__FILE__, line);
    if (rdata_exp != inst_mem_rdata)  $fatal("%0t %s %0d: rdata error, exp: %x, actual: %x", $time, `__FILE__, line, rdata_exp, inst_mem_rdata);
    inst_mem_read = 1'b0;
endtask

task automatic test_readd_miss
(
    rv32i_word addr,
    llc_cacheline rdata_feed,
    rv32i_word rdata_exp,
    int line
);
    @(posedge clk);
    data_mem_read = 1'b1;
    data_mem_address = addr;
    mem_resp = 1'b0;
    @(posedge clk);
    if (mem_resp) $fatal("%0t %s %0d: should not hit", $time, `__FILE__, line);
    repeat (3) @(posedge clk);
    if (~mem_read) $fatal("%0t %s %0d: not reading", $time, `__FILE__, line);
    if (mem_write) $fatal("%0t %s %0d: is writing", $time, `__FILE__, line);
    if ({addr[31:5], 5'b0} != mem_address)  $fatal("%0t %s %0d: mem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr, mem_address);
    repeat (delay) @(posedge clk);
    for (int i = 0; i < 4; ++i) begin
        mem_resp = 1'b1;
        mem_rdata = rdata_feed[64*i + :64];
        @(posedge clk);
    end
    mem_resp = 1'b0;
    @(posedge clk iff data_mem_resp);
    data_mem_read = 1'b0;
    if (rdata_exp != data_mem_rdata)  $fatal("%0t %s %0d: rdata error, exp: %x, actual: %x", $time, `__FILE__, line, rdata_exp, data_mem_rdata);
endtask

task automatic test_readd_hit
(
    rv32i_word addr,
    rv32i_word rdata_exp,
    int line
);
    @(posedge clk);
    data_mem_read = 1'b1;
    data_mem_address = addr;
    @(posedge clk);
    if (~data_mem_resp) $fatal("%0t %s %0d: should hit", $time, `__FILE__, line);
    if (rdata_exp != data_mem_rdata)  $fatal("%0t %s %0d: rdata error, exp: %x, actual: %x", $time, `__FILE__, line, rdata_exp, data_mem_rdata);
    data_mem_read = 1'b0;
endtask

task automatic test_write_miss
(
    rv32i_word addr,
    llc_cacheline rdata_feed,
    rv32i_word wdata_feed,
    logic [3:0] byte_enable,
    int line
);
    @(posedge clk);
    data_mem_write = 1'b1;
    data_mem_wdata = wdata_feed;
    data_mem_address = addr;
    data_mem_byte_enable = byte_enable;
    @(posedge clk);
    if (mem_resp) $fatal("%0t %s %0d: should not hit", $time, `__FILE__, line);
    repeat (3) @(posedge clk);
    if (~mem_read) $fatal("%0t %s %0d: not reading", $time, `__FILE__, line);
    if (mem_write) $fatal("%0t %s %0d: is writing", $time, `__FILE__, line);
    if ({addr[31:5], 5'b0} != mem_address)  $fatal("%0t %s %0d: mem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr, mem_address);
    repeat (delay) @(posedge clk);
    for (int i = 0; i < 4; ++i) begin
        mem_resp = 1'b1;
        mem_rdata = rdata_feed[64*i + :64];
        @(posedge clk);
    end
    mem_resp = 1'b0;
    mem_rdata = {64{1'bX}};
    @(posedge clk iff data_mem_resp);
    data_mem_write = 1'b0;
    data_mem_wdata = {32{1'bX}};
    data_mem_byte_enable = {4{1'bX}};
endtask

task automatic test_write_hit
(
    rv32i_word addr,
    rv32i_word wdata_feed,
    logic [3:0] byte_enable,
    int line
);
    @(posedge clk);
    data_mem_write = 1'b1;
    data_mem_wdata = wdata_feed;
    data_mem_address = addr;
    data_mem_byte_enable = byte_enable;
    @(posedge clk);
    if (~data_mem_resp) $fatal("%0t %s %0d: should hit", $time, `__FILE__, line);
    data_mem_write = 1'b0;
    data_mem_wdata = {32{1'bX}};
    data_mem_byte_enable = {4{1'bX}};
endtask

task automatic test_write_miss_with_wb(
    rv32i_word addr,
    llc_cacheline rdata_feed,
    rv32i_word wdata_feed,
    logic [3:0] byte_enable,
    llc_cacheline expect_wb,
    int line
);
    @(posedge clk);
    data_mem_write = 1'b1;
    data_mem_wdata = wdata_feed;
    data_mem_address = addr;
    data_mem_byte_enable = byte_enable;
    // hit_check_state
    @(posedge clk);
    if (data_mem_resp) $fatal("%0t %s %0d: should not hit", $time, `__FILE__, line);
    // write_back_state
    // TODO: why 3 cycle?
    repeat (3) @(posedge clk);
    if (~mem_write) $fatal("%0t %s %0d: Not writing back to mem", $time, `__FILE__, line);
    if (mem_read) $fatal("%0t %s %0d: Read/write mem at the same time", $time, `__FILE__, line);
    repeat (delay) @(posedge clk);
    for (int i = 0; i < 4; ++i) begin
        mem_resp = 1'b1;
        @(posedge clk);
        wb_wdata[64*i + :64] = mem_wdata;
    end
    mem_resp = 1'b0;
    mem_rdata = {64{1'bX}};
    if (expect_wb != wb_wdata)  $fatal("%0t %s %0d: wb_wdata error, exp: %x, actual: %x", $time, `__FILE__, line, expect_wb, wb_wdata);
    // read_back_state
    // TODO: why 5 cycle?
    repeat (5) @(posedge clk);
    if (~mem_read) $fatal("%0t %s %0d: Not reading from mem", $time, `__FILE__, line);
    if (mem_write) $fatal("%0t %s %0d: Read/write mem at the same time", $time, `__FILE__, line);
    if ({addr[31:5], 5'b0} != mem_address)  $fatal("%0t %s %0d: mem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr, mem_address);
    repeat (delay) @(posedge clk);
    for (int i = 0; i < 4; ++i) begin
        mem_resp = 1'b1;
        mem_rdata = rdata_feed[64*i + :64];
        @(posedge clk);
    end
    mem_resp = 1'b0;
    mem_rdata = {64{1'bX}};
    @(posedge clk iff data_mem_resp);
    data_mem_write = 1'b0;
    data_mem_wdata = {32{1'bX}};
    data_mem_byte_enable = {4{1'bX}};
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;

    inst_mem_read = 1'b0;
    inst_mem_write = 1'b0;
    data_mem_read = 1'b0;
    data_mem_write = 1'b0;

    // ================================ Read Inst Tests ================================
    
    // TEST: sequence 1
    test_readi_miss(
        32'h0000000,
        256'h1111111122222222333333334444444455555555666666667777777788888888,
        32'h88888888,
        `__LINE__
    );

    test_readi_hit(32'h00000000, 32'h88888888, `__LINE__);
    test_readi_hit(32'h00000008, 32'h66666666, `__LINE__);
    test_readi_hit(32'h00000000, 32'h88888888, `__LINE__);
    test_readi_hit(32'h0000001C, 32'h11111111, `__LINE__);

    // TEST: sequence 2, same index
    test_readi_miss(
        32'h1000000C,
        256'h88888888899999999AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFF,
        32'hCCCCCCCC,
        `__LINE__
    );
    test_readi_hit(32'h10000018, 32'h99999999, `__LINE__);

    // TEST: sequence 1 should not lost
    test_readi_hit(32'h0000000C, 32'h55555555, `__LINE__);
    test_readi_hit(32'h00000010, 32'h44444444, `__LINE__);

    // TEST: sequence 3, different index
    test_readi_miss(
        32'h00000080,
        {8{32'hAAAAAAAA}},
        32'hAAAAAAAA,
        `__LINE__
    );

    // TEST: sequence 1 and 2 should not lost
    test_readi_hit(32'h10000000, 32'hFFFFFFFF, `__LINE__);
    test_readi_hit(32'h00000008, 32'h66666666, `__LINE__);

    // TEST: read sequence 4, with the same index as seq 1 and 2. Seq 2 should be replaced
    test_readi_miss(
        32'h80000000,
        {8{32'hFFFFEEEE}},
        32'hFFFFEEEE,
        `__LINE__
    );

    // TEST: seq 1 should not miss
    test_readi_hit(32'h00000000, 32'h88888888, `__LINE__);
    test_readi_hit(32'h0000001C, 32'h11111111, `__LINE__);

    // TEST: seq 2 should miss, seq 4 should be replaced
    test_readi_miss(
        32'h1000000C,
        256'h88888888899999999AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFF,
        32'hCCCCCCCC,
        `__LINE__
    );

    // TEST: seq 4 should miss, seq 1 should be replace
    test_readi_miss(
        32'h80000000,
        {8{32'hFFFFEEEE}},
        32'hFFFFEEEE,
        `__LINE__
    );

    // TEST: seq 3 should be totally unaffected
    test_readi_hit(32'h00000084, 32'hAAAAAAAA, `__LINE__);

    // TEST: seq 1 should miss, seq 2 should be replace
    test_readi_miss(
        32'h00000000,
        256'h1111111122222222333333334444444455555555666666667777777788888888,
        32'h88888888,
        `__LINE__
    );

    // TEST: seq 4 should not miss
    test_readi_hit(32'h8000000C, 32'hFFFFEEEE, `__LINE__);

    // TEST: read seq 5, with the same index as seq 3
    test_readi_miss( 32'h03000080, {8{32'hBBBBBBBB}}, 32'hBBBBBBBB, `__LINE__);

    // TEST: read seq 6, with the same index as seq 3 & 5. Seq 3 should be replaced
    test_readi_miss( 32'h05000080, {8{32'hCCCCCCCC}}, 32'hCCCCCCCC, `__LINE__);

    // TEST: read seq 7, with the same index as seq 6 & 5. Seq 5 should be replaced
    test_readi_miss( 32'h05500080, {8{32'hDDDDDDDD}}, 32'hDDDDDDDD, `__LINE__);

    // TEST: seq 5 should miss. Seq 6 should be replaced
    test_readi_miss( 32'h03000080, {8{32'hBBBBBBBB}}, 32'hBBBBBBBB, `__LINE__);

    // TEST: read a cache line using non-zero offset
    test_readi_miss(
        32'h0011008C,
        {8{32'h11111111}},
        32'h11111111,
        `__LINE__
    );
    test_readi_hit(32'h00110080, 32'h11111111, `__LINE__);

    // ================================ Read Data Tests ================================

    // TEST: sequence 1
    test_readd_miss(
        32'h0000000,
        256'h1111111122222222333333334444444455555555666666667777777788888888,
        32'h88888888,
        `__LINE__
    );

    test_readd_hit(32'h00000000, 32'h88888888, `__LINE__);
    test_readd_hit(32'h00000008, 32'h66666666, `__LINE__);
    test_readd_hit(32'h00000000, 32'h88888888, `__LINE__);
    test_readd_hit(32'h0000001C, 32'h11111111, `__LINE__);

    // TEST: sequence 2, same index
    test_readd_miss(
        32'h1000000C,
        256'h88888888899999999AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFF,
        32'hCCCCCCCC,
        `__LINE__
    );
    test_readd_hit(32'h10000018, 32'h99999999, `__LINE__);

    // TEST: sequence 1 should not lost
    test_readd_hit(32'h0000000C, 32'h55555555, `__LINE__);
    test_readd_hit(32'h00000010, 32'h44444444, `__LINE__);

    // TEST: sequence 3, different index
    test_readd_miss(
        32'h00000080,
        {8{32'hAAAAAAAA}},
        32'hAAAAAAAA,
        `__LINE__
    );

    // TEST: sequence 1 and 2 should not lost
    test_readd_hit(32'h10000000, 32'hFFFFFFFF, `__LINE__);
    test_readd_hit(32'h00000008, 32'h66666666, `__LINE__);

    // TEST: read sequence 4, with the same index as seq 1 and 2. Seq 2 should be replaced
    test_readd_miss(
        32'h80000000,
        {8{32'hFFFFEEEE}},
        32'hFFFFEEEE,
        `__LINE__
    );

    // TEST: seq 1 should not miss
    test_readd_hit(32'h00000000, 32'h88888888, `__LINE__);
    test_readd_hit(32'h0000001C, 32'h11111111, `__LINE__);

    // TEST: seq 2 should miss, seq 4 should be replaced
    test_readd_miss(
        32'h1000000C,
        256'h88888888899999999AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFF,
        32'hCCCCCCCC,
        `__LINE__
    );

    // TEST: seq 4 should miss, seq 1 should be replace
    test_readd_miss(
        32'h80000000,
        {8{32'hFFFFEEEE}},
        32'hFFFFEEEE,
        `__LINE__
    );

    // TEST: seq 3 should be totally unaffected
    test_readd_hit(32'h00000084, 32'hAAAAAAAA, `__LINE__);

    // TEST: seq 1 should miss, seq 2 should be replace
    test_readd_miss(
        32'h00000000,
        256'h1111111122222222333333334444444455555555666666667777777788888888,
        32'h88888888,
        `__LINE__
    );

    // TEST: seq 4 should not miss
    test_readd_hit(32'h8000000C, 32'hFFFFEEEE, `__LINE__);

    // TEST: read seq 5, with the same index as seq 3
    test_readd_miss( 32'h03000080, {8{32'hBBBBBBBB}}, 32'hBBBBBBBB, `__LINE__);

    // TEST: read seq 6, with the same index as seq 3 & 5. Seq 3 should be replaced
    test_readd_miss( 32'h05000080, {8{32'hCCCCCCCC}}, 32'hCCCCCCCC, `__LINE__);

    // TEST: read seq 7, with the same index as seq 6 & 5. Seq 5 should be replaced
    test_readd_miss( 32'h05500080, {8{32'hDDDDDDDD}}, 32'hDDDDDDDD, `__LINE__);

    // TEST: seq 5 should miss. Seq 6 should be replaced
    test_readd_miss( 32'h03000080, {8{32'hBBBBBBBB}}, 32'hBBBBBBBB, `__LINE__);

    // TEST: read a cache line using non-zero offset
    test_readd_miss(
        32'h0011008C,
        {8{32'h11111111}},
        32'h11111111,
        `__LINE__
    );
    test_readd_hit(32'h00110080, 32'h11111111, `__LINE__);

    // ================================ Write Tests ================================
    
    // Load data 1
    test_readd_miss(32'hF0000000, {8{32'hDDDDDDDD}}, 32'hDDDDDDDD, `__LINE__);
    
    // TEST: hit write to offset 0
    test_write_hit(32'hF0000000, 32'hEEEEEEEE, 4'b1111, `__LINE__);

    // TEST: the data gets updated, while the other offset get unaffected
    test_readd_hit(32'hF0000000, 32'hEEEEEEEE, `__LINE__);
    test_readd_hit(32'hF0000004, 32'hDDDDDDDD, `__LINE__);
    test_readd_hit(32'hF0000008, 32'hDDDDDDDD, `__LINE__);
    test_readd_hit(32'hF000000C, 32'hDDDDDDDD, `__LINE__);
    test_readd_hit(32'hF0000010, 32'hDDDDDDDD, `__LINE__);
    test_readd_hit(32'hF0000014, 32'hDDDDDDDD, `__LINE__);
    test_readd_hit(32'hF0000018, 32'hDDDDDDDD, `__LINE__);
    test_readd_hit(32'hF000001C, 32'hDDDDDDDD, `__LINE__);

    // TEST: with bit enabled
    test_write_hit(32'hF0000004, 32'hCCCCCCCC, 4'b0001, `__LINE__);
    test_write_hit(32'hF0000008, 32'hCCCCCCCC, 4'b0010, `__LINE__);
    test_write_hit(32'hF000000C, 32'hCCCCCCCC, 4'b0100, `__LINE__);
    test_write_hit(32'hF0000010, 32'hCCCCCCCC, 4'b1000, `__LINE__);
    test_write_hit(32'hF0000014, 32'hCCCCCCCC, 4'b0011, `__LINE__);
    test_write_hit(32'hF0000018, 32'hCCCCCCCC, 4'b1100, `__LINE__);
    test_write_hit(32'hF000001C, 32'hCCCCCCCC, 4'b1001, `__LINE__);

    test_readd_hit(32'hF0000004, 32'hDDDDDDCC, `__LINE__);
    test_readd_hit(32'hF0000008, 32'hDDDDCCDD, `__LINE__);
    test_readd_hit(32'hF000000C, 32'hDDCCDDDD, `__LINE__);
    test_readd_hit(32'hF0000010, 32'hCCDDDDDD, `__LINE__);
    test_readd_hit(32'hF0000014, 32'hDDDDCCCC, `__LINE__);
    test_readd_hit(32'hF0000018, 32'hCCCCDDDD, `__LINE__);
    test_readd_hit(32'hF000001C, 32'hCCDDDDCC, `__LINE__);

    // TEST: write miss data 2
    test_write_miss(32'hE0000000, {8{32'h00000000}}, 32'h11111111, 4'b0110, `__LINE__);
    test_readd_hit(32'hE0000000, 32'h00111100, `__LINE__);
    test_readd_hit(32'hE000001C, 32'h00000000, `__LINE__);

    // TEST: data 1 should not change
    test_readd_hit(32'hF0000004, 32'hDDDDDDCC, `__LINE__);
    test_readd_hit(32'hF0000008, 32'hDDDDCCDD, `__LINE__);
    test_readd_hit(32'hF000000C, 32'hDDCCDDDD, `__LINE__);
    test_readd_hit(32'hF0000010, 32'hCCDDDDDD, `__LINE__);
    test_readd_hit(32'hF0000014, 32'hDDDDCCCC, `__LINE__);
    test_readd_hit(32'hF0000018, 32'hCCCCDDDD, `__LINE__);
    test_readd_hit(32'hF000001C, 32'hCCDDDDCC, `__LINE__);

    // TEST: write miss data 3, replacing data 2
    test_write_miss_with_wb(
        32'hD0000000, 
        {8{32'h00000000}}, 
        32'h22222222, 4'b1010, 
        {{7{32'h00000000}}, 32'h00111100}, 
        `__LINE__
    );

    // TEST: data 1 should not change
    test_readd_hit(32'hF0000004, 32'hDDDDDDCC, `__LINE__);
    test_readd_hit(32'hF000001C, 32'hCCDDDDCC, `__LINE__);

    // TEST: data 3 should be updated
    test_readd_hit(32'hD0000000, 32'h22002200, `__LINE__);
    test_readd_hit(32'hD0000010, 32'h00000000, `__LINE__);

    // TEST: write miss data 2, replacing data 1
    test_write_miss_with_wb(
        32'hE0000000, 
        {{7{32'h00000000}}, 32'h00111100}, 
        32'h11111111, 4'b1001, 
        256'hCCDDDDCCCCCCDDDDDDDDCCCCCCDDDDDDDDCCDDDDDDDDCCDDDDDDDDCCEEEEEEEE,
        `__LINE__
    );

    // TEST: LRU but not dirty
    test_readd_miss(32'hE00000C0, {8{32'hAAAAAAAA}}, 32'hAAAAAAAA, `__LINE__);
    test_write_miss(32'hD00000C0, {8{32'hBBBBBBBB}}, 32'hBBBBBBBB, 4'b1111, `__LINE__);
    test_readd_miss(32'hC00000C0, {8{32'hCCCCCCCC}}, 32'hCCCCCCCC, `__LINE__);

    $finish;
end

endmodule