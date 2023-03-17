module ProgramCounter #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                     ProgramCounterEnable,
    input                     StallEnable,
    input                     BranchEnable,
    input                     RelativeBranchEnable,
    input                     Speculating,
    input                     PredictingTrue,
    input  [DATABITWIDTH-1:0] SpeculativeDestination,
    input  [DATABITWIDTH-1:0] OperandAData,
    input  [DATABITWIDTH-1:0] OperandBData,

    // TODO: Priv Jumps & Speculation
    input                     BeginSpeculationPulse,
    output                    IncorrectSpeculation,

    input  [DATABITWIDTH-1:0] ECallDestination,
    input  [DATABITWIDTH-1:0] EBreakDestination,
    input  [DATABITWIDTH-1:0] XReturnDestination,
    
    input  [DATABITWIDTH-1:0] ImmediateData,
    input               [3:0] MinorOpcode,

    output [DATABITWIDTH-1:0] ProgramCounterValue,
    output [DATABITWIDTH-1:0] JumpAndLinkDataOut

);
    // If Speculating && BranchEn
    // > Correct: If Predicted Destination AND Taken/NotTaken properly
    // - Predicted Taken & Correct & Good Address: Do Nothing
    // - Predicted Taken & Correct & Bad Address:  Pulse IncorrectSpeculation, Let PC Update as normal
    // - Predicted Taken & Incorrect:              Pulse IncorrectSpeculation, Roll PC back to Speculation Roll-Back
    // - Predicted Not Taken & Correct:            Do Nothing
    // - Predicted Not Taken & Incorrect:          Pulse IncorrectSpeculation, Let PC Update as normal

    // Speculation Roll-Back Buffer 
        reg  [DATABITWIDTH-1:0] SpeculationRollbackAddress;
        wire SpeculationRollbackAddressTrigger = sync_rst || (clk_en && BeginSpeculationPulse);
        always_ff @(posedge clk) begin
            if (SpeculationRollbackAddressTrigger) begin
                SpeculationRollbackAddress <= ProgramCounter + 1;
            end
        end
    // 

    // Program Counter
        reg  [DATABITWIDTH-1:0] ProgramCounter;
        wire                    AEqualsZero = OperandAData == 0;
        wire              [6:0] BranchOffsetLower = {MinorOpcode, 3'b000}
        wire [DATABITWIDTH-7:0] BranchOffsetUpper = 0
        wire [DATABITWIDTH-1:0] BranchOffset = {BranchOffsetUpper, BranchOffsetLower};

        logic  [DATABITWIDTH-1:0] NextProgramCounter;
        wire                [1:0] NextProgramCounterCondition;
        assign                    NextProgramCounterCondition[0] = AEqualsZero && BranchEnable && ~sync_rst;
        assign                    NextProgramCounterCondition[1] = (AEqualsZero && RelativeBranchEnable) || sync_rst;
        always_comb begin : NextProgramCounterMux
            case (NextProgramCounterCondition)
                2'b00  : NextProgramCounter = ProgramCounter + 1; // Standard PC
                2'b01  : NextProgramCounter = ImmediateData;
                2'b10  : NextProgramCounter = 0; // sync_rst
                2'b11  : NextProgramCounter = OperandAData + BranchOffset;
                default: NextProgramCounter = 0;
            endcase
        end

        wire ProgramCounterTrigger = sync_rst || (clk_en && ~StallEnable && ProgramCounterEnable);
        always_ff @(posedge clk) begin
            if (ProgramCounterTrigger) begin
                ProgramCounter <= NextProgramCounter;
            end
        end
        assign ProgramCounterValue = ProgramCounter;
        assign JumpAndLinkDataOut = ProgramCounter - 5;
    //

endmodule : ProgramCounter