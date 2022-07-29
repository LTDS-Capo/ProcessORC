//             //
// *VALIDATED* //
//             //
module TopLevelReset_DomainControl #(
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

    // sys to target CDC
    // > clk_en_trigger, sync_rst_trigger, init_trigger
        wire       SysToTargetWriteTrigger = clk_en_sys || sync_rst_sys || init_sys;
        wire [2:0] SysToTargetDataIn = {clk_en_sys, sync_rst_sys, init_sys};
        wire [2:0] SysToTargetDataOut;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(3),
            .DEPTH(8),
            .TESTENABLE(0)
        ) CDC_SysToTarget (
            .rst    (async_rst_in),
            .w_clk  (sys_clk),
            .dInACK (SysToTargetWriteTrigger),
            .dInREQ (), // Do Not Connect
            .dIN    (SysToTargetDataIn),
            .r_clk  (target_clk),
            .dOutACK(), // Do Not Connect
            .dOutREQ(clk_en),
            .dOUT   (SysToTargetDataOut)
        );

    // target_init Output Buffer
        reg  initOutputBuffer;
        wire initOutputBufferTrigger = clk_en;
        wire NextinitOutputBuffer = SysToTargetDataOut[0];
        always_ff @(posedge target_clk or posedge async_rst_in) begin
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
        wire NextResetDelay = SysToTargetDataOut[1];
        always_ff @(posedge target_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                ResetDelay <= 0;
            end
            else if (ResetDelayTrigger) begin
                ResetDelay <= NextResetDelay;
            end
        end

        reg  SyncRstActive;
        wire SyncRstActiveTrigger = (ResetCycleLimitMet && SyncRstActive && clk_en) || (SysToTargetDataOut[1] && clk_en) || (ResetDelay && clk_en);
        wire NextSyncRstActive = ~(ResetCycleLimitMet && SyncRstActive) && ~SysToTargetDataOut[1];
        always_ff @(posedge target_clk or posedge async_rst_in) begin
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
        always_ff @(posedge target_clk or posedge async_rst_in) begin
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
        wire clk_en_bufferTrigger = (SysToTargetDataOut[2] && clk_en) || target_sync_rst;
        wire Nextclk_en_buffer = SysToTargetDataOut[2] && ~target_sync_rst;
        always_ff @(posedge target_clk or posedge async_rst_in) begin
            if (async_rst_in) begin
                clk_en_buffer <= 0;
            end
            else if (clk_en_bufferTrigger) begin
                clk_en_buffer <= Nextclk_en_buffer;
            end
        end
        assign target_clk_en = clk_en_buffer;
        wire target_clk_en_trigger = SysToTargetDataOut[2];
    //


    // target to sys CDC
    // > SyncResponse, sync_rst_trigger
        wire       target_sync_response = target_clk_en_trigger || target_init || sync_rst_end;
        wire       TargetToSysWriteTrigger = target_sync_response || target_sync_rst_trigger;
        wire [1:0] TargetToSysDataIn = {target_sync_response, target_sync_rst_trigger};
        wire [1:0] TargetToSysDataOut;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(2),
            .DEPTH(8),
            .TESTENABLE(0)
        ) CDC_TargetToSys (
            .rst    (async_rst_in),
            .w_clk  (target_clk),
            .dInACK (TargetToSysWriteTrigger),
            .dInREQ (), // Do Not Connect
            .dIN    (TargetToSysDataIn),
            .r_clk  (sys_clk),
            .dOutACK(), // Do Not Connect
            .dOutREQ(clk_en),
            .dOUT   (TargetToSysDataOut)
        );
        assign sync_response = TargetToSysDataOut[1];
        assign sync_rst_trigger = TargetToSysDataOut[0];
    //

endmodule