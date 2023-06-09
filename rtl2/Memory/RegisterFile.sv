module RegisterFile #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    // Speculation Status
    input                     Speculating,
    input                     EndSpeculationPulse,
    input                     MispredictedSpeculationPulse,

    // Read Operands
        // Operand A
    input               [3:0] OperandAAddr,
    input               [3:0] SecondardyOperandAAddr,
    input                     OperandADirtySet,
    input                     OperandAReadEn,
    input                     WillBeWritingToA,
    output [DATABITWIDTH-1:0] OperandAData,
    output              [1:0] OperandAStatus,
        // Operand B
    input               [3:0] OperandBAddr,
    input                     OperandBReadEn,
    output [DATABITWIDTH-1:0] OperandBData,
    output              [1:0] OperandBStatus,

    // From Instruction Issue
    input                     IssuedFromA,
    input               [3:0] IssueAAddress,
    input                     IssuedFromB,
    input               [3:0] IssueBAddress,   

    // From Writeback
    input                     WritebackEn,
    input               [3:0] WritebackRegisterAddr,
    input  [DATABITWIDTH-1:0] WritebackData,
    
    // From Load Interface
    input                     LoadWriteEn,
    input               [3:0] LoadWriteRegisterAddr,
    input  [DATABITWIDTH-1:0] LoadWriteData,

    // To Runahead Queue
    output [15:0] DirtyVector,
    output        RunaheadEnqueue, // TODO

    // To Stall Controller
    output ToBeWrittenStall
);

    // Read A Decoder
        logic [15:0] OperandAOneHot;
        always_comb begin
            OperandAOneHot = 0;
            OperandAOneHot[OperandAAddr] = 1'b1;
        end
    //

    // Writeback Decoder
        logic [15:0] WritebackOneHot;
        always_comb begin
            WritebackOneHot = 0;
            WritebackOneHot[WritebackRegisterAddr] = 1'b1;
        end
    //

    // LoadWrite Decoder
        logic [15:0] LoadWriteOneHot;
        always_comb begin
            LoadWriteOneHot = 0;
            LoadWriteOneHot[LoadWriteRegisterAddr] = 1'b1;
        end
    //

    // Register Cell Generation
        wire [15:0][DATABITWIDTH-1:0] RegisterReadVector;
        genvar REGISTERINDEX;
        generate
            for (REGISTERINDEX = 0; REGISTERINDEX < 16; REGISTERINDEX = REGISTERINDEX + 1) begin : RegisterCellGeneration
                if (REGISTERINDEX == 0) begin // Zero Register, always zero
                    assign RegisterReadVector[REGISTERINDEX] = 0;
                end
                else if (REGISTERINDEX == 14) begin // Top of Stack
                    assign RegisterReadVector[REGISTERINDEX] = 0; // TODO:
                end
                else begin // Registers 1-13, 15
                    wire Cell_WillBeWritingToA = OperandAOneHot[REGISTERINDEX] && WillBeWritingToA;
                    wire Cell_WriteBackEn = WritebackOneHot[REGISTERINDEX] && WritebackEn;
                    wire Cell_LoadWriteEn = LoadWriteOneHot[REGISTERINDEX] && LoadWriteEn;
                    RegisterFile_Cell #(
                        .DATABITWIDTH(DATABITWIDTH)
                    ) Register_Cell (
                        .clk                         (clk),
                        .clk_en                      (clk_en),
                        .sync_rst                    (sync_rst),
                        .Speculating                 (Speculating),
                        .WillBeWritingToA            (WillBeWritingToA),
                        .EndSpeculationPulse         (EndSpeculationPulse),
                        .MispredictedSpeculationPulse(MispredictedSpeculationPulse),
                        .CurrentlySpeculative        (), // Do Not Care
                        .WritebackEn                 (Cell_WriteBackEn),
                        .WritebackData               (WritebackData),
                        .LoadWriteEn                 (Cell_LoadWriteEn),
                        .LoadWriteData               (LoadWriteData),
                        .ReadData                    (RegisterReadVector[REGISTERINDEX])
                    );
                end
            end
        endgenerate
        assign OperandAData = RegisterReadVector[OperandAAddr];
        assign OperandBData = RegisterReadVector[OperandBAddr];
    //

    // Register Status
        wire [15:0] ToBeWrittenVector;
        RegisterStatus RegStatus (
            .clk               (clk),
            .clk_en            (clk_en),
            .sync_rst          (sync_rst),
            .ReadingFromA      (OperandAReadEn),
            .WillBeWritingToA  (WillBeWritingToA),
            .ReadAOperandOneHot(ReadAOperandOneHot),
            .MarkADirty        (OperandADirtySet),
            .ReadingFromB      (OperandBReadEn),
            .ReadBAddress      (OperandBAddr),
            .IssuedFromA       (IssuedFromA),
            .IssueAAddress     (IssueAAddress),
            .IssuedFromB       (IssuedFromB),
            .IssueBAddress     (IssueBAddress),
            .LoadingToReg      (LoadWriteEn),
            .LoadingRegOneHot  (LoadWriteOneHot),
            .WritingToReg      (WritebackEn),
            .WritingRegOneHot  (WritebackOneHot),
            .StackDirty        (SOMETHING),
            .StackToBeWritten  (SOMETHING),
            .StackToBeRead     (SOMETHING),
            .DirtyVector       (DirtyVector),
            .ToBeWrittenVector (ToBeWrittenVector),
            .ToBeReadVector    (ToBeReadVector)
        );
        assign OperandAStatus = {DirtyVector[OperandAAddr], ToBeReadVector[OperandAAddr]};
        assign OperandBStatus = {DirtyVector[OperandBAddr], ToBeReadVector[OperandBAddr]};
        assign ToBeWrittenStall = WillBeWritingToA && ToBeWrittenVector[SecondardyOperandAAddr];
    //

    // Stack Cache

    //

endmodule : RegisterFile