module StackCache_PushWaitTable #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    // To/From Speculation Control
    input                     Speculating,
    input                     MispredictedSpeculationPulse,
    output                    AllowedToSpeculate,

    // Fence Status
    output                    NoPendingWrites,

    // Tag Request
    input                     InstructionValid,
    input                     WillBeWriting,
    output                    TagValid,
    output              [3:0] AssignedTag,
    input  [DATABITWIDTH-1:0] StackPointer,

    // Tag Clear
    input                     StackWriteEn,
    input               [3:0] StackWriteTag,
    output                    SpeculativeWrite,
    output [DATABITWIDTH-1:0] WriteAddress
);

    // Tag Counter
        // Post-Increments
        reg  [3:0] CurrentTag;
        wire [3:0] NextCurrentTag = sync_rst ? 0 : (CurrentTag + 1);
        wire CurrentTagTrigger = sync_rst || (clk_en && InstructionValid && WillBeWriting && TagValid);
        always_ff @(posedge clk) begin
            if (CurrentTagTrigger) begin
                CurrentTag <= NextCurrentTag;
            end
        end
        wire   [1:0] CurrentTagStatus = TagVector[CurrentTag];
        assign       TagValid = ~CurrentTagStatus[0];
        assign       AssignedTag = CurrentTag;
    //

    // Tag Status Table
        // {Speculating, InFlight}
        reg  [31:0] TagTable;
        wire [31:0] NextTagTable = NewTagVector;
        wire TagTableTrigger = sync_rst || (clk_en && MispredictedSpeculationPulse) || (clk_en && InstructionValid && WillBeWriting && TagValid) || (clk_en && StackWriteEn);
        always_ff @(posedge clk) begin
            if (TagTableTrigger) begin
                TagTable <= NextTagTable;
            end
        end
        wire [15:0][1:0] TagVector = TagTable;
        // Current Tag Decoder
            logic [15:0] CurrentTagOneHot;
            always_comb begin
                CurrentTagOneHot = 0;
                CurrentTagOneHot[CurrentTag] = 1'b1;
            end
        //
        // Stack Write Decoder
            logic [15:0] StackWriteOneHot;
            always_comb begin
                StackWriteOneHot = 0;
                StackWriteOneHot[StackWriteTag] = 1'b1;
            end
        //
        wire [15:0][1:0] NewTagVector;
        wire [15:0]      PendingWriteVector;
        genvar TAGINDEX;
        generate
            for (TAGINDEX = 0; TAGINDEX < 16; TAGINDEX = TAGINDEX + 1) begin : TagVectorModification
                logic  [1:0] NewTagStatus;
                wire   [1:0] TagStatusCondition;
                assign       TagStatusCondition[0] = (WillBeWriting && TagValid && CurrentTagOneHot[TAGINDEX]) || (TagVector[TAGINDEX][1] && MispredictedSpeculationPulse) || sync_rst;
                assign       TagStatusCondition[1] = (StackWriteEn && StackWriteOneHot[TAGINDEX]) || sync_rst;
                always_comb begin : NewTagStatusMux
                    case (TagStatusCondition)
                        2'b00  : NewTagStatus = TagVector[TAGINDEX]; // Stay the same
                        2'b01  : NewTagStatus = {Speculating, TagValid}; // Allocate
                        2'b10  : NewTagStatus = 0; // Clear
                        2'b11  : NewTagStatus = 0; // Reset
                        default: NewTagStatus = 0;
                    endcase
                end
                assign NewTagVector[TAGINDEX] = NewTagStatus;
                assign PendingWriteVector[TAGINDEX] = TagVector[TAGINDEX][0];
            end
        endgenerate
        assign NoPendingWrites = ~|PendingWriteVector;
    //

    // Tag Address Table
        reg  [DATABITWIDTH-1:0] TagAddressTable [15:0];
        always_ff @(posedge clk) begin
            if (CurrentTagTrigger) begin
                TagAddressTable[CurrentTag] <= StackPointer;
            end
        end
        assign WriteAddress = TagAddressTable[StackWriteTag];
        assign SpeculativeWrite = TagVector[StackWriteTag][1];
    //

    // Speculative Counter
        // Only allow the system to speculate when this counter is Zero.
        // Increment: when requesting a valid tag while Speculating
        // Decrement: when an instruction writes back to a speculative tag
        reg  [4:0] SpeculativeCounter;
        wire [4:0] SpeculationDelta = {{4{(SpeculativeWrite && StackWriteEn)}}, 1'b1};
        wire [4:0] NextSpeculativeCounter = sync_rst ? 0 : (SpeculativeCounter + SpeculationDelta);
        wire SpeculativeCounterTrigger = sync_rst || (clk_en && Speculating && InstructionValid && WillBeWriting && TagValid) || (clk_en && TagVector[StackWriteTag][1] && StackWriteEn);
        always_ff @(posedge clk) begin
            if (SpeculativeCounterTrigger) begin
                SpeculativeCounter <= NextSpeculativeCounter;
            end
        end
        assign AllowedToSpeculate = SpeculativeCounter == 5'h00;
    //

endmodule : StackCache_PushWaitTable