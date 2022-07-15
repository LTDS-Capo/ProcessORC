module WritebackMux #(
    parameter DATABITWIDTH = 16,
    parameter REGADDRBITWIDTH = 4
)(
    input                        RegAWriteEn,
    input  [REGADDRBITWIDTH-1:0] RegWriteAddr,
    input                  [1:0] WritebackSource,

    input     [DATABITWIDTH-1:0] JumpAndLinkResultIn,
    input     [DATABITWIDTH-1:0] ALU0ResultIn,
    input     [DATABITWIDTH-1:0] ALU1ResultIn,

    output    [DATABITWIDTH-1:0] WritebackResultOut,
    output [REGADDRBITWIDTH-1:0] WritebackRegAddr,
    output                       RegisterWriteEn
);
    
    logic  [DATABITWIDTH:0] Result_tmp;
    wire              [1:0] WritebackSourceCond;
    assign                  WritebackSourceCond[0] = WritebackSource[0];
    assign                  WritebackSourceCond[1] = WritebackSource[1];
    always_comb begin : ResultMux
        case (WritebackSourceCond)
            2'b01  : Result_tmp = JumpAndLinkResultIn;
            2'b10  : Result_tmp = ALU0ResultIn;
            2'b11  : Result_tmp = ALU1ResultIn;
            default: Result_tmp = '0; // Default is also case 0
        endcase
    end
    
    assign WritebackResultOut = Result_tmp;
    assign WritebackRegAddr = RegWriteAddr;
    assign RegisterWriteEn = RegAWriteEn;

endmodule