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
    input  [DATABITWIDTH-1:0] OperandAData,
    input  [DATABITWIDTH-1:0] OperandBData,

    // TODO: Priv Jumps
    // ECall, EBreak, XReturn
    input  [DATABITWIDTH-1:0] CSRDestination,

    input                     Speculating,
    input                     BeginSpeculationPulse,
    input                     RelativeSpeculation, // TODO
    input                     PredictingTrue,
    input  [DATABITWIDTH-1:0] SpeculativeDestination,
    output                    MispredictedSpeculationPulse,
    output                    EndSpeculationPulse,


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
    // - Predicted Taken & Correct & Good Address: Ignore Branch
    // - Predicted Taken & Correct & Bad Address:  Pulse MispredictedSpeculationPulse, Let PC Update as normal
    // - Predicted Taken & Incorrect:              Pulse MispredictedSpeculationPulse, Roll PC back to Speculation Roll-Back
    // - Predicted Not Taken & Correct:            Do Nothing
    // - Predicted Not Taken & Incorrect:          Pulse MispredictedSpeculationPulse, Let PC Update as normal

    // Destination Check Buffer
        reg  [DATABITWIDTH:0] SpeculationResultBuffer;
        wire [DATABITWIDTH:0] NextSpeculationResultBuffer = {(PredictingTrue && ~sync_rst), NextProgramCounter};
        wire SpeculationResultBufferTrigger = sync_rst || (clk_en && ~StallEnable && BeginSpeculationPulse);
        always_ff @(posedge clk) begin
            if (SpeculationResultBufferTrigger) begin
                SpeculationResultBuffer <= NextSpeculationResultBuffer;
            end
        end
        wire   [DATABITWIDTH-1:0] SpeculativeBranchToImmediateDestination = SpeculationRollbackAddress + ImmediateData;
        wire   [DATABITWIDTH-1:0] TruePCDestination = RelativeBranchEnable ? SpeculativeBranchToImmediateDestination : BranchToOffsetRegisterDestination;
        wire                      DestinationMismatch = SpeculationResultBuffer[DATABITWIDTH-1:0] != TruePCDestination;
        assign                    MispredictedSpeculationPulse = (DestinationMismatch && BranchEnable && SpeculationResultBuffer[DATABITWIDTH]) || ((SpeculationResultBuffer[DATABITWIDTH] ^ AEqualsZero) && Speculating && BranchEnable);
    //

    // Speculation Roll-Back Buffer
        reg  [DATABITWIDTH-1:0] SpeculationRollbackAddress;
        wire SpeculationRollbackAddressTrigger = sync_rst || (clk_en && ~StallEnable && BeginSpeculationPulse);
        always_ff @(posedge clk) begin
            if (SpeculationRollbackAddressTrigger) begin
                SpeculationRollbackAddress <= ProgramCounter + 1;
            end
        end
    //

    // Program Counter
        reg    [DATABITWIDTH-1:0] ProgramCounter;
        
        wire                      AEqualsZero = OperandAData == 0;
        wire                [6:0] BranchOffsetLower = {MinorOpcode, 3'b000};
        wire   [DATABITWIDTH-7:0] BranchOffsetUpper = 0;
        wire   [DATABITWIDTH-1:0] BranchOffset = {BranchOffsetUpper, BranchOffsetLower};
        wire                      MispredicatedTaken = SpeculationResultBuffer[DATABITWIDTH] && ~AEqualsZero && Speculating;
        wire                      PredictionTaken = SpeculationResultBuffer[DATABITWIDTH] && Speculating;
        wire   [DATABITWIDTH-1:0] BranchToOffsetRegisterDestination = OperandAData + BranchOffset;

        logic  [DATABITWIDTH-1:0] NextProgramCounter;
        wire                [2:0] NextProgramCounterCondition;
        assign                    NextProgramCounterCondition[0] = (AEqualsZero && RelativeBranchEnable && BranchEnable && ~PredictionTaken) || (MispredicatedTaken && BranchEnable) || (BeginSpeculationPulse && PredictingTrue && SpeculativeDestination) || sync_rst;
        assign                    NextProgramCounterCondition[1] = (AEqualsZero && BranchEnable && ~MispredicatedTaken && ~PredictionTaken && ~sync_rst) || (BeginSpeculationPulse && PredictingTrue && ~sync_rst);
        assign                    NextProgramCounterCondition[2] = (BeginSpeculationPulse && PredictingTrue && ~BranchEnable && ~sync_rst) || (MispredicatedTaken && BranchEnable && ~sync_rst);
        always_comb begin : NextProgramCounterMux
            case (NextProgramCounterCondition)
                3'b000 : NextProgramCounter = ProgramCounter + 1; // Standard PC + 1
                3'b001 : NextProgramCounter = 0; // sync_rst
                3'b010 : NextProgramCounter = BranchToOffsetRegisterDestination; // A + Offset
                3'b011 : NextProgramCounter = ProgramCounter + ImmediateData; // PC + Signed Imm //TODO: If Speculative, add to the Rollback Value
                3'b100 : NextProgramCounter = 0; //! ERROR
                3'b101 : NextProgramCounter = SpeculationRollbackAddress;
                3'b110 : NextProgramCounter = SpeculativeDestination;
                3'b111 : NextProgramCounter = ProgramCounter + SpeculativeDestination;
                default: NextProgramCounter = 0;
            endcase
        end
        wire ProgramCounterTrigger = sync_rst || (clk_en && ~StallEnable && ProgramCounterEnable) || (clk_en && BeginSpeculationPulse && PredictingTrue);
        always_ff @(posedge clk) begin
            if (ProgramCounterTrigger) begin
                ProgramCounter <= NextProgramCounter;
            end
        end
        assign ProgramCounterValue = ProgramCounter;
        assign JumpAndLinkDataOut = SpeculationRollbackAddress;
        assign EndSpeculationPulse = Speculating && BranchEnable && ~StallEnable;
    //

endmodule : ProgramCounter