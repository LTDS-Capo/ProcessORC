module RunaheadOperandValidation (
    input clk,
    input clk_en,
    input sync_rst,

    input         IssuedInstructionValid,
    input  [15:0] IssuedInstruction,
    input   [3:0] OperandARegisterAddress,
    input   [1:0] OperandAStatusVector, // [2]Dirty , [1]ToBeWritten, [0]ToBeRead
    input   [3:0] OperandBRegisterAddress,
    input   [1:0] OperandBStatusVector, // [2]Dirty , [1]ToBeWritten, [0]ToBeRead
    input         Forward0ToA,
    input         Forward1ToA,
    input         Forward0ToB,
    input         Forward1ToB,

    input         LoadToBeWritten,
    input   [3:0] LoadRegisterDestination,

    output        InstructionToRunaheadQueueValid,
    output [15:0] InstructionToRunaheadQueue,
    output        AWouldHaveForwarded,
    output        BWouldHaveForwarded,

    output        InvalidateIssuedInstruction,
    output        ForwardLoadToA,
    output        ForwardLoadToB
);


    // When to forward Instruction into Runahead Queue: DirtyBForward || DirtyAForward || ADirty || BDirty || AToBeRead
    // Else; Issue Instruction

    // Runahead History
        reg  [1:0] RunaheadHistory;
        wire [1:0] NextRunaheadHistory = sync_rst ? 0 : {RunaheadHistory[0], InstructionToRunaheadQueueValid};
        wire RunaheadHistoryTrigger = sync_rst || clk_en;
        always_ff @(posedge clk) begin
            if (RunaheadHistoryTrigger) begin
                RunaheadHistory <= NextRunaheadHistory;
            end
        end
        wire DirtyAForward = (RunaheadHistory[1] && Forward1ToA) || (Forward0ToA && RunaheadHistory[0]);
        wire DirtyBForward = (RunaheadHistory[1] && Forward1ToB) || (Forward0ToB && RunaheadHistory[0]);
    //

    // Operand Status Decode
        wire   LoadAOperandMatch = (LoadRegisterDestination == OperandARegisterAddress) && LoadToBeWritten;
        wire   LoadBOperandMatch = (LoadRegisterDestination == OperandARegisterAddress) && LoadToBeWritten;
        wire   ADirty = OperandAStatusVector[2] && ~LoadAOperandMatch;
        wire   AToBeRead = OperandAStatusVector[0];
        wire   BDirty = OperandBStatusVector[2] && ~LoadBOperandMatch;
    //

    // Runahead Queue Connection Assigments
        assign InstructionToRunaheadQueueValid = (DirtyBForward || DirtyAForward || ADirty || BDirty || AToBeRead) && IssuedInstructionValid;
        assign InstructionToRunaheadQueue = IssuedInstructionValid;
        assign AWouldHaveForwarded = Forward0ToA || Forward1ToA;
        assign BWouldHaveForwarded = Forward0ToB || Forward1ToB;
    //

    // Issued Instruction Output Assignments
        assign InvalidateIssuedInstruction == InstructionToRunaheadQueueValid;
        assign ForwardLoadToA = LoadAOperandMatch;
        assign ForwardLoadToB = LoadBOperandMatch;
    //

endmodule : RunaheadOperandValidation


