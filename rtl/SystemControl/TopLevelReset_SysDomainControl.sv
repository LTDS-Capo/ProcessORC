//             //
// *VALIDATED* //
//             //
module TopLevelReset_SysDomainControl #(
    parameter RESETCYCLELENGTH = 16
)(
    input sys_clk,
    input clk_en,
    input async_rst_in,

    // sys_clk inputs
    input  clk_en_sys,
    input  sync_rst_sys,
    input  init_sys,
    // sys_clk outputs
    output sync_rst_trigger,
    output sync_response,

    // target_clk inputs
    input  target_clk,
    input  target_sync_rst_trigger,
    // target_clk outputs
    output target_clk_en,
    output target_sync_rst,
    output target_init
);

    // target_init Output Buffer
        reg  initOutputBuffer;
        wire initOutputBufferTrigger = clk_en;
        wire NextinitOutputBuffer = init_sys;
        always_ff @(posedge sys_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                initOutputBuffer <= 0;
            end
            else if (initOutputBufferTrigger) begin
                initOutputBuffer <= NextinitOutputBuffer;
            end
        end
        assign target_init = initOutputBuffer;
    //

    // sync_rst pulse extender
        reg  ResetDelay;
        wire ResetDelayTrigger = clk_en;
        wire NextResetDelay = sync_rst_sys;
        always_ff @(posedge sys_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                ResetDelay <= 0;
            end
            else if (ResetDelayTrigger) begin
                ResetDelay <= NextResetDelay;
            end
        end

        reg  SyncRstActive;
        wire SyncRstActiveTrigger = (ResetCycleLimitMet && SyncRstActive && clk_en) || (sync_rst_sys && clk_en) || (ResetDelay && clk_en);
        wire NextSyncRstActive = ~(ResetCycleLimitMet && SyncRstActive) && ~sync_rst_sys;
        always_ff @(posedge sys_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                SyncRstActive <= 0;
            end
            else if (SyncRstActiveTrigger) begin
                SyncRstActive <= NextSyncRstActive;
            end
        end

        localparam RSTCOUNTBITWIDTH = (RESETCYCLELENGTH == 1) ? 1 : $clog2(RESETCYCLELENGTH);
        reg  [RSTCOUNTBITWIDTH:0] ResetCycleCount;
        wire                        ResetCycleCountTrigger = (ResetDelay && clk_en) || (SyncRstActive && clk_en);
        wire [RSTCOUNTBITWIDTH:0] NextResetCycleCount = ResetDelay ? 0 : (ResetCycleCount + 1);
        always_ff @(posedge sys_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                ResetCycleCount <= 0;
            end
            else if (ResetCycleCountTrigger) begin
                ResetCycleCount <= NextResetCycleCount;
            end
        end
        wire ResetCycleLimitMet = ResetCycleCount == (RESETCYCLELENGTH - 1);

        assign target_sync_rst = SyncRstActive;// && ~ResetCycleLimitMet;
        wire sync_rst_end = SyncRstActive && ResetCycleLimitMet;
    //

    // clk_en buffer
        reg  clk_en_buffer;
        wire clk_en_bufferTrigger = (clk_en_sys && clk_en) || target_sync_rst;
        wire Nextclk_en_buffer = clk_en_sys && ~target_sync_rst;
        always_ff @(posedge sys_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                clk_en_buffer <= 0;
            end
            else if (clk_en_bufferTrigger) begin
                clk_en_buffer <= Nextclk_en_buffer;
            end
        end
        assign target_clk_en = clk_en_buffer;
        wire target_clk_en_trigger = clk_en_sys;
    //

    // Response Assignments
        wire target_sync_response = target_clk_en_trigger || target_init || sync_rst_end;
        reg  SyncDelayBuffer;
        wire SyncDelayBufferTrigger = clk_en;
        wire NextSyncDelayBuffer = target_sync_response;
        always_ff @(posedge sys_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                SyncDelayBuffer <= 0;
            end
            else if (SyncDelayBufferTrigger) begin
                SyncDelayBuffer <= NextSyncDelayBuffer;
            end
        end
        assign sync_response = SyncDelayBuffer;
        assign sync_rst_trigger = target_sync_rst_trigger;
    //

endmodule