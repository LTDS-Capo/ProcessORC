module StackCache_PointerTracking #(
    parameter LINESIZE = 8,
    parameter ADDRESS_BITWIDTH = 32
)(
    input  clk,
    input  clk_en,
    input  sync_rst,

    input         Speculating, //TODO
    input         EndSpeculationPulse, //TODO
    input         MispredictedSpeculationPulse, //TODO
    output        SpeculativeCSRWriteStall, //TODO

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
    output        OverflowError,
    output        UnderflowError,

    output        PushingOut,
    output        PoppingOut,
    output        PrePopEnable,

    output        NextPushValid,
    output        PushValid,
    output        OnPushBounds,
    output        NextPopValid,
    output        PopValid,
    output        OnPopBounds
);


//? Stack Pointer
    //* Common Connections
        reg    [31:0] StackPointer;
        logic  [31:0] NextStackPointer;
    //* Push Checking
        localparam LINEADDRBITWIDTH = (LINESIZE == 1) ? 1 : $clog2(LINESIZE);
        wire          PushInvalidityCheck = OnPushBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b0}});
        wire          PushValid = PushEnable && ~PushInvalidityCheck;
        assign        OverflowError = PushEnable && PushInvalidityCheck;
    //* Pop Checking
        wire          PopInvalidityCheck = OnPopBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b1}});
        wire          PopValid = PopValid && ~PopInvalidityCheck;
        assign        UnderflowError = PushEnable && PopInvalidityCheck;
        wire          SwapValid = CSRAddr[1] && CSRAddr[0] && CSRWriteEnable && ~sync_rst;
    //* Next Stack Pointer
        wire    [1:0] NextStackPointerCondition;
        assign        NextStackPointerCondition[0] = PushValid || SwapValid;
        assign        NextStackPointerCondition[1] = PopValid || SwapValid;
        always_comb begin : NextStackPointerMux
            case (NextStackPointerCondition)
                2'b00  : NextStackPointer = 32'd0; // Default sync_rst output
                2'b01  : NextStackPointer = StackPointer - 32'd1; // Push
                2'b10  : NextStackPointer = StackPointer + 32'd1; // Pop
                2'b11  : NextStackPointer = StackPointerSwapIn; // Swap
                default: NextStackPointer = 0;
            endcase
        end
    //* Buffer
        wire StackPointerTrigger = sync_rst || (clk_en && CSRAddr[1] && CSRAddr[0] && CSRWriteEnable) || ();
        always_ff @(posedge clk) begin
            if (StackPointerTrigger) begin
                StackPointer <= NextStackPointer;
            end
        end
        assign PushingOut = PushEnable && ~OnPushBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b0}});
        assign PoppingOut = PopEnable && ~OnPopBounds && (StackPointer[LINEADDRBITWIDTH-1:0] == {LINEADDRBITWIDTH{1'b1}});
//?

//? PrePop
    //* Common Connections
        wire CSRMetaWriteTrigger = sync_rst || (clk_en && CSRWriteEnable && ~CSRAddr[1] && ~CSRAddr[0]);
    //* Status
        reg  PrePop;
        wire NextPrePop = ~sync_rst && CSRDataIn[10];
        always_ff @(posedge clk) begin
            if (CSRMetaWriteTrigger) begin
                PrePop <= NextPrePop;
            end
        end
        assign PrePopEnable = PrePop;
//?

//? Stack Upper Bounds
    //* Common Connections
    wire [31:0] NextBound = sync_rst ? 32'd0 : CSRDataIn;
    //* Buffer
    reg  [31:0] UpperBounds;
    wire UpperBoundsTrigger = sync_rst || (clk_en && CSRWriteEnable && ~CSRAddr[1] && CSRAddr[0]);
    always_ff @(posedge clk) begin
        if (UpperBoundsTrigger) begin
            UpperBounds <= NextBound;
        end
    end
//?

//? Stack Lower Bounds
    //* Buffer
    reg  [31:0] LowerBounds;
    wire LowerBoundsTrigger = sync_rst || (clk_en && CSRWriteEnable && CSRAddr[1] && ~CSRAddr[0]);
    always_ff @(posedge clk) begin
        if (LowerBoundsTrigger) begin
            LowerBounds <= NextBound;
        end
    end
//? 

//? Bound Checks
    //* Stack Pointer Offsetting
        wire   [31:0] RoundedDownStackPointer = {NextStackPointer[31:3], 3'd0};
        wire   [31:0] StackPointerPlus8 = RoundedDownStackPointer + 32'd8;
        wire   [31:0] StackPointerPlus16 = RoundedDownStackPointer + 32'd16;
        wire   [31:0] StackPointerSubtract8 = RoundedDownStackPointer - 32'd8;
        wire   [31:0] StackPointerSubtract16 = RoundedDownStackPointer - 32'd16;
    //* Checks
        wire NextPushValidCheck = StackPointerSubtract8 >= LowerBounds;
        wire PushValidCheck = StackPointerSubtract16 >= LowerBounds;
        wire OnPushBoundsCheck = RoundedDownStackPointer >= LowerBounds;
        wire NextPopValidCheck = StackPointerPlus16 <= UpperBounds;
        wire PopValidCheck = StackPointerPlus8 <= UpperBounds;
        wire OnPopBoundsCheck = RoundedDownStackPointer == UpperBounds;
    //* Buffer
        reg  [5:0] BoundCheckVector;
        wire [5:0] NextBoundCheckVector = sync_rst ? 0 : {NextPushValidCheck, PushValidCheck, OnPushBoundsCheck, NextPopValidCheck, PopValidCheck, OnPopBoundsCheck};
        always_ff @(posedge clk) begin
            if (StackPointerTrigger) begin
                BoundCheckVector <= NextBoundCheckVector;
            end
        end
//? 

//? Output Generation
    //* CSR Read 
        logic [31:0] CSRSelection;
        always_comb begin : CSRSelectionMux
            case (CSRAddr)
                2'b00  : CSRSelection = {21'd0, PrePop, 10'd0};
                2'b01  : CSRSelection = UpperBounds;
                2'b10  : CSRSelection = LowerBounds;
                2'b11  : CSRSelection = StackPointer;
                default: CSRSelection = 0;
            endcase
        end
        assign CSRDataOut = CSRSelection;
    //* Valid Action Assignments
        assign NextPushValid = BoundCheckVector[5];
        assign PushValid = BoundCheckVector[4];
        assign OnPushBounds = BoundCheckVector[3];
        assign NextPopValid = BoundCheckVector[2];
        assign PopValid = BoundCheckVector[1];
        assign OnPopBounds = BoundCheckVector[0];
//?























    //? Data Tracking
        //* Stack Pointer
            //TODO: ADD SPECULATION ROLLBACK TO POINTER - AND EVICTION
            wire [31:0] SwappedStackPointer;
            generate
                if (DATABITWIDTH > 32) begin
                    assign SwappedStackPointer = WritebackData[31:0];
                end
                else if (DATABITWIDTH <= 32) begin
                    localparam SPPADDINGBITWIDTH = (32-DATABITWIDTH)+1;
                    wire   [32:0] PaddedWriteback = {{SPPADDINGBITWIDTH{1'b0}}, WritebackData};
                    assign        SwappedStackPointer = PaddedWriteback[31:0];
                end
            endgenerate

            reg    [31:0] StackPointer;
            logic  [31:0] NextStackPointer;
            wire    [1:0] NextStackPointerCondition;
            assign        NextStackPointerCondition[0] = ReadEn || sync_rst;
            assign        NextStackPointerCondition[1] = StackPointerWriteEn || sync_rst;
            always_comb begin : NextStackPointerMux
                case (NextStackPointerCondition)
                    2'b00  : NextStackPointer = StackPointer + PushOffset; // Pushing
                    2'b01  : NextStackPointer = StackPointer + PopOffset; // Popping
                    2'b10  : NextStackPointer = SwappedStackPointer; // Swap
                    2'b11  : NextStackPointer = SwappedStackPointer; // Swap
                    default: NextStackPointer = 0;
                endcase
            end
            wire StackPointerTrigger = sync_rst || (clk_en && InstructionValid && ReadEn && ~WritingTo) || (clk_en && InstructionValid && ~ReadEn && WritingTo) || (clk_en && InstructionValid && StackPointerWriteEn);
            always_ff @(posedge clk) begin
                if (StackPointerTrigger) begin
                    StackPointer <= NextStackPointer;
                end
            end
            assign StackPointerOut = StackPointer;
        //

        //* Growth Direction
            reg  GrowthDirection;
            wire NextGrowthDirection = ~sync_rst && StackDirection;
            wire GrowthDirectionTrigger = sync_rst || (clk_en && DirectionWE);
            always_ff @(posedge clk) begin
                if (GrowthDirectionTrigger) begin
                    GrowthDirection <= NextGrowthDirection;
                end
            end
            wire   [31:0] PushOffset = {{31{~GrowthDirection}}, 1'b1};
            wire   [31:0] PopOffset = {{31{GrowthDirection}}, 1'b1};

            assign        StackOverflowException = ; // TODO
            assign        StackUnderflowException = ; // TODO
        //

        //* Stack Upper Bounds
            reg  [31:0] UpperBounds;
            wire [31:0] NextUpperBounds = sync_rst ? 0 : StackUpperBound;
            wire UpperBoundsTrigger = sync_rst || (clk_en && UpperBoundWE);
            always_ff @(posedge clk) begin
                if (UpperBoundsTrigger) begin
                    UpperBounds <= NextUpperBounds;
                end
            end
            
        //

        //* Stack Lower Bounds
            reg  [31:0] LowerBounds;
            wire [31:0] NextLowerBounds = sync_rst ? 0 : StackLowerBound;
            wire LowerBoundsTrigger = sync_rst || (clk_en && LowerBoundWE);
            always_ff @(posedge clk) begin
                if (LowerBoundsTrigger) begin
                    LowerBounds <= NextLowerBounds;
                end
            end
        //

    //?

endmodule : StackCache_PointerTracking