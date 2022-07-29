// /* VALIDATED */
module TimerCell (
    input clk,
    input clk_en,
    input sync_rst,

    input TimeSet,
    input TimeCheck,
    input [15:0] WaitTime,

    output TimerElapsed,

    input [1:0] TESTIN
);
    reg  Active;
    wire ActiveTrigger = (TimeCheck && CountMatch && clk_en) || (TimeSet && clk_en) || sync_rst;
    wire NextActive = TimeSet && ~sync_rst;
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            Active <= NextActive;
        end
    end    

    reg   [15:0] CycleCount;
    wire         CountMatch = CycleCount == 0;
    wire         CycleCountTrigger = (TimeSet && clk_en) || (Active && clk_en) || sync_rst;
    logic [15:0] CycleCountNext;
    wire  [1:0] NextRegCondition;
    assign NextRegCondition[0] = ~TimeSet && Active && ~CountMatch && ~sync_rst;
    assign NextRegCondition[1] = TimeSet && ~sync_rst;
    always_comb begin : NextRegMux
        case (NextRegCondition)
            2'b01  : CycleCountNext = CycleCount - 1;
            2'b10  : CycleCountNext = WaitTime;
            default: CycleCountNext = 0; // Default is also case 0
        endcase
    end
    always_ff @(posedge clk) begin
        if (CycleCountTrigger) begin
            CycleCount <= CycleCountNext;
        end
        //$display("Timer:Remaining - %0h:%0h", TESTIN, CycleCount);
    end

    assign TimerElapsed = TimeCheck && CountMatch;

endmodule