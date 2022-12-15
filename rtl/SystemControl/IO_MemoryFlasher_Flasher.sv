module IO_MemoryFlasher_Flasher #(
    parameter MEMMAPSTARTADDR = 384,
    parameter MEMMAPENDADDR = 511
)(
    input clk,
    input clk_en,
    input sync_rst,

    input         FlashInit,

    input         SoftwareResetIn,
    input   [3:0] ResetVectorIn,
    output        ResetResponseOut,
    output        ResetTriggerOut,
    output        CPUResetLockoutOut, 
    output        IOResetLockoutOut,

    output        InstFlashEn,
    output        DataFlashEn,
    output  [9:0] FlashAddr,
    output [15:0] FlashDataOut,

    output        SystemEnable,

    output        FlashReadEn,
    input  [15:0] FlashDataIn

);

    // Reset Control
        // Type - Priority - VectorIndex - TargetState - Notes
        // FullReset - 1 - 3 - 11 - Submit Reset Trigger
        // InstReset - 2 - 2 - 01 - Flash Inst Memory, Submit Reset, Lockout Local Reset, Do Not Reply
        // IOReset   - 3 - 1 - 10 - Submit Reset, Lockout Local resets and CPU reset, Reply
        // DataReset - 4 - 0 - 11 - Flashes Fixed Memory, Reply 

        wire [1:0] DesiredState;
        wire FullReset = ResetVectorIn[3]; // // Buffer these locally // no
        wire InstReset = ResetVectorIn[2]; // // Buffer these locally // no
        wire IOReset   = ResetVectorIn[1]; // // Buffer these locally // no
        wire DataReset = ResetVectorIn[0]; // // Buffer these locally // no
        wire LocalSoftResetEn = InstReset || IOReset;
        assign DesiredState[0] = FullReset || IOReset || InstReset;
        assign DesiredState[1] = FullReset || IOReset || DataReset;
        wire LocalSyncRst = sync_rst && ~LocalResetBlock;

        // Reset State
        reg   [1:0] ResetBuffer;
        logic [2:0] ResetStateVector;
        always_comb begin : ResetStateMux // Make it so IO reset is blocked when doing Inst flash only
            case (ResetBuffer)
                2'b00  : ResetStateVector = {SoftwareResetIn, DesiredState} /* synthesis syn_keep=1 */; // Idle
                2'b01  : ResetStateVector = {NextFlashAddress[10], 1'b1, ~DataReset} /* synthesis syn_keep=1 */; // Flash Inst
                2'b10  : ResetStateVector = {NextFlashAddress[11], LocalSoftResetEn, LocalSoftResetEn} /* synthesis syn_keep=1 */; // Flash Data
                2'b11  : ResetStateVector = {(~ResetResponseDetection && ResponseEn), 2'b00} /* synthesis syn_keep=1 */; // Submit Reset
                default: ResetStateVector = '0; // Default is also case 0
            endcase  /* synthesis syn_preserve=1 */
        end
        wire       ResetBufferTrigger = (ResetStateVector[2] && clk_en) || LocalSyncRst;
        wire [1:0] NextResetBuffer = LocalSyncRst ? '0 : ResetStateVector[1:0];
        always_ff @(posedge clk) begin
            if (ResetBufferTrigger) begin
                ResetBuffer <= NextResetBuffer;
            end
        end
        reg  ResponseEn;
        wire ResponseEnTrigger = (ResetStateVector[2] && clk_en) || (ResetBuffer[1] && ResetBuffer[0] && clk_en) || LocalSyncRst;
        wire NextResponseEn = ~ResetBufferTrigger && ~LocalSyncRst;
        always_ff @(posedge clk) begin
            if (ResponseEnTrigger) begin
                ResponseEn <= NextResponseEn;
            end
        end
        reg  ResetResponseDetection;
        wire ResetResponseDetectionTrigger = (CPUResetLockoutOut && clk_en) || (LocalResetBlock && clk_en) || FlashInit || LocalSyncRst;
        wire NextResetResponseDetection = ~FlashInit && ~LocalSyncRst;
        always_ff @(posedge clk) begin
            if (ResetResponseDetectionTrigger) begin
                ResetResponseDetection <= NextResetResponseDetection;
            end
        end
        wire   LocalResetBlock = ResetBuffer[1] && ResetBuffer[0] && (IOReset || InstReset);
        assign CPUResetLockoutOut = ResetBuffer[1] && ResetBuffer[0] && ~InstReset && ~FullReset;
        assign IOResetLockoutOut = ResetBuffer[1] && ResetBuffer[0] && ~IOReset && ~FullReset;
        assign ResetResponseOut = ResetStateVector[2] && ~ResetStateVector[1] && ~ResetStateVector[0];
        wire   ResetInstFlash = ResetStateVector[2] && ~ResetStateVector[1] && ResetStateVector[0];
        wire   ResetDataFlash = ResetStateVector[2] && ResetStateVector[1] && ~ResetStateVector[0];
        assign ResetTriggerOut = ResetStateVector[2] && ResetStateVector[1] && ResetStateVector[0];
    //

    // Active Register
        reg  [1:0] Active;
        wire       FlashInit_Tmp = FlashInit && ~LocalResetBlock;
        wire       ActiveTrigger = (FlashFinished && clk_en) || (FlashInit_Tmp && clk_en) || (ResetInstFlash && clk_en) || (ResetDataFlash && clk_en) || LocalSyncRst;
        wire       FlashFinished = FlashAddress[11] || (NextFlashAddress[10] && ~DataReset);
        wire [1:0] NextActive;
        assign     NextActive[0] = (FlashInit_Tmp && ~FlashFinished && ~LocalSyncRst) || (ResetInstFlash && ~LocalSyncRst) || (ResetDataFlash && ~LocalSyncRst);
        assign     NextActive[1] = FlashFinished && ~ResetInstFlash && ~LocalSyncRst;
        always_ff @(posedge clk) begin
            if (ActiveTrigger) begin
                Active[0] <= NextActive[0];
                Active[1] <= NextActive[1];
            end
        end
    //

    // Powered Up
        reg  PoweredUp;
        wire PoweredUpTrigger = (FlashFinished && clk_en) || LocalSyncRst;
        wire NextPoweredUp = Active[1] && ~LocalSyncRst;
        always_ff @(posedge clk) begin
            if (PoweredUpTrigger) begin
                PoweredUp <= NextPoweredUp;
            end
        end
    //

    // Address Generation
    reg   [11:0] FlashAddress;
    wire         FlashAddressTrigger = (Active[0] && clk_en) || LocalSyncRst || ResetInstFlash || FlashInit_Tmp || ResetDataFlash;
    logic [11:0] NextFlashAddress;
    wire   [1:0] NextFlashAddressCondition;
    wire   [9:0] MemMapStart = MEMMAPSTARTADDR;
    wire   [9:0] MemMapEnd = MEMMAPENDADDR + 1;
    wire  [11:0] MemMapCompareAddr = {2'b01, MemMapStart};
    wire         MemMapSkipTrigger = (FlashAddress == MemMapCompareAddr);
    assign NextFlashAddressCondition[0] = Active[0] && (~FlashAddress[10] || MemMapSkipTrigger) && ~LocalSyncRst && ~ResetInstFlash && ~FlashInit_Tmp && ~ResetDataFlash;
    assign NextFlashAddressCondition[1] = FlashAddress[10] && ~LocalSyncRst && ~ResetInstFlash && ~FlashInit_Tmp && ~ResetDataFlash;
    always_comb begin : NextFlashAddressMux
        case (NextFlashAddressCondition)
            2'b00  : NextFlashAddress = {1'b0, (ResetDataFlash && ~LocalSyncRst), 10'b0};
            2'b01  : NextFlashAddress = FlashAddress + 1;
            2'b10  : NextFlashAddress = FlashAddress + 2;
            2'b11  : NextFlashAddress = {FlashAddress[11:10] , MemMapEnd};
            default: NextFlashAddress =  {1'b0, ResetDataFlash, 10'b0}; // Default is also case 0
        endcase
    end
    always_ff @(posedge clk) begin
        if (FlashAddressTrigger) begin
            FlashAddress <= NextFlashAddress;
        end
    end

    // Instruction ROM
    wire [15:0] CurrentInstruction;
    FlashROM_Instruction InstROM (
        .Address(FlashAddress[9:0]),
        .Value  (CurrentInstruction)
    );

    // Data ROM
    wire [15:0] CurrentData;
    FlashROM_Data DataROM (
        .Address(FlashAddress[9:0]),
        .Value  (CurrentData)
    );

    logic [15:0] FlashDataOut_Tmp;
    wire   [1:0] FlashDataCondition = {PoweredUp, FlashAddress[10]};
    always_comb begin : NextSOMETHINGMux
        case (FlashDataCondition)
            2'b00  : FlashDataOut_Tmp = CurrentInstruction;
            2'b01  : FlashDataOut_Tmp = CurrentData;
            2'b10  : FlashDataOut_Tmp = FlashDataIn;
            2'b11  : FlashDataOut_Tmp = FlashDataIn;
            default: FlashDataOut_Tmp = '0; // Default is also case 0
        endcase
    end

    // Flashing Output Assignments
    assign SystemEnable = Active[1];
    assign FlashAddr = FlashAddress[9:0];
    assign FlashDataOut = FlashDataOut_Tmp;
    assign FlashReadEn = Active[0] && ~FlashFinished;
    assign InstFlashEn = Active[0] && ~FlashAddress[10] && ~FlashFinished;
    assign DataFlashEn = Active[0] && FlashAddress[10] && ~FlashFinished;

endmodule