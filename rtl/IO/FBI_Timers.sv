//* Four Byte Interface Timers *//
module FBI_Timers #(
    parameter DATABITWIDTH = 16,
    parameter PORTBYTEWIDTH = 8, // Multiple of 2s only for now
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH)
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                     IOInACK,
    output                    IOInREQ,
    input                     LoadEnIn,
    input                     StoreEnIn,             
    input   [BUFFERCOUNT-1:0] WordEn,
    input  [DATABITWIDTH-1:0] DataIn,

    output                    TimerOutACK,
    input                     TimerOutREQ,
    output             [31:0] TimerDataOut,
    output              [3:0] RegisterDestOut
);

    // [26:0] Wait time
    //   [27] PreScaler
    // > 0 : 1x
    // > 1 : 32x
    // [20:28] Timer Select
    // [31] Command
    // > 0 : Clear(Store)/Check(Load)
    // > 1 : Set(Store)/Wait(Load)
    wire                         TimerACK;
    wire                         TimerREQ;
    wire                         LoadEn;
    wire                         StoreEn;
    wire [(PORTBYTEWIDTH*8)-1:0] TimerDataOut;
    IOCommandInterface #(
        .DATABITWIDTH (DATABITWIDTH),
        .PORTBYTEWIDTH(PORTBYTEWIDTH),
        .BUFFERCOUNT  (BUFFERCOUNT)
    ) IOInterface (
        .clk       (clk),
        .clk_en    (clk_en),
        .sync_rst  (sync_rst),
        .IOInACK   (IOInACK),
        .IOInREQ   (IOInREQ),
        .LoadEnIn  (LoadEnIn),
        .StoreEnIn (StoreEnIn),
        .WordEn    (WordEn),
        .DataIn    (DataIn),
        .IOOutACK  (TimerACK),
        .IOOutREQ  (TimerREQ),
        .LoadEnOut (LoadEn),
        .StoreEnOut(StoreEn),
        .DataOut   (TimerDataOut)
    );

    // 8x timers

    // single 32b counter

    // each cell compares the counter to an internal register

endmodule