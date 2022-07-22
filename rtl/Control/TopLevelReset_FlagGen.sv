module TopLevelReset_FlagGen #(
    parameter RESETWAITCYCLES = 625000,
    parameter OPERATIONALWAITCYCLES = 25000,
    parameter INITIALIZEWAITCYCLES = 1024,
    parameter CLOCKDOMAINS = 3
)(
    input clk,
    input clk_en,
    input sync_rst_in,

    input sync_rst_Trigger,

    input SyncIn [CLOCKDOMAINS-2:0],

    output clk_en_out,
    output sync_rst_out,
    output init_out
);
    
    localparam CYCLELIMIT = RESETWAITCYCLES + OPERATIONALWAITCYCLES + INITIALIZEWAITCYCLES + 1;
    localparam OPERATIONALCYCLELIMIT =  RESETWAITCYCLES + OPERATIONALWAITCYCLES;
    localparam RESETCYCLELIMIT = RESETWAITCYCLES;
    wire CycleLimitReached = (NextCycleCount == CYCLELIMIT) && clk_en;
    wire OperationalLimitReached = (CycleCount == OPERATIONALCYCLELIMIT) && clk_en;
    wire ResetLimitReached = (CycleCount == RESETCYCLELIMIT) && clk_en;
    localparam CYCLEBITWIDTH = $clog2(CYCLELIMIT);

    // sync_rst_in Trigger
        reg  [7:0] AsyncRstCapture;
        wire       AsyncRstCaptureTrigger = clk_en;
        wire       AsyncRstDetection = ~(|AsyncRstCapture);
        wire [7:0] NextAsyncRstCapture;
        assign NextAsyncRstCapture[0] = AsyncRstDetection;
        assign NextAsyncRstCapture[1] = AsyncRstCapture[0] || AsyncRstDetection;
        assign NextAsyncRstCapture[2] = AsyncRstCapture[1] || AsyncRstDetection;
        assign NextAsyncRstCapture[3] = AsyncRstCapture[2] || AsyncRstDetection;
        assign NextAsyncRstCapture[4] = AsyncRstCapture[3];
        assign NextAsyncRstCapture[5] = AsyncRstCapture[4];
        assign NextAsyncRstCapture[6] = AsyncRstCapture[5];
        assign NextAsyncRstCapture[7] = AsyncRstCapture[6];
        always_ff @(posedge clk or posedge sync_rst_in) begin
            if (sync_rst_in) begin
                AsyncRstCapture <= 0;
            end
            else if (AsyncRstCaptureTrigger) begin
                AsyncRstCapture <= NextAsyncRstCapture;
            end
        end
        wire AsyncRstTrigger = AsyncRstCapture[6] && ~AsyncRstCapture[7];    
    //  

    // sync_rst Trigger
        reg    syncRstCapture;
        wire   syncRstCaptureTrigger = clk_en;
        wire   NextsyncRstCapture = sync_rst_Trigger;
        always_ff @(posedge clk or posedge sync_rst_in) begin
            if (sync_rst_in) begin
                syncRstCapture <= 0;
            end
            else if (syncRstCaptureTrigger) begin
                syncRstCapture <= NextsyncRstCapture;
            end
        end
        wire syncRstTrigger = syncRstCapture;
    //


    // CycleCount Active
    reg  CountActive;
    wire CountActiveTrigger = (sync_rst_Trigger && clk_en) || (AsyncRstTrigger && clk_en) || (syncRstTrigger && clk_en);
    wire NextCountActive = (AsyncRstTrigger || syncRstTrigger) && ~sync_rst_Trigger;
    always_ff @(posedge clk or posedge sync_rst_in) begin
        if (sync_rst_in) begin
            CountActive <= 0;
        end
        else if (CountActiveTrigger) begin
            CountActive <= NextCountActive;
        end
    end
    // Cycle Counter
    reg  [CYCLEBITWIDTH+1:0] CycleCount;
    wire                     CycleCountTrigger = (sync_rst_Trigger && clk_en) || (CountActive && ~SyncWait && ~CycleLimitReached && clk_en);
    wire [CYCLEBITWIDTH+1:0] NextCycleCount = sync_rst_Trigger ? 0 : CycleCount + 1;
    always_ff @(posedge clk or posedge sync_rst_in) begin
        if (sync_rst_in) begin
            CycleCount <= 0;
        end
        else if (CycleCountTrigger) begin
            CycleCount <= NextCycleCount;
        end
    end

    // Syncronization Registers
        wire [CLOCKDOMAINS-1:0] SyncVector;
        genvar SyncIndex;
        generate
            for (SyncIndex = 0; SyncIndex < CLOCKDOMAINS; SyncIndex = SyncIndex + 1) begin : SyncBufferGen
                if (SyncIndex == (CLOCKDOMAINS-1)) begin
                    assign SyncVector[SyncIndex] = 1'b1;
                end
                else begin
                    reg  SyncBuffer;
                    wire SyncBufferTrigger = (SyncClear && clk_en) || (SyncIn[SyncIndex] && SyncWait && clk_en) || (sync_rst_Trigger && clk_en);
                    wire NextSyncBuffer = SyncIn[SyncIndex] && ~SyncClear && ~sync_rst_Trigger;
                    always_ff @(posedge clk) begin
                        if (SyncBufferTrigger) begin
                            SyncBuffer <= NextSyncBuffer;
                        end
                    end
                    assign SyncVector[SyncIndex] = SyncBuffer;
                end
            end
        endgenerate
        // Sync Clear
        wire SyncClear = (&SyncVector) && SyncWait;
        // Sync Wait
        reg  SyncWait;
        wire SyncWaitTrigger = (SyncClear && clk_en) || (ResetLimitReached && clk_en) || (OperationalLimitReached && clk_en) || (sync_rst_Trigger && clk_en);
        wire NextSyncWait = (ResetLimitReached || OperationalLimitReached) && ~SyncClear && ~sync_rst_Trigger;
        always_ff @(posedge clk or posedge sync_rst_in) begin
            if (sync_rst_in) begin
                SyncWait <= 0;
            end
            else if (SyncWaitTrigger) begin
                SyncWait <= NextSyncWait;
            end
        end
    //

    // Output Assignment
        reg  InitPulseLimit;
        wire InitPulseLimitTrigger = (CycleLimitReached && clk_en) || (sync_rst_Trigger && clk_en);
        wire NextInitPulseLimit = CycleLimitReached && ~sync_rst_Trigger;
        always_ff @(posedge clk or posedge sync_rst_in) begin
            if (sync_rst_in) begin
                InitPulseLimit <= 0;
            end
            else if (InitPulseLimitTrigger) begin
                InitPulseLimit <= NextInitPulseLimit;
            end
        end
        assign clk_en_out = CountActive && OperationalLimitReached;
        assign sync_rst_out = CountActive && ResetLimitReached;
        assign init_out = CycleLimitReached && ~InitPulseLimit;
    //

endmodule