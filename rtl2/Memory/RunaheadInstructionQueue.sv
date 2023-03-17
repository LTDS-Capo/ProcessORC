module RunaheadInstructionQueue #(
    parameter RUNAHEADDEPTH = 32
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  Stalled,
    output RunaheadFIFOFull,

    // Instruction Input
    input         FetchedInstructionValid,
    input  [15:0] FetchedInstruction,
    input         AWouldHaveForwarded,
    input         BWouldHaveForwarded,

    input  [15:0] DirtyVector,
    input  [15:0] ToBeWrittenVector,
    input  [15:0] ToBeReadVector,

    // Instruction Output
    output        RunaheadInstructionValid,
    output [15:0] RunaheadInstruction
);

    // Entry:
    // {Speculative, StackTag, AWouldHaveForwarded, BWouldHaveForwarded, Instruction}
    
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

    // When to forward Instruction into Runahead Queue: DirtyBForward || DirtyAForward || ADirty || BDirty || (AToBeRead != 0)
    // When to Issue from Runahead Queue: ~ADirty && ~BDirty
    // When to Stall: AToBeWritten || BToBeWritten
    // When to Un-Stall: ~AToBeWritten && ~BToBeWritten
    // Else; Issue Instruction

    // Runahead FIFO
        localparam FIFOINDEXBITWIDTH = (RUNAHEADDEPTH == 1) ? 1 : $clog2(RUNAHEADDEPTH);
        // Entry following struction
        // [15:0] - Instruction
        // Head Index
            reg  [FIFOINDEXBITWIDTH:0] HeadIndex;
            wire [FIFOINDEXBITWIDTH:0] NextHeadIndex = sync_rst ? '0 : (HeadIndex + 1);
            wire HeadIndexTrigger = sync_rst || (clk_en && ~FIFOFull && FetchedInstructionValid && ~FetchedOperandAStatus && ~Stalled) || (clk_en && ~FIFOFull && FetchedInstructionValid && ~FetchedOperandBStatus && ~Stalled);
            always_ff @(posedge clk) begin
                if (HeadIndexTrigger) begin
                    HeadIndex <= NextHeadIndex;
                end
            end
        // Tail Index
            reg  [FIFOINDEXBITWIDTH:0] TailIndex;
            wire [FIFOINDEXBITWIDTH:0] NextTailIndex = sync_rst ? '0 : (TailIndex + 1);
            wire TailIndexTrigger = sync_rst || (clk_en && ~FIFOEmpty && RunaheadHeadInstrucionStatus && OperandAStatus && OperandBStatus && ~Stalled);
            always_ff @(posedge clk) begin
                if (TailIndexTrigger) begin
                    TailIndex <= NextTailIndex;
                end
            end
        // Memory
            reg  [17:0] RunaheadFIFO [RUNAHEADDEPTH-1:0];
            wire [17:0] NextRunaheadEntry = {AWouldHaveForwarded, BWouldHaveForwarded, FetchedInstruction};
            always_ff @(posedge clk) begin
                if (RunaheadFIFOTrigger) begin
                    RunaheadFIFO[HeadIndex] <= NextRunaheadFIFO;
                end
            end
            wire [17:0] CurrentRunaheadInstruction = RunaheadFIFO[TailIndex][15:0];
            wire        AForwarded = RunaheadFIFO[TailIndex][17];
            wire        BForwarded = RunaheadFIFO[TailIndex][16];
        // FIFO Full/Empty Status - // TODO: Make this a Buffered-Precheck
	        wire   HeadTailLowerCompare = HeadIndex[INDEXBITWIDTH-1:0] == TailIndex[INDEXBITWIDTH-1:0];
	        wire   HeadTailUpperCompare = HeadIndex[INDEXBITWIDTH] ^ TailIndex[INDEXBITWIDTH];
	        wire   FIFOFull = HeadTailLowerCompare && HeadTailUpperCompare;
	        wire   FIFOEmpty = HeadTailLowerCompare && ~HeadTailUpperCompare;
            assign RunaheadFIFOFull = FIFOFull;
    //

    // Current Runahead Instruction State
        // Instruction Status
            reg  RunaheadHeadInstrucionStatus;
            wire NextRunaheadHeadInstrucionStatus = ~sync_rst && CurrentRunaheadInstruction[18];
            wire RunaheadHeadInstrucionStatusTrigger = sync_rst || (clk_en && CurrentRunaheadInstruction[18]);
            always_ff @(posedge clk) begin
                if (RunaheadHeadInstrucionStatusTrigger) begin
                    RunaheadHeadInstrucionStatus <= NextRunaheadHeadInstrucionStatus;
                end
            end
    //




endmodule : RunaheadInstructionQueue