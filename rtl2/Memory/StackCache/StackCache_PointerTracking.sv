module StackCache_PointerTracking #(
    parameter LINESIZE = 8,
    parameter ADDRESS_BITWIDTH = 32
)(
    input  clk,
    input  clk_en,
    input  sync_rst,

    input         Speculating,
    input         EndSpeculationPulse,
    input         MispredictedSpeculationPulse,
    //output        SpeculativeCSRWriteStall, //TODO: Generate this in the Instruction Decoder

    //! NOTE: The only value that can be changed during speculation is the stack pointer, but not by a swap... stall if any of those writes occure
    input  [31:0] CSRDataIn,
    // CSRAddr ShortHandStackAddresses
    // > 00 - Meta (PrePop & StackDirection)
    // > 01 - Stack Upper Bound
    // > 10 - Stack Lower Bound
    // > 11 - Stack Pointer (Aliased to Swap)
    input   [1:0] CSRAddr,
    input         CSRWriteEnable,
    output [31:0] CSRDataOut,

    input  [31:0] StackPointerSwapIn,
    input         PushEnable,
    input         PopEnable,
    output [31:0] CurrentStackPointer,
    //TODO Issue a Full Fence when either Error occurs, then trigger an exception
    output        OverflowError,
    output        UnderflowError,

    output        PushingOut,
    output        PoppingOut,
    output        PrePopEnable,
                                                                                                                                                                                         
    output        NextLinePushValid,
    output        LinePushValid,
    output        LineOnPushBounds,
    output        NextLinePopValid,
    output        LinePopValid,
    output        LineOnPopBounds
);


//? Stack Pointer
    //                                                                       //
    //* Common Connections
        localparam        LINEADDRBITWIDTH = (LINESIZE == 1) ? 1 : $clog2(LINESIZE);
        reg        [31:0] StackPointer;
        logic      [31:0] NextStackPointer;
        reg        [32:0] ShadowStackPointer;
    //                                                                       //
    //* Push Checking
        wire   PushInvalidityCheck = LineOnPushBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b0}});
        wire   PushValid = PushEnable && ~PushInvalidityCheck && ~sync_rst;
        assign OverflowError = PushEnable && PushInvalidityCheck;
    //                                                                       //
    //* Pop Checking
        wire   PopInvalidityCheck = LineOnPopBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b1}});
        wire   PopValid = PushEnable && ~PopInvalidityCheck && ~sync_rst;
        assign UnderflowError = PushEnable && PopInvalidityCheck;
    //                                                                       //
    //* Swap Checking
        wire   SwapValid = CSRAddr[1] && CSRAddr[0] && CSRWriteEnable && ~sync_rst;
    //                                                                       //
    //* Next Stack Pointer
        wire    [2:0] NextStackPointerCondition;
        assign        NextStackPointerCondition[0] = PushValid || SwapValid;
        assign        NextStackPointerCondition[1] = PopValid || SwapValid;
        assign        NextStackPointerCondition[2] = MispredictedSpeculationPulse && ~sync_rst;
        always_comb begin : NextStackPointerMux
            case (NextStackPointerCondition)
                3'b000 : NextStackPointer = 32'd0; // Default sync_rst output
                3'b001 : NextStackPointer = StackPointer - 32'd1; // Push
                3'b010 : NextStackPointer = StackPointer + 32'd1; // Pop
                3'b011 : NextStackPointer = StackPointerSwapIn; // Swap
                3'b100 : NextStackPointer = ShadowStackPointer[31:0]; // Misprediction Rollback
                3'b101 : NextStackPointer = ShadowStackPointer[31:0]; // Misprediction Rollback
                3'b110 : NextStackPointer = ShadowStackPointer[31:0]; // Misprediction Rollback
                3'b111 : NextStackPointer = ShadowStackPointer[31:0]; // Misprediction Rollback
                default: NextStackPointer = 32'd0;
            endcase
        end
    //                                                                       //
    //* Working Pointer
        wire StackPointerTrigger = sync_rst || (clk_en && CSRAddr[1] && CSRAddr[0] && CSRWriteEnable) || (clk_en && PushValid) || (clk_en && PopValid) || (clk_en && MispredictedSpeculationPulse);
        always_ff @(posedge clk) begin
            if (StackPointerTrigger) begin
                StackPointer <= NextStackPointer;
            end
        end
        assign CurrentStackPointer = StackPointer;
        assign PushingOut = PushEnable && ~LineOnPushBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b0}});
        assign PoppingOut = PopEnable && ~LineOnPopBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b1}});
    //                                                                       //
    //* Shadow Pointer - for speculation rollback
        wire [32:0] NextShadowStackPointer = (sync_rst || EndSpeculationPulse) ? 33'd0 : {1'b1, StackPointer};
        wire        ShadowStackPointerTrigger = sync_rst || (clk_en && Speculating && ~ShadowStackPointer[32]) || (clk_en && EndSpeculationPulse);
        always_ff @(posedge clk) begin
            if (ShadowStackPointerTrigger) begin
                ShadowStackPointer <= NextShadowStackPointer;
            end
        end
    //                                                                       //
//?

//? PrePop
    //                                                                       //
    //* Common Connections
        wire CSRMetaWriteTrigger = sync_rst || (clk_en && CSRWriteEnable && ~CSRAddr[1] && ~CSRAddr[0]);
    //                                                                       //
    //* Status
        reg  PrePop;
        wire NextPrePop = ~sync_rst && CSRDataIn[10];
        always_ff @(posedge clk) begin
            if (CSRMetaWriteTrigger) begin
                PrePop <= NextPrePop;
            end
        end
        assign PrePopEnable = PrePop;
    //                                                                       //
//?

//? Stack Upper Bounds
    //                                                                       //
    //* Common Connections
    wire [31:0] NextBound = sync_rst ? 32'd0 : CSRDataIn;
    //                                                                       //
    //* Buffer
    reg  [31:0] UpperBounds;
    wire        UpperBoundsTrigger = sync_rst || (clk_en && CSRWriteEnable && ~CSRAddr[1] && CSRAddr[0]);
    always_ff @(posedge clk) begin
        if (UpperBoundsTrigger) begin
            UpperBounds <= NextBound;
        end
    end
    //                                                                       //
//?

//? Stack Lower Bounds
    //                                                                       //
    //* Buffer
    reg  [31:0] LowerBounds;
    wire        LowerBoundsTrigger = sync_rst || (clk_en && CSRWriteEnable && CSRAddr[1] && ~CSRAddr[0]);
    always_ff @(posedge clk) begin
        if (LowerBoundsTrigger) begin
            LowerBounds <= NextBound;
        end
    end
    //                                                                       //
//? 

//? Bound Checks
    //                                                                       //
    //* Stack Pointer Offsetting
        wire   [31:0] RoundedDownStackPointer = {NextStackPointer[31:3], 3'd0};
        wire   [31:0] StackPointerPlus8 = RoundedDownStackPointer + 32'd8;
        wire   [31:0] StackPointerPlus16 = RoundedDownStackPointer + 32'd16;
        wire   [31:0] StackPointerSubtract8 = RoundedDownStackPointer - 32'd8;
        wire   [31:0] StackPointerSubtract16 = RoundedDownStackPointer - 32'd16;
    //                                                                       //
    //* Checks
        wire NextPushValidCheck = StackPointerSubtract8 >= LowerBounds;
        wire PushValidCheck = StackPointerSubtract16 >= LowerBounds;
        wire OnPushBoundsCheck = RoundedDownStackPointer >= LowerBounds;
        wire NextPopValidCheck = StackPointerPlus16 <= UpperBounds;
        wire PopValidCheck = StackPointerPlus8 <= UpperBounds;
        wire OnPopBoundsCheck = RoundedDownStackPointer == UpperBounds;
    //                                                                       //
    //* Buffer
        reg  [5:0] BoundCheckVector;
        wire [5:0] NextBoundCheckVector = sync_rst ? 6'd0 : {NextPushValidCheck, PushValidCheck, OnPushBoundsCheck, NextPopValidCheck, PopValidCheck, OnPopBoundsCheck};
        always_ff @(posedge clk) begin
            if (StackPointerTrigger) begin
                BoundCheckVector <= NextBoundCheckVector;
            end
        end
    //                                                                       //
//? 

//? Output Generation
    //                                                                       //
    //* CSR Read 
        logic [31:0] CSRSelection;
        always_comb begin : CSRSelectionMux
            case (CSRAddr)
                2'b00  : CSRSelection = {21'd0, PrePop, 10'd0};
                2'b01  : CSRSelection = UpperBounds;
                2'b10  : CSRSelection = LowerBounds;
                2'b11  : CSRSelection = StackPointer;
                default: CSRSelection = 32'd0;
            endcase
        end
        assign CSRDataOut = CSRSelection;
    //                                                                       //
    //* Valid Action Assignments
        assign NextLinePushValid = BoundCheckVector[5];
        assign LinePushValid = BoundCheckVector[4];
        assign LineOnPushBounds = BoundCheckVector[3];
        assign NextLinePopValid = BoundCheckVector[2];
        assign LinePopValid = BoundCheckVector[1];
        assign LineOnPopBounds = BoundCheckVector[0];
    //                                                                       //
//?

endmodule : StackCache_PointerTracking
