module StackCache_Line_Entry #(
    parameter DATABITWIDTH = 16,
    parameter PENDINGREADBITWIDTH = 8
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                     WriteEn,
    input  [DATABITWIDTH-1:0] DataIn,

    // State Machine Inputs
    input                     InstructionValid,
    input                     DirtyWrite,
    input                     DirtyIssue,
    input                     ToRunahead,
    input                     FromRunahead,
    input                     WritingTo,
    input                     ReadingFrom,

    // Speculation Status
    input                     Speculating,
    input                     EndSpeculationPulse,
    input                     MispredictedSpeculationPulse,

    output [DATABITWIDTH-1:0] DataOut,
    output                    IsClean,
    output                    IsDirty,
    output                    HasPendingWrite
);

        wire LocalIsClean;
        GPRStateMachine #(
            .PENDINGREADBITWIDTH(PENDINGREADBITWIDTH)
        ) StateMachine (
            .clk             (clk),
            .clk_en          (clk_en),
            .sync_rst        (sync_rst),
            .InstructionValid(InstructionValid),
            .DirtyWrite      (DirtyWrite),
            .DirtyIssue      (DirtyIssue),
            .ToRunahead      (ToRunahead),
            .FromRunahead    (FromRunahead),
            .WritingBack     (WriteEn),
            .WritingTo       (WriteTo),
            .ReadingFrom     (ReadingFrom),
            .IsClean         (LocalIsClean),
            .IsDirty         (IsDirty),
            .HasPendingWrite (HasPendingWrite)
        );

        wire CurrentlySpeculative;
        RegisterFile_Cell #(
            .DATABITWIDTH(DATABITWIDTH)
        ) Register_Cell (
            .clk                         (clk),
            .clk_en                      (clk_en),
            .sync_rst                    (sync_rst),
            .Speculating                 (Speculating),
            .WillBeWritingToA            (WritingBack),
            .EndSpeculationPulse         (EndSpeculationPulse),
            .MispredictedSpeculationPulse(MispredictedSpeculationPulse),
            .CurrentlySpeculative        (CurrentlySpeculative),
            .WritebackEn                 (WriteEn),
            .WritebackData               (DataIn),
            .LoadWriteEn                 (1'b0),
            .LoadWriteData               ({DATABITWIDTH{1'b0}}),
            .ReadData                    (DataOut)
        );

        assign IsClean = LocalIsClean && ~CurrentlySpeculative;
        
endmodule : StackCache_Line_Entry
