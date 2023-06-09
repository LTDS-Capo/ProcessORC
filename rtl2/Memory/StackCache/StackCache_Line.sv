module StackCache_Line #(
    parameter LINESIZE = 8,
    parameter DATABITWIDTH = 16,
    parameter PENDINGREADBITWIDTH = 8,
    //* Do Not Change During Instantiation
    parameter LINEADDRBITWIDTH = (LINESIZE == 1) ? 1 : $clog2(LINESIZE)
)(
    input clk,
    input clk_en,
    input sync_rst,

    // Data In
    input  [LINEADDRBITWIDTH-1:0] WriteAddr,
    input                         WriteEn,
    input      [DATABITWIDTH-1:0] DataIn,

    // State Machine Inputs
    input                         InstructionValid, //! Uses ReadAddr
    input                         DirtyWrite,
    input                         DirtyIssue,
    input                         ToRunahead,
    input                         FromRunahead,
    input                         WritingTo,

    // Speculation Status
    input                         Speculating,
    input                         EndSpeculationPulse,
    input                         MispredictedSpeculationPulse,

    // Line Status
    output                        LineAllClean,

    // Runahead Checking
    input  [LINEADDRBITWIDTH-1:0] RunaheadCheckIndex,
    output                        RunaheadCheckDirty,

    // Data and Status Out
    input  [LINEADDRBITWIDTH-1:0] ReadAddr,
    input                         ReadEn,
    output     [DATABITWIDTH-1:0] DataOut,
    output                        IsDirty,
    output                        HasPendingWrite
);

//? Write Decoder
    logic [LINESIZE-1:0] DecodedWriteAddr;
    always_comb begin
        DecodedWriteAddr = 0;
        DecodedWriteAddr[WriteAddr] = 1'b1;
    end
//

//? Read Decoder
    logic [LINESIZE-1:0] DecodedReadAddr;
    always_comb begin
        DecodedReadAddr = 0;
        DecodedReadAddr[ReadAddr] = 1'b1;
    end
//

//? Entry Generation
    wire [LINESIZE-1:0][DATABITWIDTH-1:0] LineReadVector;
    wire [LINESIZE-1:0]                   IsCleanVector;
    wire [LINESIZE-1:0]                   IsDirtyVector;
    wire [LINESIZE-1:0]                   HasPendingWriteVector;
    genvar INDEX;
    generate
        for (INDEX = 0; INDEX < LINESIZE; INDEX = INDEX + 1) begin : LineEntryGeneration
            wire LocalWriteEn = WriteEn && DecodedWriteAddr[INDEX];
            wire LocalInstructionValid = InstructionValid && DecodedReadAddr[INDEX];
            StackCache_Line_Entry #(
                .DATABITWIDTH       (DATABITWIDTH),
                .PENDINGREADBITWIDTH(PENDINGREADBITWIDTH)
            ) LineEntry (
                .clk                         (clk),
                .clk_en                      (clk_en),
                .sync_rst                    (sync_rst),
                .WriteEn                     (LocalWriteEn), //* Triggers State Update
                .DataIn                      (DataIn),
                .InstructionValid            (LocalInstructionValid), //* Triggers State Update
                .DirtyWrite                  (DirtyWrite),
                .DirtyIssue                  (DirtyIssue),
                .ToRunahead                  (ToRunahead),
                .FromRunahead                (FromRunahead),
                .WritingTo                   (WritingTo),
                .ReadingFrom                 (ReadEn),
                .Speculating                 (Speculating),
                .EndSpeculationPulse         (EndSpeculationPulse),
                .MispredictedSpeculationPulse(MispredictedSpeculationPulse),
                .DataOut                     (LineReadVector[INDEX]),
                .IsClean                     (IsCleanVector[INDEX]),
                .IsDirty                     (IsDirtyVector[INDEX]),
                .HasPendingWrite             (HasPendingWriteVector[INDEX])
            );
        end
    endgenerate
//

//? Output Assignments
    wire   AnyNotCleanCheck = |IsCleanVector;
    assign LineAllClean = ~AnyNotCleanCheck;

    assign DataOut = LineReadVector[ReadAddr];
    assign IsDirty = IsDirtyVector[ReadAddr];
    assign HasPendingWrite = HasPendingWriteVector[ReadAddr];

    assign RunaheadCheckDirty = IsDirtyVector[RunaheadCheckIndex];
//

endmodule : StackCache_Line