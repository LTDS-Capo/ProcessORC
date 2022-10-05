module IOClkSelectionBuffer (
    input sys_clk, // 125m
    input clk_en,
    input sync_rst,

    input src_clk0, // 100m
    input src_clk1, // 25m
    input src_clk2, // 2.5m

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
        always_ff @(posedge sys_clk) begin
            if (ClockSelectBufferTrigger) begin
                ClockSelectBuffer <= NextClockSelectBuffer;
            end
        end
    //

    // clk Mux
        logic divided_clk_src_Tmp;
        wire [1:0] ClkMuxCondition = divided_clk_sels[2] ? divided_clk_sels[ClockSelectBuffer[1:0]] : ClockSelectBuffer[1:0];
        always_comb begin : clk_mux
            case (ClkMuxCondition)
                2'b01  : divided_clk_src_Tmp = src_clk0;
                2'b10  : divided_clk_src_Tmp = src_clk1;
                2'b11  : divided_clk_src_Tmp = src_clk2;
                default: divided_clk_src_Tmp = sys_clk; // Default is also case 0
            endcase
        end
        wire divided_clk_src = divided_clk_src_Tmp;
    //

    // target_clk buffer and output assignment
        reg  clkBuffer;
        wire clkBufferTrigger = clk_en || sync_rst;
        wire NextclkBuffer = divided_clks[ClockSelectBuffer] && ~sync_rst;
        always_ff @(posedge divided_clk_src) begin
            if (clkBufferTrigger) begin
                clkBuffer <= NextclkBuffer;
            end
        end

        logic       target_clk_Tmp;
        always_comb begin : NextSOMETHINGMux
            casez (ClockSelectBuffer)
                3'b001 : target_clk_Tmp = divided_clks[1];
                3'b010 : target_clk_Tmp = divided_clks[2];
                3'b011 : target_clk_Tmp = divided_clks[3];
                3'b1?? : target_clk_Tmp = clkBuffer;
                default: target_clk_Tmp = divided_clks[0]; // Default is also case 0
            endcase
        end
        // assign target_clk = target_clk_Tmp;
        assign target_clk = sys_clk; // Temporarily disable everything here
    //

endmodule