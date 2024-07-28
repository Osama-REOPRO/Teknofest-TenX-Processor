module CountPopulation32 (
    input [31:0] data_in,
    output [5:0] pop_count
);
    integer i;
    reg [5:0] count;
    
    always @(*) begin
        count = 0;
        for (i = 0; i < 32; i = i + 1) begin
            count = count + data_in[i];
        end
    end

    assign pop_count = count;
endmodule