module StallControl (
    input clk,
    input clk_en,
    input sync_rst,

    input  InstructionValid,

    input  BranchStallIn,
    input  RegisterStallIn,
    input  IssueCongestionStallIn,

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

    assign StallEn = BranchStallDelay || RegisterStallIn || IssueCongestionStallIn;

endmodule