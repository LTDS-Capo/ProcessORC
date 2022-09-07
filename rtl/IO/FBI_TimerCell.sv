module FBI_TimerCell #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,
    input sync_rst,

    input              [31:0] CounterIn,

    input                     TimerInACK,
    output                    TimerInREQ,
    input              [31:0] ComparisonValueIn,
    input               [3:0] MinorOpcodeIn,
    input  [DATABITWIDTH-1:0] CommandAddressIn,
    input               [3:0] RegisterDestIn,
    input                     TimerSet,
    input                     TimerClear,
    input                     TimerCheck,
    input                     TimerWait,

    output                    TimerOutACK,
    input                     TimerOutREQ,
    output [DATABITWIDTH-1:0] TimerDataOut, // TODO: Load Alignment
    output              [3:0] RegisterDestOut
);
    
    // Active
        reg  Active;
        wire ActiveTrigger = (TimerElapsed && clk_en) || (TimerClear && TimerInACK && clk_en) || (TimerSet && TimerInACK && clk_en) || sync_rst;
        wire NextActive = TimerSet && ~sync_rst;
        always_ff @(posedge clk) begin
            if (ActiveTrigger) begin
                Active <= NextActive;
            end
        end
    //

    // Comparison Register
        reg  [31:0] ComparisonValue;
        wire        ComparisonValueTrigger = (TimerSet && TimerInACK && clk_en) || sync_rst;
        wire [31:0] NextComparisonValue = (sync_rst) ? 0 : ComparisonValueIn;
        always_ff @(posedge clk) begin
            if (ComparisonValueTrigger) begin
                ComparisonValue <= NextComparisonValue;
            end
        end
        wire TimerElapsed = (ComparisonValue[31:0] == CounterIn[31:0]) && Active;
    //

    // Wait Buffer
        reg  WaitBuffer;
        wire WaitBufferTrigger = (TimerElapsed && clk_en) || (~WaitBuffer && TimerWait && Active && TimerInACK && clk_en) || sync_rst;
        wire NextWaitBuffer = ~WaitBuffer && TimerWait && ~sync_rst;
        always_ff @(posedge clk) begin
            if (WaitBufferTrigger) begin
                WaitBuffer <= NextWaitBuffer;
            end
        end
        reg  [3:0] RegDestBuffer;
        wire [3:0] NextRegDestBuffer = (sync_rst || TimerElapsed) ? '0 : RegisterDestIn;
        always_ff @(posedge clk) begin
            if (WaitBufferTrigger) begin
                RegDestBuffer <= NextRegDestBuffer;
            end
        end
    //

    // Output Control
        reg  ACKOutWait;
        wire TimerACKCondition = (TimerCheck && TimerInREQ && TimerInACK && clk_en) || (TimerWait && ~Active && TimerInREQ && TimerInACK && clk_en) || (TimerElapsed && WaitBuffer && clk_en);
        wire ACKOutWaitTrigger = (TimerOutACK && TimerOutREQ && clk_en) || TimerACKCondition || sync_rst;
        // wire NextACKOutWait = ~ACKOutWait && ~sync_rst;
        wire NextACKOutWait = (TimerCheck || TimerWait) && ~sync_rst;
        always_ff @(posedge clk) begin
            if (ACKOutWaitTrigger) begin
                ACKOutWait <= NextACKOutWait;
            end
        end
        // Output Data ACK Buffer
        reg  [31:0] OutputDataBuffer;
        wire        OutputDataBufferTrigger = TimerACKCondition || sync_rst;
        wire [31:0] TempTimerDifference = CounterIn - ComparisonValue;
        wire [31:0] NextOutputDataBuffer = (TimerCheck && Active) ? TempTimerDifference : '0;
        always_ff @(posedge clk) begin
            if (OutputDataBufferTrigger) begin
                OutputDataBuffer <= NextOutputDataBuffer;
            end
        end
        // Register Dest ACK Buffer
        reg   [3:0] RegDestACKBuffer;
        logic [3:0] NextRegDestACKBuffer;
        wire  [1:0] NextDestCondition;
        assign NextDestCondition[0] = WaitBuffer && TimerElapsed && ~sync_rst;
        assign NextDestCondition[1] = sync_rst;
        always_comb begin : NextDestMux
            case (NextDestCondition)
                2'b01  : NextRegDestACKBuffer = RegDestBuffer;
                2'b10  : NextRegDestACKBuffer = '0;
                2'b11  : NextRegDestACKBuffer = '0;
                default: NextRegDestACKBuffer = RegisterDestIn; // Default is also case 0
            endcase
        end
        always_ff @(posedge clk) begin
            if (OutputDataBufferTrigger) begin
                RegDestACKBuffer <= NextRegDestACKBuffer;
            end
        end
        // Output Assignments
        assign TimerInREQ = ~(TimerElapsed && WaitBuffer) && ~(WaitBuffer && TimerWait) && ~ACKOutWait;
        assign TimerOutACK = ACKOutWait;
        // assign TimerDataOut = (TimerCheck && Active) ? OutputDataBuffer : '0;
        assign TimerDataOut = OutputDataBuffer;
        assign RegisterDestOut = RegDestACKBuffer;
    // 

endmodule