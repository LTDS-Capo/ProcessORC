module StackCache_ReplacementQueue #(
    parameter ADDRESS_BITWIDTH = 16,
    parameter bit LIBERO = 1'b0
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                         ReplacementREQ,
    output                        ReplacementACK,
    input                         ReplacementFlush,
    input                   [1:0] ReplacementLineIndex,
    input  [ADDRESS_BITWIDTH-1:0] ReplacementLineAddress,

    input                   [3:0] LineDirtyVector,
    input                   [3:0] LineValidVector,

    output                        MemoryStoreREQ,
    input                         MemoryStoreACK,
    output                  [1:0] MemoryStoreLineIndex,
    output [ADDRESS_BITWIDTH-1:0] MemoryStoreAddress,

    output                        MemoryLoadREQ,
    input                         MemoryLoadACK,
    output                  [4:0] MemoryLoadDestination,
    output [ADDRESS_BITWIDTH-1:0] MemoryLoadAddress,

    output                        FlushLine,
    output                  [1:0] FlushLineIndex
);

//! Procedure:
//* Replacing Valid Clean Line:
    // Issue to Store Queue
    // When complete,
    //   If ~ReplacementFlush,
    //     Issue to Load Queue
    //     Execute Load
    //   If ReplacementFlush,
    //     Issue LineFlush Handshake
//* Replacing Valid Dirty Line:
    // Issue to Store Queue
    // When Clean,
    //   Execute Store
    // When Complete,
    //   If ~ReplacementFlush,
    //     Issue to Load Queue
    //     Execute Load
    //   If ReplacementFlush,
    //     Issue LineFlush Handshake
//* Replacing Invalid Line:
    // If ~ReplacementFlush
    //   Issue to Load Queue
    //   Execute Load
    // If ReplacementFlush,
    //   Issue LineFlush Handshake

    wire LineValid = LineValidVector[ReplacementLineIndex];
    wire StoreLineValid = LineValidVector[StoreQueueOutputData[STORE_QUEUE_BITWIDTH-2:STORE_QUEUE_BITWIDTH-3]];

    wire                            StoreQueueInputACK;
    wire                            LoadQueueInputACK;

//? Line Store Queue
    localparam STORE_QUEUE_BITWIDTH = 1 + 2 + ADDRESS_BITWIDTH; // Flush + LineIndex + Address

    wire                            StoreQueueInputREQ = (ReplacementREQ && ~LineValid && ReplacementFlush) || (ReplacementREQ && LineValid);
    wire [STORE_QUEUE_BITWIDTH-1:0] StoreQueueInputData;

    wire                            StoreQueueOutputREQ;
    wire                            StoreQueueOutputACK = (LoadQueueInputACK && ~StoreQueueOutputData[STORE_QUEUE_BITWIDTH-1] && MemoryStoreACK && StoreLineValid) || (StoreQueueOutputData[STORE_QUEUE_BITWIDTH-1] && MemoryStoreACK && StoreLineValid) || (~StoreLineValid);
    wire [STORE_QUEUE_BITWIDTH-1:0] StoreQueueOutputData;

    handshake_fifo_top #(
        .WIDTH (STORE_QUEUE_BITWIDTH),
        .DEPTH (4),
        .LIBERO(LIBERO)
    ) StoreQueue (
        .clk       (clk),
        .clk_en    (clk_en),
        .sync_rst  (sync_rst),
        .InputREQ  (StoreQueueInputREQ),
        .InputACK  (StoreQueueInputACK),
        .InputData (StoreQueueInputData),
        .OutputREQ (StoreQueueOutputREQ),
        .OutputACK (StoreQueueOutputACK),
        .OutputData(StoreQueueOutputData)
    );
//?


//? Line Load Queue
    localparam LOAD_QUEUE_BITWIDTH = 2 + ADDRESS_BITWIDTH; // LineIndex + Address

    wire                            LoadQueueInputREQ = (ReplacementREQ && ~LineValid && ~ReplacementFlush) || (StoreQueueOutputREQ && ~StoreQueueOutputData[STORE_QUEUE_BITWIDTH-1] && MemoryStoreACK);
    wire [STORE_QUEUE_BITWIDTH-1:0] LoadQueueInputData;

    wire                            LoadQueueOutputREQ;
    wire                            LoadQueueOutputACK;
    wire [STORE_QUEUE_BITWIDTH-1:0] LoadQueueOutputData;

    handshake_fifo_top #(
        .WIDTH (LOAD_QUEUE_BITWIDTH),
        .DEPTH (4),
        .LIBERO(LIBERO)
    ) LoadQueue (
        .clk       (clk),
        .clk_en    (clk_en),
        .sync_rst  (sync_rst),
        .InputREQ  (LoadQueueInputREQ),
        .InputACK  (LoadQueueInputACK),
        .InputData (LoadQueueInputData),
        .OutputREQ (LoadQueueOutputREQ),
        .OutputACK (LoadQueueOutputACK),
        .OutputData(LoadQueueOutputData)
    );
//?


    assign ReplacementACK = (LineValid && StoreQueueInputACK) || (~LineValid && LoadQueueInputACK);


    assign FlushLine = StoreQueueOutputREQ && ~StoreLineValid;
    assign FlushLineIndex = StoreQueueOutputData[STORE_QUEUE_BITWIDTH-2:STORE_QUEUE_BITWIDTH-3];


endmodule : StackCache_ReplacementQueue

