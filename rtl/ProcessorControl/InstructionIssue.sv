module InstructionIssue #(
    parameter DATABITWIDTH = 16,
    parameter TAGBITWIDTH = 6,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                        StallIn,

    // Instruction Input
    input                  [3:0] MinorOpcode,
    input                  [4:0] FunctionalUnitEnable,
    input                  [1:0] WriteBackSourceIn,
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
    input                         LoadStore_REQ,
    output                        LoadStore_ACK,

    // Stall out
    output  IssueCongestionStallOut,

    // Writeback Control Out
    output                       RegWriteEn,
    output                 [1:0] WriteBackSourceOut,
    output [REGADDRBITWIDTH-1:0] RegWriteAddrOut
);

    // Branch output assignments
    assign BranchEn = FunctionalUnitEnable[4];

    // ALU0 output assignments
    assign ALU0_Enable = FunctionalUnitEnable[0];
    
    // ALU1 output assignments
    assign ALU1_Enable = FunctionalUnitEnable[1];

    // Universal output assignments
    assign ALU_MinorOpcode = MinorOpcode;
    assign Data_A = RegADataIn;
    assign Data_B = RegBDataIn;

    // Writeback Control output assignments
    assign WriteBackSourceOut = WriteBackSourceIn;
    assign RegWriteAddrOut = WritebackRegAddr;
    assign RegWriteEn = WritebackEnIn;

    // Stall Flag
    reg  CongestionStallBuffer;
    wire CongestionStallBufferTrigger = (LoadStore_ACK && LoadStore_REQ && clk_en) || (LoadStore_ACK && ~LoadStore_REQ && clk_en) || sync_rst;
    wire NextCongestionStallBuffer = ~LoadStore_REQ && ~sync_rst;
    always_ff @(posedge clk) begin
        if (CongestionStallBufferTrigger) begin
            CongestionStallBuffer <= NextCongestionStallBuffer;
        end
    end
    
    assign IssueCongestionStallOut = LoadStore_ACK && ~LoadStore_REQ;
    


    // Load Store Unit Control
    assign LoadStore_ACK = (FunctionalUnitEnable[3] || CongestionStallBuffer) && ~StallIn;

endmodule