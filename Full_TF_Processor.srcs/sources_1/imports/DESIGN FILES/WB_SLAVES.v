module WB_SLAVE_SINGLE(
    input            CLK_I,
    input            RST_I,
    input            CYC_I,
    input            STB_I,
    input            WE_I,
    input      [7:0] ADR_I,
    input      [7:0] DAT_I,
    output reg [7:0] DAT_O,
    output reg       ACK_O,
    output reg       ERR_O,
    output reg       RTY_O,
    output reg       STALL_O
    );
    reg [7:0] i;
    parameter message_len = 15;
    reg [7:0] message [0:message_len];
    
    always @(posedge CLK_I) begin
        if(RST_I)begin
            {DAT_O, ACK_O, ERR_O, RTY_O, STALL_O} = 0;
            for(i=0; i<=message_len; i=i+1)begin
                message[i] = 0;
            end
        end else begin
            if(CYC_I && STB_I && WE_I)begin
                message[ADR_I] = DAT_I;
                ACK_O = 1;
            end else begin
                ACK_O = 0;
            end
        end
    end
endmodule

module WB_SLAVE_RMW(
    input            CLK_I,
    input            RST_I,
    input            CYC_I,
    input            STB_I,
    input            WE_I,
    input      [7:0] ADR_I,
    input      [7:0] DAT_I,
    output reg [7:0] DAT_O,
    output reg       ACK_O
    );
    reg [7:0] i;
    parameter message_len = 15;
    reg [7:0] message1 [0:message_len];
    reg [7:0] message2 [0:message_len];
    
    initial begin
        for(i=0; i<=message_len; i=i+1)begin
            message1[i] = 0;
            message2[i] = 0;
        end
        i = 0;
        $readmemh("wb_message_0.mem", message1);
    end
    
    always @(posedge CLK_I) begin
        if(RST_I)begin
            {DAT_O, ACK_O} = 0;
            for(i=0; i<=message_len; i=i+1)begin
                message2[i] = 0;
            end
        end else begin
            if(CYC_I && STB_I && !WE_I)begin
                // read half
                DAT_O = message1[ADR_I];
                ACK_O = 1;
            end else if(CYC_I && STB_I && WE_I)begin
                // write half
                message2[ADR_I] = DAT_I;
                ACK_O = 1;
            end else begin
                ACK_O = 0;
            end
        end
    end
endmodule