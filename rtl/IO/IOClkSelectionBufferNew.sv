module IOClkSelectionBufferNew (
    input sys_clk, // 125m
    input clk_en,
    input sync_rst,

    input src_clk,

    input  [7:0]       divided_clks,
    input  [3:0] [1:0] divided_clk_sels,

    input              ClockUpdate,
    input        [2:0] ClockSelect,

    output             target_clk
);

    // Clock Select Buffer
        reg  [2:0] ClockSelectBuffer;
        wire       ClockSelectBufferTrigger = (ClockUpdate && clk_en) || sync_rst;
        wire [2:0] NextClockSelectBuffer = (sync_rst) ? '0 : ClockSelect;
        always_ff @(posedge src_clk) begin
            if (ClockSelectBufferTrigger) begin
                ClockSelectBuffer <= NextClockSelectBuffer;
            end
        end
    //

    assign target_clk = divided_clks[ClockSelectBuffer];

endmodule