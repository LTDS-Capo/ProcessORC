module RegisterStatus (
    input clk,
    input clk_en,
    input sync_rst,

    input         ReadingFromA,
    input         WillBeWritingToA,
    input   [3:0] ReadAAddress, // Turn into a OneHot from primary Register Read
    input         MarkADirty,
    input         ReadingFromB,
    input   [3:0] ReadBAddress, // Turn into a OneHot from primary Register Read

    input         IssuedFromA,
    input   [3:0] IssueAAddress,
    input         IssuedFromB,
    input   [3:0] IssueBAddress,

    input         LoadingToReg,
    input   [3:0] LoadingRegAddress,

    input         WritingToReg,
    input   [3:0] WritingRegAddress,

    input         StackDirty, // make a dedicated unit just for this
    input         StackToBeWritten, // make a dedicated unit just for this
    input         StackToBeRead, // make a dedicated unit just for this

    output [15:0] DirtyVector,
    output [15:0] ToBeWrittenVector,
    output [15:0] ToBeReadVector
);


    // Read A Decoder
        logic [15:0] ReadAOperandOneHot;
        always_comb begin
            ReadAOperandOneHot = 0;
            ReadAOperandOneHot[ReadAAddress] = 1'b1;
        end
    //

    // Read B Decoder
        logic [15:0] ReadBOperandOneHot;
        always_comb begin
            ReadBOperandOneHot = 0;
            ReadBOperandOneHot[ReadBAddress] = 1'b1;
        end
    //

    // Issue A Decoder
        logic [15:0] IssueAOperandOneHot;
        always_comb begin
            IssueAOperandOneHot = 0;
            IssueAOperandOneHot[IssueAAddress] = 1'b1;
        end
    //

    // Issue B Decoder
        logic [15:0] IssueBOperandOneHot;
        always_comb begin
            IssueBOperandOneHot = 0;
            IssueBOperandOneHot[IssueBAddress] = 1'b1;
        end
    //

    // Loading To Reg Decoder
        logic [15:0] LoadingRegOneHot;
        always_comb begin
            LoadingRegOneHot = 0;
            LoadingRegOneHot[LoadingRegAddress] = 1'b1;
        end
    //

    // Writeing To Reg Decoder
        logic [15:0] WritingRegOneHot;
        always_comb begin
            WritingRegOneHot = 0;
            WritingRegOneHot[WritingRegAddress] = 1'b1;
        end
    //

    // Register Status
        genvar RegisterGenIndex;
        generate
            for (RegisterGenIndex = 0; RegisterGenIndex < 16; RegisterGenIndex = RegisterGenIndex + 1) begin : RegisterGeneration
                if (RegisterGenIndex == 14) begin // Top of Stack Exception
                    assign DirtyVector[RegisterGenIndex] = StackDirty;
                    assign ToBeWrittenVector[RegisterGenIndex] = StackToBeWritten;
                    assign ToBeReadVector[RegisterGenIndex] = StackToBeRead;
                end
                else begin
                    wire UsedAsA = ReadAOperandOneHot[RegisterGenIndex] && ReadingFromA;
                    wire LocalWillBeWritingToA = ReadAOperandOneHot[RegisterGenIndex] && WillBeWritingToA;
                    wire MarkDirty = ReadAOperandOneHot[RegisterGenIndex] && WillBeWritingToA && MarkADirty;
                    wire UsedAsB = ReadBOperandOneHot[RegisterGenIndex] && ReadingFromB;
                    wire IssuedAsA = IssueAOperandOneHot[RegisterGenIndex] && IssuedFromA;
                    wire IssuedAsB = IssueBOperandOneHot[RegisterGenIndex] && IssuedFromB;
                    wire LoadValid = LoadingRegOneHot[RegisterGenIndex] && LoadingToReg;
                    wire WritebackValid = WritingRegOneHot[RegisterGenIndex] && WritingToReg;
                    RegisterStateCell RegisterState (
                        .clk             (clk),
                        .clk_en          (clk_en),
                        .sync_rst        (sync_rst),
                        .UsedAsA         (UsedAsA),
                        .WillBeWritingToA(LocalWillBeWritingToA),
                        .MarkDirty       (MarkDirty),
                        .UsedAsB         (UsedAsB),
                        .IssuedAsA       (IssuedAsA),
                        .IssuedAsB       (IssuedAsB),
                        .LoadValid       (LoadValid),
                        .WritebackValid  (WritebackValid),
                        .Dirty           (DirtyVector[RegisterGenIndex]),
                        .ToBeWritten     (ToBeWrittenVector[RegisterGenIndex]),
                        .ToBeRead        (ToBeReadVector[RegisterGenIndex])
                    );
                end
            end
        endgenerate
    //

endmodule : RegisterStatus