module SystemControl (
    input clk,
    input clk_en,
    input sync_rst,

    input  InstructionValid,
    input  [3:0] BAddrIn,
    input  [3:0] MinorOpcodeIn,
    input  [4:0] FunctionalUnitEnable,
    output       SoftwareResetOut,
    output [3:0] ResetVectorOut,
    input        ResetResponseIn,

    input  BranchStallIn,
    input  RegisterStallIn,
    input  IssueCongestionStallIn,
    input  HaltStallIn,

    output BranchStallDisable,
    output Halted,
    output StallEn
);

    // Reset Control
        wire ResetEn   = (MinorOpcodeIn == 4'hE) && FunctionalUnitEnable[2] && InstructionValid;
        // wire FullReset = BAddrIn[3];
        // wire InstReset = BAddrIn[2]; // Stall [Clears on reset]
        // wire IOReset   = BAddrIn[1]; // Stall [Clears on reply]
        // wire DataReset = BAddrIn[0]; // Stall [Clears on reply]
        reg  [4:0] ResetVectorBuffer;
        wire       ResetVectorBufferTrigger = (ResetResponseIn && clk_en) || (ResetEn && clk_en) || sync_rst;
        wire [4:0] NextResetVectorBuffer = (sync_rst || ResetResponseIn) ? '0 : {ResetEn, BAddrIn};
        always_ff @(posedge clk) begin
            if (ResetVectorBufferTrigger) begin
                ResetVectorBuffer <= NextResetVectorBuffer;
            end
        end
        reg  ResetEnPulseLimit;
        wire ResetEnPulseLimitTrigger = clk_en || sync_rst;
        wire NextResetEnPulseLimit = ResetVectorBuffer[4] && ~sync_rst;
        always_ff @(posedge clk) begin
            if (ResetEnPulseLimitTrigger) begin
                ResetEnPulseLimit <= NextResetEnPulseLimit;
            end
        end
        // assign SoftwareResetOut = ResetVectorBuffer[4] && ~ResetEnPulseLimit && InstructionValid;
        assign SoftwareResetOut = ResetVectorBuffer[4] && ~ResetEnPulseLimit;
        // assign ResetVectorOut = InstructionValid ? ResetVectorBuffer[3:0] : '0;
        assign ResetVectorOut = ResetVectorBuffer[3:0];

        reg  ResetStall;
        wire ResetStallEn = |ResetVectorBuffer[2:0];
        wire ResetStallTrigger = (ResetResponseIn && clk_en) || (ResetStallEn && InstructionValid && clk_en) || sync_rst;
        wire NextResetStall = ~ResetResponseIn && ~sync_rst;
        always_ff @(posedge clk) begin
            if (ResetStallTrigger) begin
                ResetStall <= NextResetStall;
            end
        end
    //
    
    // Stall Control
        reg  BranchStallDelay;
        wire BranchStallDelayTrigger = clk_en || sync_rst;
        wire NextBranchStallDelay = InstructionValid && BranchStallIn && ~sync_rst;
        always_ff @(posedge clk) begin
            if (BranchStallDelayTrigger) begin
                BranchStallDelay <= NextBranchStallDelay;
            end
        end
        assign BranchStallDisable = BranchStallDelay;
        assign StallEn = ResetVectorBuffer[4] || ResetStall || BranchStallDelay || RegisterStallIn || IssueCongestionStallIn || HaltStallIn || HaltCapture;
    //

    // Halt Control
        reg  HaltCapture;
        wire HaltCaptureTrigger = (~HaltCapture && clk_en) || sync_rst;
        wire NextHaltCapture = HaltStallIn && ~sync_rst;
        always_ff @(posedge clk) begin
            if (HaltCaptureTrigger) begin
                HaltCapture <= NextHaltCapture;
            end
        end
        assign Halted = HaltCapture;
    //

endmodule