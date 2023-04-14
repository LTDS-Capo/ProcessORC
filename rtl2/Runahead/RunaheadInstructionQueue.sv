module RunaheadInstructionQueue #(
    parameter RUNAHEADDEPTH = 32,
    parameter STACKTAGWIDTH = 4,
    parameter CLEARQUEUEQDEPTH = 8
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                      Stalled, //! Think through when this would be used
    output                     RunaheadFIFOFullStall,
    output                     ClearQueueFIFOFullStall,

    // Instruction Input
    input                      FetchedInstructionValid,
    input  [STACKTAGWIDTH-1:0] FetchedStackTag,
    input               [15:0] FetchedInstruction,

    // Register Status
    input               [15:0] DirtyVector,

    // Speculation Interface
    input                      Speculating,
    input                      EndSpeculationPulse,
    input                      MispredictedSpeculationPulse,

    // Instruction Output
    output                     RunaheadInstructionValid,
    output [STACKTAGWIDTH-1:0] RunaheadStackTag,
    output              [15:0] RunaheadInstruction
);

    //! When to forward Instruction into Runahead Queue: DirtyBForward || DirtyAForward || ADirty || BDirty || (AToBeRead != 0)
    //* When to Issue from Runahead Queue: ~ADirty && ~BDirty
    //! When to Stall: AToBeWritten || BToBeWritten
    //! When to Un-Stall: ~AToBeWritten && ~BToBeWritten
    //! Else; Issue Instruction

    //? Speculative Clear Control
        localparam COUNTERBITWIDTH = (RUNAHEADDEPTH == 1) ? 2 : $clog2(RUNAHEADDEPTH+1);
        wire                       MispredictionQueueACK = SpeculativeHeadOfRunahead && ClearQueueMisprediction;
        wire                       ClearQueueValid;
        wire                       ClearQueueMisprediction;
        wire [COUNTERBITWIDTH-1:0] ClearQueueSpeculativeDepth;
        RunaheadSpeculativeClearQueue #(
            .COUNTERBITWIDTH(COUNTERBITWIDTH),
            .QUEUEDEPTH     (CLEARQUEUEQDEPTH)
        ) ClearQueue (
            .clk                         (clk),
            .clk_en                      (clk_en),
            .sync_rst                    (sync_rst),
            .FetchedInstructionValid     (FetchedInstructionValid),
            .ClearQueueFull              (ClearQueueFIFOFullStall),
            .Speculating                 (Speculating),
            .EndSpeculationPulse         (EndSpeculationPulse),
            .MispredictedSpeculationPulse(MispredictedSpeculationPulse),
            .SpeculativeHeadOfRunahead   (SpeculativeHeadOfRunahead),
            .RunaheadInstrucionValid     (RunaheadInstructionValid),
            .MispredictionQueueACK       (MispredictionQueueACK),
            .ClearQueueValid             (ClearQueueValid),
            .ClearQueueMisprediction     (ClearQueueMisprediction),
            .ClearQueueSpeculativeDepth  (ClearQueueSpeculativeDepth)
        );
    //

    //? Runahead Queue
        //! Entry:
        // {Speculative, StackTag, Instruction}
            //* Stack Tag
            // 4bit Tag for operations that Push to the Stack cache
            //* Speculative Bit:
            // Append a bit when speculating and pushing an instruction to the runahead queue.
            wire                    RunaheadQueueNotFull;
            wire [FIFOBITWIDTH-1:0] RunaheadQueueInput = {Speculating, FetchedStackTag, FetchedInstruction};
            wire                    RunaheadQueueOutputValid;
            wire                    RunaheadClear = sync_rst || (~ClearQueueValid && MispredictedSpeculationPulse && SpeculativeHeadOfRunahead && RunaheadQueueOutputValid);
            wire [FIFOBITWIDTH-1:0] RunaheadQueueOutput;
        localparam FIFOBITWIDTH = 1 + STACKTAGWIDTH + 16;
        BufferedFIFO #(
            .DATABITWIDTH(FIFOBITWIDTH),
            .FIFODEPTH   (RUNAHEADDEPTH)
        ) RunaheadQueue (
            .clk           (clk),
            .clk_en        (clk_en),
            .sync_rst      (RunaheadClear),
            .InputREQ      (FetchedInstructionValid),
            .InputACK      (RunaheadQueueNotFull),
            .InputData     (RunaheadQueueInput),
            .OutputREQ     (RunaheadQueueOutputValid),
            .OutputACK     (RunaheadInstructionACK),
            .FIFOTailOffset(ClearQueueSpeculativeDepth),
            .OutputData    (RunaheadQueueOutput)
        );
        assign RunaheadFIFOFullStall = ~RunaheadQueueNotFull;
        wire   RunaheadInstructionACK = (AOperandClear && BOperandClear && ~Stalled && ~ClearQueueMisprediction) || (ClearQueueMisprediction);
        assign RunaheadInstructionValid = RunaheadQueueOutputValid && AOperandClear && BOperandClear && ~Stalled && ~ClearQueueMisprediction;
        wire   SpeculativeHeadOfRunahead = RunaheadQueueOutput[FIFOBITWIDTH-1];
        assign RunaheadStackTag = RunaheadQueueOutput[FIFOBITWIDTH-2:16];
        assign RunaheadInstruction = RunaheadQueueOutput[15:0];
    //

    //? Operand Validation
        //* A Operand Check
            wire [3:0] AOperand = RunaheadInstruction[11:8];
            wire       AOperandClear = ~DirtyVector[AOperand];
        //* B Operand Check
            wire [3:0] BOperand = RunaheadInstruction[3:0];
            wire       BOperandClear = ~DirtyVector[BOperand];
    //

endmodule : RunaheadInstructionQueue