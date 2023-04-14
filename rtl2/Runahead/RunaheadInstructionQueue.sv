module RunaheadInstructionQueue #(
    parameter RUNAHEADDEPTH = 32,
    parameter STACKTAGWIDTH = 4,
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  Stalled, //! Think through when this would be used
    output RunaheadFIFOFullStall,

    // Instruction Input
    input         FetchedInstructionValid,
    input  [15:0] FetchedInstruction,
    // input         AWouldHaveForwarded,
    // input         BWouldHaveForwarded,

    // Register Status
    input  [15:0] DirtyVector,
    input  [15:0] ToBeWrittenVector,
    input  [15:0] ToBeReadVector,

    // Speculation Interface
    input         Speculating,
    input         EndSpeculationPulse,
    input         MispredictedSpeculationPulse,

    // Instruction Output
    output        RunaheadInstructionValid,
    output [15:0] RunaheadInstruction
);

    //* Entry:
    // // {Speculative, StackTag, AWouldHaveForwarded, BWouldHaveForwarded, Instruction}
    // {Speculative, StackTag, Instruction}
    
    //* Stack Tag
    // 4bit Tag for operations that Push to the Stack cache

    //* Speculative Bit:
    // Append a bit when speculating and pushing an instruction to the runahead queue.
    // > Have a counter to count how many instructions were pushed to the runahead queue during the current speculation.
    // - Increment Counter: Push an Instruction to the Runahead Queue while actively Speculating
    // - Decrement Counter: Issue an Instruction with a Speculative Bit '1'
    // If Predicted Correctly; Prevent any speculation until counter reaches 0
    // If Predicted Incorrectly; Add counter value to Runahead Tail pointer... effectively throwing away all speculative instructions.
    // > Spectulation Valid Bit
    // - Set: Begining Speculation
    // - Clear: Mispredicted || (~Speculating && Counter == 1 && RunaheadIssue) [When issuing your last speculative instruction, post speculation]

    //! When to forward Instruction into Runahead Queue: DirtyBForward || DirtyAForward || ADirty || BDirty || (AToBeRead != 0)
    //* When to Issue from Runahead Queue: ~ADirty && ~BDirty
    //! When to Stall: AToBeWritten || BToBeWritten
    //! When to Un-Stall: ~AToBeWritten && ~BToBeWritten
    //! Else; Issue Instruction


    //* Runahead Queue
        localparam FIFOBITWIDTH = 1 + STACKTAGWIDTH + DATABITWIDTH;
        BufferedFIFO #(
            .DATABITWIDTH(FIFOBITWIDTH),
            .FIFODEPTH   (RUNAHEADDEPTH)
        ) RunaheadQueue (
            .clk       (clk),
            .clk_en    (clk_en),
            .sync_rst  (sync_rst),
            .InputREQ  (),
            .InputACK  (),
            .InputData (),
            .OutputREQ (),
            .OutputACK (),
            .FIFOTailOffset(TailOffset),
            .OutputData()
        );
    //*



endmodule : RunaheadInstructionQueue