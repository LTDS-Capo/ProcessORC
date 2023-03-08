module ForwardingMux #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  [DATABITWIDTH-1:0] OperandADataIn,
    input                     Forward0ToA,
    input                     Forward1ToA,
    input                     ForwardLoadToA,

    input  [DATABITWIDTH-1:0] OperandBDataIn,
    input                     Forward0ToB,
    input                     Forward1ToB,
    input                     ForwardLoadToB,

    input  [DATABITWIDTH-1:0] WritebackResult,
    input  [DATABITWIDTH-1:0] LoadResult,

    output [DATABITWIDTH-1:0] OperandADataOut,
    output [DATABITWIDTH-1:0] OperandADataOut
);

    // Writeback History
        reg  [DATABITWIDTH-1:0] WritebackHistory;
        wire [DATABITWIDTH-1:0] NextWritebackHistory = sync_rst ? 0 : WritebackResult;
        wire WritebackHistoryTrigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (WritebackHistoryTrigger) begin
                WritebackHistory <= NextWritebackHistory;
            end
        end
    //

    // Operand A Forwarding Mux
        logic  [DATABITWIDTH-1:0] TempOperandAData;
        wire   [1:0] TempOperandADataCondition;
        assign       TempOperandADataCondition[0] = Forward0ToA || ForwardLoadToA;
        assign       TempOperandADataCondition[1] = Forward1ToA || ForwardLoadToA;
        always_comb begin : TempOperandADataMux
            case (TempOperandADataCondition)
                2'b00  : TempOperandAData = OperandADataIn;
                2'b01  : TempOperandAData = WritebackResult;
                2'b10  : TempOperandAData = WritebackHistory;
                2'b11  : TempOperandAData = LoadResult;
                default: TempOperandAData = 0;
            endcase
        end
        assign OperandADataOut = TempOperandAData;
    //
    
    // Operand B Forwarding Mux
        logic  [DATABITWIDTH-1:0] TempOperandBData;
        wire   [1:0] TempOperandBDataCondition;
        assign       TempOperandBDataCondition[0] = Forward0ToB || ForwardLoadToB;
        assign       TempOperandBDataCondition[1] = Forward1ToB || ForwardLoadToB;
        always_comb begin : TempOperandBDataMux
            case (TempOperandBDataCondition)
                2'b00  : TempOperandBData = OperandBDataIn;
                2'b01  : TempOperandBData = WritebackResult;
                2'b10  : TempOperandBData = WritebackHistory;
                2'b11  : TempOperandBData = LoadResult;
                default: TempOperandBData = 0;
            endcase
        end
        assign OperandBDataOut = TempOperandBData;
    //

endmodule : ForwardingMux