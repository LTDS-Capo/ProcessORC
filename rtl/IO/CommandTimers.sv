module CommandTimers (
    input clk,
    input clk_en,
    input sync_rst,

    input                     IOInACK,
    output                    IOInREQ,
    input               [3:0] MinorOpcodeIn,
    input               [3:0] RegisterDestIn,
    input  [DATABITWIDTH-1:0] DataAddrIn,
    input  [DATABITWIDTH-1:0] DataIn,

    output       [7:0]        TimerOutACK,
    input        [7:0]        TimerOutREQ,
    output       [7:0]  [3:0] RegisterDestOut,
    output       [7:0] [31:0] TimerDataOut
);
    
    // [26:0] Wait time
    //   [27] PreScaler
    // > 0 : 1x
    // > 1 : 32x
    // [30:28] Timer Select
    // [31] Command
    // > 0 : Clear(Store)/Check(Load)
    // > 1 : Set(Store)/Wait(Load)

    // Interface Manager (For stores)
        localparam PORTBYTEWIDTH = 4; // Multiple of 2s only for now
        localparam BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH);
        wire                         TimerACK;
        wire                         TimerREQ = TimerREQArray[TimerDataOut_Tmp[30:28]];
        wire                   [3:0] MinorOpcodeOut;
        wire                         LoadEn = ~MinorOpcodeOut[2];
        wire                         StoreEn = MinorOpcodeOut[2];
        wire [(PORTBYTEWIDTH*8)-1:0] TimerAddrOut;
        wire [(PORTBYTEWIDTH*8)-1:0] TimerDataOut_Tmp;
        IOCommandInterface #(
            .DATABITWIDTH (DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH),
            .BUFFERCOUNT  (BUFFERCOUNT)
        ) IOInterface (
            .clk           (clk),
            .clk_en        (clk_en),
            .sync_rst      (sync_rst),
            .CommandInACK  (IOInACK),
            .CommandInREQ  (IOInREQ),
            .MinorOpcodeIn (MinorOpcodeIn),
            .DataAddrIn    (DataAddrIn),
            .DataIn        (DataIn),
            .CommandOutACK (TimerACK),
            .CommandOutREQ (TimerREQ),
            .MinorOpcodeOut(MinorOpcodeOut),
            .DataAddrOut   (TimerAddrOut),
            .DataOut       (TimerDataOut_Tmp)
        );
    //

    // 32bit Counter
        reg  [31:0] CycleCounter;
        wire        CycleCounterTrigger = clk_en || sync_rst;
        wire [31:0] NextCycleCounter = (sync_rst) ? 0 : (CycleCounter + 1);
        always_ff @(posedge clk) begin
            if (CycleCounterTrigger) begin
                CycleCounter <= NextCycleCounter;
            end
        end
    //

    // 8x timers
        wire  [31:0] ComparisonValue_Tmp = TimerDataOut_Tmp[27] ? {TimerDataOut_Tmp[26:0], 5'h00} : {'0, TimerDataOut_Tmp[26:0]};
        wire  [31:0] ComparisonValue = CycleCounter + ComparisonValue_Tmp;
        logic  [3:0] CommandVector;
        wire   [1:0] CommandAddr = {StoreEn, TimerDataOut_Tmp[31]};
        wire   [7:0] TimerREQArray;
        always_comb begin
            CommandVector = 0;
            CommandVector[CommandAddr] = 1'b1;
        end
        localparam TIMERCOUNT = 8;
        genvar TimerIndex;
        generate
            for (TimerIndex = 0; TimerIndex < 8; TimerIndex = TimerIndex + 1) begin : TimerGeneration
                wire TimerACK_Local = TimerACK && (TimerIndex == TimerDataOut_Tmp[30:28]);
                CommandTimers_Cell #(
                    .DATABITWIDTH(16)
                )(
                    .clk              (clk),
                    .clk_en           (clk_en),
                    .sync_rst         (sync_rst),
                    .CounterIn        (CycleCounter),
                    .TimerInACK       (TimerACK),
                    .TimerInREQ       (TimerREQArray[TimerIndex]),
                    .ComparisonValueIn(ComparisonValue),        
                    .MinorOpcodeIn    (MinorOpcodeOut),    
                    .CommandAddressIn (TimerAddrOut),       
                    .RegisterDestIn   (RegisterDestIn),     
                    .TimerSet         (CommandVector[3]),
                    .TimerClear       (CommandVector[2]),
                    .TimerCheck       (CommandVector[0]),
                    .TimerWait        (CommandVector[1]),
                    .TimerOutACK      (TimerOutACK[TimerIndex]),
                    .TimerOutREQ      (TimerOutREQ[TimerIndex]),
                    .TimerDataOut     (TimerDataOut[TimerIndex]),
                    .RegisterDestOut  (RegisterDestOut[TimerIndex])
                );
            end
        endgenerate
    //



endmodule