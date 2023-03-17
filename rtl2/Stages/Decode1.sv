module Decode1 #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    // From Decode 0
        // Instruction
    input                     IssuedInstructionValid,
    input              [15:0] IssuedInstruction,
        // Decoded Instruction
    // TODO: Decoded Instruction
        // Operand A
    input  [DATABITWIDTH-1:0] OperandADataIn,
    input               [3:0] OperandARegisterAddress,
    input               [3:0] OperandAStackCacheTag, // TODO:
    input               [1:0] OperandAStatusVector, // [2]Dirty , [1]ToBeWritten, [0]ToBeRead
    input                     Forward0ToA,
    input                     Forward1ToA,
        // Operand B
    input  [DATABITWIDTH-1:0] OperandBDataIn,
    input               [3:0] OperandBRegisterAddress,
    input               [3:0] OperandBStackCacheTag, // TODO:
    input               [1:0] OperandBStatusVector, // [2]Dirty , [1]ToBeWritten, [0]ToBeRead
    input                     Forward0ToB,
    input                     Forward1ToB,

    // From Execution Writeback
    input  [DATABITWIDTH-1:0] WritebackResult,

    // From Load Interface
    input                     LoadToBeWritten,
    input               [3:0] LoadRegisterDestination,
    input  [DATABITWIDTH-1:0] LoadResult,

    // To Runahead Queue
    output                    InstructionToRunaheadQueueValid,
    output             [15:0] InstructionToRunaheadQueue,
    output                    AWouldHaveForwarded,
    output                    BWouldHaveForwarded,

    // To Execution Stage
    output              [3:0] MinorOpcode,
    output [DATABITWIDTH-1:0] OperandADataOut,
    output [DATABITWIDTH-1:0] OperandADataOut
);

    // Runahead Operand Validation
        wire InvalidateIssuedInstruction;
        wire ForwardLoadToA;
        wire ForwardLoadToB;
        RunaheadOperandValidation OperandValidation (
            .clk                            (clk),
            .clk_en                         (clk_en),
            .sync_rst                       (sync_rst),
            .IssuedInstructionValid         (IssuedInstructionValid),
            .IssuedInstruction              (IssuedInstruction),
            .OperandARegisterAddress        (OperandARegisterAddress),
            .OperandAStatusVector           (OperandAStatusVector),
            .OperandBRegisterAddress        (OperandBRegisterAddress),
            .OperandBStatusVector           (OperandBStatusVector),
            .Forward0ToA                    (Forward0ToA),
            .Forward1ToA                    (Forward1ToA),
            .Forward0ToB                    (Forward0ToB),
            .Forward1ToB                    (Forward1ToB),
            .LoadToBeWritten                (LoadToBeWritten),
            .LoadRegisterDestination        (LoadRegisterDestination),
            .InstructionToRunaheadQueueValid(InstructionToRunaheadQueueValid),
            .InstructionToRunaheadQueue     (InstructionToRunaheadQueue),
            .AWouldHaveForwarded            (AWouldHaveForwarded),
            .BWouldHaveForwarded            (BWouldHaveForwarded),
            .InvalidateIssuedInstruction    (InvalidateIssuedInstruction),
            .ForwardLoadToA                 (ForwardLoadToA),
            .ForwardLoadToB                 (ForwardLoadToB)
        );
    //

    // Forwarding Multiplexer
        wire [DATABITWIDTH-1:0] LocalOperandAData;
        wire [DATABITWIDTH-1:0] LocalOperandBData;
        ForwardingMux #(
            .DATABITWIDTH(16)
        ) Forwarder (
            .clk            (clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .OperandADataIn (OperandADataIn),
            .Forward0ToA    (Forward0ToA),
            .Forward1ToA    (Forward1ToA),
            .ForwardLoadToA (ForwardLoadToA),
            .OperandBDataIn (OperandBDataIn),
            .Forward0ToB    (Forward0ToB),
            .Forward1ToB    (Forward1ToB),
            .ForwardLoadToB (ForwardLoadToB),
            .WritebackResult(WritebackResult),
            .LoadResult     (LoadResult),
            .OperandADataOut(LocalOperandAData),
            .OperandADataOut(LocalOperandBData)
        );
    //

    // Instruction Issue
        // TODO: Instruction Issue
    //

    // Pipeline Buffer
        // TODO: Pipeline Buffer

    //

    // Output Assignment
        // TODO: Output Assignment

    //

endmodule : Decode1