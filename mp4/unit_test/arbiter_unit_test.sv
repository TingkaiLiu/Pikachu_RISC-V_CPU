import rv32i_types::*;

module arbiter_unit_test();

timeunit 1ns;
timeprecision 1ns;

bit clk;
always #5 clk = clk === 1'b0;

logic rst;

// I-Cache
logic imem_read;
llc_cacheline imem_rdata;
logic imem_resp;
rv32i_word imem_address;
// D-Cache
logic dmem_read;
logic dmem_write;
llc_cacheline dmem_rdata;
llc_cacheline dmem_wdata;
logic dmem_resp;
rv32i_word dmem_address;
// Memory
logic mmem_read;
logic mmem_write;
llc_cacheline mmem_rdata;
llc_cacheline mmem_wdata;
logic mmem_resp;
rv32i_word mmem_address;

arbiter dut(
    .*
);

task automatic test_read_i
(
    rv32i_word addr_feed,
    llc_cacheline mmem_rdata_feed,
    int line
);
    @(posedge clk);
    imem_address = addr_feed;
    imem_read = 1'b1;
    mmem_resp = 1'b0;
    repeat(2) @(posedge clk);
    if (mmem_address != addr_feed)  $fatal("%0t %s %0d: read i test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr_feed, mmem_address);
    if (~mmem_read) $fatal("%0t %s %0d: read i test: not reading ", $time, `__FILE__, line);
    if (mmem_write) $fatal("%0t %s %0d: read i test: is writing", $time, `__FILE__, line);
    @(posedge clk);
    mmem_rdata = mmem_rdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    mmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff imem_resp);
    imem_read = 1'b0;
    if (imem_rdata != mmem_rdata_feed) $fatal("%0t %s %0d: read i test: imem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, mmem_rdata_feed, imem_rdata);
    @(posedge clk);
endtask

task automatic test_read_d
(
    rv32i_word addr_feed,
    llc_cacheline mmem_rdata_feed,
    int line
);
    @(posedge clk);
    dmem_address = addr_feed;
    dmem_read = 1'b1;
    dmem_write = 1'b0;
    mmem_resp = 1'b0;
    repeat(2) @(posedge clk);
    if (mmem_address != addr_feed)  $fatal("%0t %s %0d: read d test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr_feed, mmem_address);
    if (~mmem_read) $fatal("%0t %s %0d: read d test: not reading ", $time, `__FILE__, line);
    if (mmem_write) $fatal("%0t %s %0d: read d test: is writing", $time, `__FILE__, line);
    @(posedge clk);
    mmem_rdata = mmem_rdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    mmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff dmem_resp);
    dmem_read = 1'b0;
    if (dmem_rdata != mmem_rdata_feed) $fatal("%0t %s %0d: read d test: imem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, mmem_rdata_feed, dmem_rdata);
    @(posedge clk);
endtask

task automatic test_write_d
(
    rv32i_word addr_feed,
    llc_cacheline dmem_wdata_feed,
    int line
);
    @(posedge clk);
    dmem_address = addr_feed;
    dmem_read = 1'b0;
    dmem_write = 1'b1;
    mmem_resp = 1'b0;
    repeat(2) @(posedge clk);
    if (mmem_address != addr_feed)  $fatal("%0t %s %0d: write d test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, addr_feed, mmem_address);
    if (mmem_read) $fatal("%0t %s %0d: write d test: is reading ", $time, `__FILE__, line);
    if (~mmem_write) $fatal("%0t %s %0d: write d test: not writing", $time, `__FILE__, line);
    @(posedge clk);
    dmem_wdata = dmem_wdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    dmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff dmem_resp);
    dmem_write = 1'b0;
    if (mmem_wdata != dmem_wdata_feed) $fatal("%0t %s %0d: read d test: imem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, dmem_wdata_feed, mmem_wdata);
    @(posedge clk);
endtask

task automatic test_read_i_read_d
(
    rv32i_word i_addr_feed,
    llc_cacheline i_mmem_rdata_feed,
    rv32i_word d_addr_feed,
    llc_cacheline d_mmem_rdata_feed,
    int line
);
    @(posedge clk);
    imem_address = i_addr_feed;
    dmem_address = d_addr_feed;
    imem_read = 1'b1;
    dmem_read = 1'b1;
    dmem_write = 1'b0;
    mmem_resp = 1'b0;
    repeat(2) @(posedge clk);
    if (mmem_address != i_addr_feed)  $fatal("%0t %s %0d: read i read d test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, i_addr_feed, mmem_address);
    if (~mmem_read) $fatal("%0t %s %0d: read i read d test: not reading ", $time, `__FILE__, line);
    if (mmem_write) $fatal("%0t %s %0d: read i read d test: is writing", $time, `__FILE__, line);
    @(posedge clk);
    mmem_rdata = i_mmem_rdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    mmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff imem_resp);
    imem_read = 1'b0;
    if (imem_rdata != i_mmem_rdata_feed) $fatal("%0t %s %0d: read i test: imem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, i_mmem_rdata_feed, imem_rdata);
    
    repeat(2) @(posedge clk);
    if (mmem_address != d_addr_feed)  $fatal("%0t %s %0d: read i read d test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, d_addr_feed, mmem_address);
    if (~mmem_read) $fatal("%0t %s %0d: read i read d test: not reading ", $time, `__FILE__, line);
    if (mmem_write) $fatal("%0t %s %0d: read i read d test: is writing", $time, `__FILE__, line);
    @(posedge clk);
    mmem_rdata = d_mmem_rdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    mmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff dmem_resp);
    dmem_read = 1'b0;
    if (dmem_rdata != d_mmem_rdata_feed) $fatal("%0t %s %0d: read i test: dmem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, d_mmem_rdata_feed, dmem_rdata);
    
endtask

task automatic test_read_i_write_d
(
    rv32i_word i_addr_feed,
    llc_cacheline mmem_rdata_feed,
    rv32i_word d_addr_feed,
    llc_cacheline dmem_wdata_feed,
    int line
);
    @(posedge clk);
    imem_address = i_addr_feed;
    dmem_address = d_addr_feed;
    imem_read = 1'b1;
    dmem_read = 1'b0;
    dmem_write = 1'b1;
    mmem_resp = 1'b0;
    repeat(2) @(posedge clk);
    if (mmem_address != i_addr_feed)  $fatal("%0t %s %0d: read i write d test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, i_addr_feed, mmem_address);
    if (~mmem_read) $fatal("%0t %s %0d: read i write d test: not reading ", $time, `__FILE__, line);
    if (mmem_write) $fatal("%0t %s %0d: read i write d test: is writing", $time, `__FILE__, line);
    @(posedge clk);
    mmem_rdata = mmem_rdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    mmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff imem_resp);
    imem_read = 1'b0;
    if (imem_rdata != mmem_rdata_feed) $fatal("%0t %s %0d: read i test: imem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, mmem_rdata_feed, imem_rdata);
    
    repeat(2) @(posedge clk);
    if (mmem_address != d_addr_feed)  $fatal("%0t %s %0d: read i write d test: mmem_address error, exp: %x, actual: %x", $time, `__FILE__, line, d_addr_feed, mmem_address);
    if (mmem_read) $fatal("%0t %s %0d: read i write d test: is reading ", $time, `__FILE__, line);
    if (~mmem_write) $fatal("%0t %s %0d: read i write d test: not writing", $time, `__FILE__, line);
    @(posedge clk);
    dmem_wdata = dmem_wdata_feed;
    mmem_resp = 1'b1;
    @(posedge clk);
    dmem_rdata = {256{1'bX}};
    mmem_resp = 1'b0;
    @(posedge clk iff dmem_resp);
    dmem_write = 1'b0;
    if (mmem_wdata != dmem_wdata_feed) $fatal("%0t %s %0d: read d test: imem_rdata error, exp: %x, actual: %x", $time, `__FILE__, line, dmem_wdata_feed, mmem_wdata);
    @(posedge clk);
    
endtask

initial begin
    
    rst = 1'b1;
    repeat (5) @(posedge clk);
    rst = 1'b0;
    
    // TEST: test read i
    test_read_i(
        32'h11112222,
        256'h3333444433334444333344443333444433334444333344443333444433334444,
        `__LINE__
    );
    // TEST: test read d
    test_read_d(
        32'h11112222,
        256'h3333444433334444333344443333444433334444333344443333444433334444,
        `__LINE__
    );
    // TEST: test write d
    test_write_d(
        32'h1111222211112222,
        256'h3333444433334444333344443333444433334444333344443333444433334444,
        `__LINE__
    );
    // TEST: test read i read d
    test_read_i_read_d(
        32'h1111222211112222,
        256'h5555666633334444555566665555666655556666333344443333444433334444,
        32'h1111222211112222,
        256'h3333444455556666555566665555666655556666555566665555666633334444,
        `__LINE__
    );
    // TEST: test read i write d
    test_read_i_write_d(
        32'h1111222211112222,
        256'h3333444433334444555566665555666655556666555566663333444433334444,
        32'h1111222211112222,
        256'h5555666655556666555566665555666655556666333344443333444433334444,
        `__LINE__
    );
    $finish;
end

endmodule