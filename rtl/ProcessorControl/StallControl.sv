module StallControl (
    input clk,
    input clk_en,
    input sync_rst,

    input  InstructionValid,

    input  BranchStallIn,
    input  RegisterStallIn,
    input  IssueCongestionStallIn,
    input  HaltStallIn,

    output Halted,
    output StallEn
);
    
    reg  BranchStallDelay;
    wire BranchStallDelayTrigger = clk_en || sync_rst;
    wire NextBranchStallDelay = InstructionValid && BranchStallIn && ~sync_rst;
    always_ff @(posedge clk) begin
        if (BranchStallDelayTrigger) begin
            BranchStallDelay <= NextBranchStallDelay;
        end
    end

    reg  HaltCapture;
    wire HaltCaptureTrigger = (~HaltCapture && clk_en) || sync_rst;
    wire NextHaltCapture = HaltStallIn && ~sync_rst;
    always_ff @(posedge clk) begin
        if (HaltCaptureTrigger) begin
            HaltCapture <= NextHaltCapture;
        end
    end

    assign Halted = HaltCapture;
    assign StallEn = BranchStallDelay || RegisterStallIn || IssueCongestionStallIn || HaltStallIn || HaltCapture;

endmodule