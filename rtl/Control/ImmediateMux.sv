module ImmediateMux #(
    parameter DATABITWIDTH = 16
)(
    input                     ImmediateEn,
    input                     UpperImmediateEn,
 
    input  [DATABITWIDTH-1:0] BDataIn,
    input  [DATABITWIDTH-1:0] ImmediateIn, 

    output [DATABITWIDTH-1:0] BDataOut
);
    
    wire [DATABITWIDTH-1:0] UpperImmediateResult = {ImmediateIn[DATABITWIDTH-1:(DATABITWIDTH/2)], BDataIn[(DATABITWIDTH/2)-1:0]};

    logic [DATABITWIDTH-1:0] NextBDataOut;
    wire  [1:0] NextBDataOutCondition;
    assign NextBDataOutCondition[0] = ImmediateEn;
    assign NextBDataOutCondition[1] = UpperImmediateEn;
    always_comb begin : NextBMux
        case (NextBDataOutCondition)
            2'b01  : NextBDataOut = ImmediateIn;
            2'b11  : NextBDataOut = UpperImmediateResult;
            default: NextBDataOut = BDataIn; // Default is also case 0
        endcase
    end
    assign BDataOut = NextBDataOut;
    
endmodule