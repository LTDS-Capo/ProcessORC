module IOClkSelectionBuffer (
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input  [7:0]       divided_clks,
    input  [3:0] [1:0] divided_clk_sels,

    input        [2:0] ClockSelect,

    output              target_clk
);
    
    // clk Mux
        logic divided_clk_src_Tmp;
        wire [1:0] ClkMuxCondition = divided_clk_sels[2] ? divided_clk_sels[ClockSelect[1:0]] : ClockSelect[1:0];
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
        wire NextclkBuffer = divided_clks[ClockSelect] && ~sync_rst;
        always_ff @(posedge divided_clk_src) begin
            if (clkBufferTrigger) begin
                clkBuffer <= NextclkBuffer;
            end
        end
        assign target_clk = clkBuffer;
    //

endmodule