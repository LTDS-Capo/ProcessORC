module CommandTimers_Cell #(
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
    output [DATABITWIDTH-1:0] TimerDataOut,
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
        reg  WaitHoldBuffer;
        wire WaitHoldBufferTrigger = (WaitACK && TimerOutREQ && TimerOutACK && clk_en) || (~WaitHoldBuffer && Active && TimerWait && TimerInREQ && TimerInACK) || sync_rst;
        wire NextWaitHoldBuffer = TimerWait && ~sync_rst;
        always_ff @(posedge clk) begin
            if (WaitHoldBufferTrigger) begin
                WaitHoldBuffer <= NextWaitHoldBuffer;
            end
        end
        reg  WaitACK;
        wire WaitACKTrigger = (WaitACK && TimerOutREQ && TimerOutACK && clk_en) || (TimerElapsed && clk_en) || (~Active && TimerWait && TimerInREQ && TimerInACK)|| sync_rst;
        wire NextWaitACK = WaitHoldBuffer && ~WaitACK && ~sync_rst;
        always_ff @(posedge clk) begin
            if (WaitACKTrigger) begin
                WaitACK <= NextWaitACK;
            end
        end
        reg  [3:0] WaitRegDestBuffer;
        wire [3:0] NextWaitRegDestBuffer = (sync_rst || TimerElapsed) ? '0 : RegisterDestIn;
        always_ff @(posedge clk) begin
            if (WaitHoldBufferTrigger) begin
                WaitRegDestBuffer <= NextWaitRegDestBuffer;
            end
        end
    //

    // Check Buffer
        reg  CheckACK;
        wire CheckACKTrigger = (TimerOutREQ && TimerOutACK && CheckACK && ~WaitACK) || (~CheckACK && Active && TimerCheck && TimerInREQ && TimerInACK) || sync_rst;
        wire NextCheckACK = TimerCheck && ~sync_rst;
        always_ff @(posedge clk) begin
            if (CheckACKTrigger) begin
                CheckACK <= NextCheckACK;
            end
        end
        reg  [31:0] CheckDataBuffer;
        wire [31:0] TempTimerDifference = CounterIn - ComparisonValue - 1;
        wire        CheckDataBufferTrigger = (TimerElapsed && clk_en) || (CheckACK && clk_en) || sync_rst;
        wire [31:0] NextCheckDataBuffer = (sync_rst || TimerElapsed || ~Active) ? 0 : TempTimerDifference;
        always_ff @(posedge clk) begin
            if (CheckDataBufferTrigger) begin
                CheckDataBuffer <= NextCheckDataBuffer;
            end
        end
        localparam CHECKBUFBITWIDTH = DATABITWIDTH + 8; // DATABITWIDTH for addr, 4 for minorOpcode, 4 for RegDest 
        reg  [CHECKBUFBITWIDTH-1:0] CheckMetaBuffer;
        wire [CHECKBUFBITWIDTH-1:0] NextCheckMetaBuffer = (sync_rst) ? 0 : {CommandAddressIn, MinorOpcodeIn, RegisterDestIn};
        always_ff @(posedge clk) begin
            if (CheckACKTrigger) begin
                CheckMetaBuffer <= NextCheckMetaBuffer;
            end
        end
        localparam PORTBYTEWIDTH = 4;
        wire [DATABITWIDTH-1:0] CheckDataOut;
        IOLoadDataAlignment #(
            .DATABITWIDTH(DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH)
        ) LoadAlignment (
            .MinorOpcodeIn(CheckMetaBuffer[7:4]),
            .DataAddrIn   (CheckMetaBuffer[CHECKBUFBITWIDTH-1:8]),
            .DataIn       (CheckDataBuffer),
            .DataOut      (CheckDataOut)
        );
    //

    // Output Assignments
        assign TimerInREQ = (~WaitHoldBuffer && TimerWait) ? TimerOutREQ : 1'b1;

        assign TimerOutACK = WaitACK || CheckACK;
        assign TimerDataOut = WaitACK ? '0 : CheckDataOut;
        assign RegisterDestOut = (WaitHoldBuffer && WaitACK) ? WaitRegDestBuffer : RegisterDestIn;
    //

endmodule