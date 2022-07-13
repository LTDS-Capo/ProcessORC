module InstructionIssue #(
    parameter DATABITWIDTH = 16,
    parameter TAGBITWIDTH = 6,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    // Instruction Input
    input                  [3:0] MinorOpcode,
    input                  [4:0] FunctionalUnitEnable,
    input                  [1:0] WriteBackSourceIn,
    input                        RegAWriteEnIn,
    input                        InstructionTagValid,
    input      [TAGBITWIDTH-1:0] InstructionTagIn,
    input                        WritebackEnIn,
    input  [REGADDRBITWIDTH-1:0] WritebackRegAddr,
    input     [DATABITWIDTH-1:0] RegADataIn,
    input     [DATABITWIDTH-1:0] RegBDataIn,

    // Program Counter Out
    output                    BranchEn,
    // ALU Simple 0 Out
    output                    ALU0_Enable,
    // ALU Simple 1 Out
    output                    ALU1_Enable,
    // Universal Outputs
    output              [3:0] ALU_MinorOpcode,
    output [DATABITWIDTH-1:0] Data_A,
    output [DATABITWIDTH-1:0] Data_B,

    // Complex ALU Out
        // TODO:

    // Memory Out (Load Store Unit)
        // TODO:

    // Stall out
    output  IssueCongestionStallOut,

    // Writeback Control Out
    output                       RegWriteEn,
    output                 [1:0] WriteBackSourceOut,
    output [REGADDRBITWIDTH-1:0] RegWriteAddrOut
);
    assign IssueCongestionStallOut = 0;

    // Branch output assignments
    assign BranchEn = FunctionalUnitEnable[4];

    // ALU0 output assignments
    assign ALU0_Enable = FunctionalUnitEnable[0];
    
    // ALU1 output assignments
    assign ALU1_Enable = FunctionalUnitEnable[1];

    // Universal output assignments
    assign MinorOpcode = MinorOpcode;
    assign Data_A = RegADataIn;
    assign Data_B = RegBDataIn;

    // Writeback Control output assignments
    assign WriteBackSourceOut = WriteBackSourceIn;
    assign RegWriteAddrOut = WritebackRegAddr;
    assign RegWriteEn = WritebackEnIn;

endmodule