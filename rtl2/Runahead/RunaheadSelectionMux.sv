module RunaheadSelectionMux (
    input         FetchedInstructionValid,
    input  [15:0] FetchedInstruction,

    input         RunaheadInstrucionValid,
    input  [15:0] RunaheadInstruction,

    output        InstructionValid,
    output        StallFetchedPath,
    output        InstructionIsARunahead,
    output [15:0] Instruction
);

    assign InstructionValid = FetchedInstructionValid || RunaheadInstrucionValid;
    assign StallFetchedPath = RunaheadInstrucionValid;
    assign InstructionIsARunahead = FetchedInstructionValid;
    assign Instruction = RunaheadInstrucionValid ? RunaheadInstruction : FetchedInstruction;

endmodule : RunaheadSelectionMux