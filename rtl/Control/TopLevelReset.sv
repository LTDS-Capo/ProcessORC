module TopLevelReset #(
    parameter RESETWAITCYCLES = 625000,
    parameter RESETCYCLELENGTH = 16,
    parameter OPERATIONALWAITCYCLES = 25000,
    parameter INITIALIZEWAITCYCLES = 1024,
    parameter CLOCKDOMAINS = 2
)(
    input sys_clk, // Connect your fastest clock to this
    input clk_en,
    input async_rst_in,

    input  clks [CLOCKDOMAINS-2:0], // Sys_clk is your highest clock input.

    input  sync_rst_trigger [CLOCKDOMAINS-1:0],

    output clk_en_out [CLOCKDOMAINS-1:0],
    output sync_rst_out [CLOCKDOMAINS-1:0],
    output init_out [CLOCKDOMAINS-1:0]
);
    
    // Flag Gen
        wire [CLOCKDOMAINS-1:0] sys_rst_trigger;
        wire sys_sync_rst_trigger = |sys_rst_trigger;
        wire sys_SyncIn [CLOCKDOMAINS-2:0];
        wire sys_clk_en_out;
        wire sys_sync_rst_out;
        wire sys_init_out;
        TopLevelReset_FlagGen #(
            .RESETWAITCYCLES      (RESETWAITCYCLES),
            .OPERATIONALWAITCYCLES(OPERATIONALWAITCYCLES),
            .INITIALIZEWAITCYCLES (INITIALIZEWAITCYCLES),
            .CLOCKDOMAINS         (CLOCKDOMAINS)
        ) FlagGen (
            .clk             (sys_clk),
            .clk_en          (clk_en),
            .sync_rst_in     (async_rst_in),
            .sync_rst_Trigger(sys_sync_rst_trigger),
            .SyncIn          (sys_SyncIn),
            .clk_en_out      (sys_clk_en_out),
            .sync_rst_out    (sys_sync_rst_out),
            .init_out        (sys_init_out)
        );
    //

    // Domain Control
        genvar DomainIndex;
        generate
            for (DomainIndex = 0; DomainIndex < CLOCKDOMAINS; DomainIndex = DomainIndex + 1) begin : DomainControlGen
                if (DomainIndex == (CLOCKDOMAINS-1)) begin
                    assign sys_rst_trigger[DomainIndex] = sync_rst_trigger[DomainIndex];
                    assign clk_en_out[DomainIndex] = sys_clk_en_out; // Needs latch
                    assign sync_rst_out[DomainIndex] = sys_sync_rst_out; // Needs cycle extender
                    assign init_out[DomainIndex] = sys_init_out;
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