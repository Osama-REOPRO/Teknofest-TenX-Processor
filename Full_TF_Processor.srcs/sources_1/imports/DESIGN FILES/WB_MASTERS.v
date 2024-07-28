module WB_MASTER_SINGLE( // single read/write cycles
    input            CLK_I,
    input            RST_I,
    output reg       CYC_O,
    output reg       STB_O,
    output reg       WE_O,
    input      [7:0] ADR_I,
    output reg [7:0] ADR_O,
    input      [7:0] DAT_I,
    output reg [7:0] DAT_O,
    input            ACK_I
    );
    reg [7:0] i;
    parameter message_len = 15;
    reg [7:0] message [0:message_len];
    initial $readmemh("wb_message_0.mem", message);
    
    always @ (posedge CLK_I) begin
        if(RST_I)begin
            {STB_O, CYC_O, i} = 0;
        end else begin
            if(i < message_len && !CYC_O) begin
                ADR_O = i;
                DAT_O = message[i];
                WE_O = 1;
                CYC_O = 1;
                STB_O = 1;
            end else if (CYC_O && ACK_I) begin
                STB_O = 0;
                CYC_O = 0;
                i = i+1;
            end
        end
    end
    
endmodule

module WB_MASTER_RMW( // read-modify-write cycles
    input            CLK_I,
    input            RST_I,
    output reg       CYC_O,
    output reg       STB_O,
    output reg       WE_O,
    output reg [7:0] ADR_O,
    input      [7:0] DAT_I,
    output reg [7:0] DAT_O,
    input            ACK_I
    );
    reg [7:0] i;
    parameter message_len = 15;
    reg [7:0] message [0:message_len];
    initial begin
        for(i=0; i<=message_len; i=i+1)begin
            message[i] = 0;
        end
        i = 0;
//        $readmemh("wb_message_0.mem", message);
    end
    
    always @ (posedge CLK_I) begin
        if(RST_I)begin
            {STB_O, CYC_O, i, WE_O, ADR_O, DAT_O} = 0;
        end else begin
            if (i < message_len) begin
                if (!CYC_O) begin
                    // read half
                    WE_O = 0;
                    ADR_O = i;
                    CYC_O = 1;
                    STB_O = 1;
                end else if (STB_O && !WE_O && ACK_I) begin
                    message[i] = DAT_I;
                    STB_O = 0;
                end else if (!STB_O && !WE_O && !ACK_I) begin
                    // write half
                    DAT_O = message[i];
                    WE_O = 1;
                    STB_O = 1;
                end else if (STB_O && WE_O && ACK_I) begin
                    CYC_O = 0;
                    STB_O = 0;
                    WE_O = 0;
                    i = i+1;
                end
            end
        end
    end
    
endmodule