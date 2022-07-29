// /* VALIDATED */
module Timers (
    input clk,
    input clk_en,
    input sync_rst,

    input  [1:0]  TimerAddr,
    input         TimerCheck,
    input         TimerSet,
    input  [15:0] WaitTime,

    output TimerElapsed
);
    
    logic [3:0] TimeSelect;
    always_comb begin : TimeSelectMux
        case (TimerAddr)
            2'b01  : TimeSelect = 4'b0010; 
            2'b10  : TimeSelect = 4'b0100; 
            2'b11  : TimeSelect = 4'b1000; 
            default: TimeSelect = 4'b0001;
        endcase
    end

    genvar i;
    wire [3:0] TimeElapsedVector;
    generate
        for (i = 0; i < 4; i = i + 1) begin : TimerArray
            wire LocalTimeSet = TimeSelect[i] && TimerSet;
            wire LocalTimeCheck = TimeSelect[i] && TimerCheck;
            TimerCell TimerCellTest (
                .clk         (clk),
                .clk_en      (clk_en),
                .sync_rst    (sync_rst),
                .TimeSet     (LocalTimeSet),
                .TimeCheck   (LocalTimeCheck),
                .WaitTime    (WaitTime),
                .TimerElapsed(TimeElapsedVector[i]),
                .TESTIN(i)
            );
        end
    endgenerate

    assign TimerElapsed = |TimeElapsedVector;

endmodule