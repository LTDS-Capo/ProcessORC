module WritebackMux #(
    parameter DATABITWIDTH = 16
)(
    input                     RegAWriteEn,
    input               [1:0] WritebackSource,

    input  [DATABITWIDTH-1:0] ALU0ResultIn,
    input  [DATABITWIDTH-1:0] ALU1ResultIn,
    input  [DATABITWIDTH-1:0] JumpAndLinkResultIn,

    output [DATABITWIDTH-1:0] WritebackResultOut,
    output                    RegisterWriteEn
);
    
    logic [DATABITWIDTH:0] Result_tmp;
    always_comb begin : ResultMux
        case (WritebackSource)
            2'b01  : Result_tmp = ALU1ResultIn;
            2'b10  : Result_tmp = JumpAndLinkResultIn;
            2'b11  : Result_tmp = '0;
            default: Result_tmp = ALU0ResultIn; // Default is also case 0
        endcase
    end
    
    assign WritebackResultOut = Result_tmp;
    assign RegisterWriteEn = RegAWriteEn;

endmodule