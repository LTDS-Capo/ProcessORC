module TopLevelReset #(
    parameter RESETWAITCYCLES = 625000,
    parameter RESETCYCLELENGTH = 16,
    parameter OPERATIONALWAITCYCLES = 25000,
    parameter INITIALIZEWAITCYCLES = 1024,
    parameter CLOCKDOMAINS = 3
)(
    input sys_clk, // Connect your fastest clock to this
    input clk_en,
    input async_rst_in,
    input async_rst_out,

    input  [CLOCKDOMAINS-2:0] clks, // Sys_clk is your highest clock input.

    input  [CLOCKDOMAINS-1:0] sync_rst_trigger,

    output  [CLOCKDOMAINS-1:0] clk_en_out,
    output  [CLOCKDOMAINS-1:0] sync_rst_out,
    output  [CLOCKDOMAINS-1:0] init_out,

    output TESTBIT
);
    assign TESTBIT = FLAGTESTBIT;
    // Flag Gen
        wire [CLOCKDOMAINS-1:0] sys_rst_trigger;
        wire sys_sync_rst_trigger = |sys_rst_trigger;
        wire sys_SyncIn [CLOCKDOMAINS-1:0];
        wire sys_clk_en_out;
        wire sys_sync_rst_out;
        wire sys_init_out;
        wire FLAGTESTBIT;
        TopLevelReset_FlagGen #(
            .RESETWAITCYCLES      (RESETWAITCYCLES),
            .OPERATIONALWAITCYCLES(OPERATIONALWAITCYCLES),
            .INITIALIZEWAITCYCLES (INITIALIZEWAITCYCLES),
            .CLOCKDOMAINS         (CLOCKDOMAINS)
        ) FlagGen (
            .clk             (sys_clk),
            .clk_en          (clk_en),
            .async_rst_in    (async_rst_in),
            .async_rst_out   (async_rst_out),
            .sync_rst_Trigger(sys_sync_rst_trigger),
            .SyncIn          (sys_SyncIn),
            .clk_en_out      (sys_clk_en_out),
            .sync_rst_out    (sys_sync_rst_out),
            .init_out        (sys_init_out),
            .TESTBIT         (FLAGTESTBIT)
        );
    //

    // Domain Control
        genvar DomainIndex;
        generate
            for (DomainIndex = 0; DomainIndex < CLOCKDOMAINS; DomainIndex = DomainIndex + 1) begin : DomainControlGen
                if (DomainIndex == (CLOCKDOMAINS-1)) begin
                    TopLevelReset_SysDomainControl #(
                        .RESETCYCLELENGTH(RESETCYCLELENGTH)
                    ) SysDomainControl (
                        .sys_clk                (sys_clk),
                        .clk_en                 (clk_en),
                        .async_rst_in           (async_rst_in),
                        .clk_en_sys             (sys_clk_en_out),
                        .sync_rst_sys           (sys_sync_rst_out),
                        .init_sys               (sys_init_out),
                        .sync_rst_trigger       (sys_rst_trigger[DomainIndex]),
                        .sync_response          (sys_SyncIn[DomainIndex]),
                        .target_clk             (sys_clk),
                        .target_sync_rst_trigger(sync_rst_trigger[DomainIndex]),
                        .target_clk_en          (clk_en_out[DomainIndex]),
                        .target_sync_rst        (sync_rst_out[DomainIndex]),
                        .target_init            (init_out[DomainIndex])
                    );
                    // assign sys_rst_trigger[DomainIndex] = sync_rst_trigger[DomainIndex];
                    // // clk_en - sys_clk domain
                    //     reg  clk_en_buffer;
                    //     wire clk_en_bufferTrigger = (sys_clk_en_out && clk_en) || sys_sync_rst_out;
                    //     wire Nextclk_en_buffer = sys_clk_en_out && ~sys_sync_rst_out;
                    //     always_ff @(posedge sys_clk or posedge async_rst_in) begin
                    //         if (async_rst_in) begin
                    //             clk_en_buffer <= 0;
                    //         end
                    //         else if (clk_en_bufferTrigger) begin
                    //             clk_en_buffer <= Nextclk_en_buffer;
                    //         end
                    //     end
                    //     assign clk_en_out[DomainIndex] = clk_en_buffer;
                    // assign sync_rst_out[DomainIndex] = sys_sync_rst_out;
                    // assign init_out[DomainIndex] = sys_init_out;
                end
                else begin
                    TopLevelReset_DomainControl #(
                        .RESETCYCLELENGTH(RESETCYCLELENGTH)
                    ) DomainControl (
                        .sys_clk                (sys_clk),
                        .clk_en                 (clk_en),
                        .async_rst_in           (async_rst_in),
                        .clk_en_sys             (sys_clk_en_out),
                        .sync_rst_sys           (sys_sync_rst_out),
                        .init_sys               (sys_init_out),
                        .sync_rst_trigger       (sys_rst_trigger[DomainIndex]),
                        .sync_response          (sys_SyncIn[DomainIndex]),
                        .target_clk             (clks[DomainIndex]),
                        .target_sync_rst_trigger(sync_rst_trigger[DomainIndex]),
                        .target_clk_en          (clk_en_out[DomainIndex]),
                        .target_sync_rst        (sync_rst_out[DomainIndex]),
                        .target_init            (init_out[DomainIndex])
                    );
                end
            end
        endgenerate
    //

endmodule