module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

enum logic [8:0] {Wait, Finish_Read, Finish_Write, Read_0, Read_1, Read_2, Read_3, Write_0, Write_1, Write_2, Write_3} state, next_state;

logic [255:0] line_o_next;
logic [31:0] address_o_next;

always_ff @(posedge clk)
begin
    if (reset_n == 0)
    begin
        state <= Wait;
        line_o <= 256'b0;
        address_o <= 32'b0;
    end
    else
    begin
        state <= next_state;
        line_o <= line_o_next;
        address_o <= address_o_next;
    end
end

always_comb
begin
    next_state = state;

    case (state)
        Wait:
        begin
            if (read_i == 0 && write_i == 0)
                next_state = Wait;
            else if (read_i == 1)
                next_state = Read_0;
            else if (write_i == 1)
                next_state = Write_0;
        end
        Read_0:
            if (resp_i == 1)
                next_state = Read_1;
            else
                next_state = Read_0;
        Read_1:
            if (resp_i == 1)
                next_state = Read_2;
            else
                next_state = Read_1;
        Read_2:
            if (resp_i == 1)
                next_state = Read_3;
            else
                next_state = Read_2;
        Read_3:
            if (resp_i == 1)
                next_state = Finish_Read;
            else
                next_state = Read_3;
        
        Write_0:
            if (resp_i == 1)
                next_state = Write_1;
            else
                next_state = Write_0;
        Write_1:
            if (resp_i == 1)
                next_state = Write_2;
            else
                next_state = Write_1;
        Write_2:
            if (resp_i == 1)
                next_state = Write_3;
            else
                next_state = Write_2;
        Write_3:
            if (resp_i == 1)
                next_state = Finish_Write;
            else
                next_state = Write_3;

        Finish_Read:  next_state = Wait;
        Finish_Write: next_state = Wait;
        
        default: ;
    endcase

end

always_comb
begin
    read_o = 0;
    write_o = 0;
    resp_o = 0;
	address_o_next = address_i;
    line_o_next = line_o;
    burst_o = 64'b0;
    case (state)
        Read_0:
        begin
            read_o = 1'b1;
            address_o_next = address_i;
            line_o_next[63:0] = burst_i;
        end
        Read_1:
        begin
            read_o = 1'b1;
            address_o_next = address_i;
            line_o_next[127:64] = burst_i;
        end
        Read_2:
        begin
            read_o = 1'b1;
            address_o_next = address_i;
            line_o_next[191:128] = burst_i;
        end
        Read_3:
        begin 
            read_o = 1'b1;
            address_o_next = address_i;
            line_o_next[255:192] = burst_i;
        end

        Write_0:
        begin
            write_o = 1'b1;
            address_o_next = address_i;
            burst_o = line_i[63:0];
        end
        Write_1:
        begin
            write_o = 1'b1;
            address_o_next = address_i;
            burst_o = line_i[127:64];
        end
        Write_2:
        begin
            write_o = 1'b1;
            address_o_next = address_i;
            burst_o = line_i[191:128];
        end
        Write_3:
        begin
            write_o = 1'b1;
            address_o_next = address_i;
            burst_o = line_i[255:192];
        end

        Finish_Read:
            resp_o = 1'b1;
        Finish_Write:
            resp_o = 1'b1;

        default: ;
    endcase
end

endmodule : cacheline_adaptor
