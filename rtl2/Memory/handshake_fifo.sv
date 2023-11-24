//                                  //
//* VALIDATED: HandshakeFIFO_tb.sv *//
//                                  //
module handshake_fifo #(
    parameter WIDTH = 16,
    parameter DEPTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    input              InputREQ,
    output             InputACK,
    input  [WIDTH-1:0] InputData,

    output             OutputREQ,
    input              OutputACK,
    output [WIDTH-1:0] OutputData
);
    localparam DEPTH_W = (DEPTH == 1) ? 1 : $clog2(DEPTH);

    // Head Counter
    reg  [DEPTH_W:0] Head;
    wire             FIFOWriteEn = clk_en && InputACK && InputREQ;
    wire             HeadTrigger = FIFOWriteEn || sync_rst;
    wire [DEPTH_W:0] NextHead = (sync_rst) ? 0 : Head + 1;
    always_ff @(posedge clk) begin
        if (HeadTrigger) begin
            Head <= NextHead;
        end
    end

    // Tail Counter
    reg  [DEPTH_W:0] Tail;
    wire             FIFOReadEn = clk_en && OutputACK && OutputREQ;
    wire             TailTrigger = FIFOReadEn || sync_rst;
    wire [DEPTH_W:0] NextTail = (sync_rst) ? 0 : Tail + 1;
    always_ff @(posedge clk) begin
        if (TailTrigger) begin
            Tail <= NextTail;
        end
    end

    // Full/Empty Checks
    wire HeadTailLowerCompare = Head[DEPTH_W-1:0] == Tail[DEPTH_W-1:0];
    wire HeadTailUpperCompare = Head[DEPTH_W] ^ Tail[DEPTH_W];
    wire FIFOFullCheck  = HeadTailLowerCompare &&  HeadTailUpperCompare;
    wire FIFOEmtpyCheck = HeadTailLowerCompare && !HeadTailUpperCompare;

    // FIFO Memory Instantiation
    reg  [WIDTH-1:0] FIFOMem [DEPTH-1:0];
    always_ff @(posedge clk) begin
        if (FIFOWriteEn) begin
            FIFOMem[Head[DEPTH_W-1:0]] <= InputData;
        end
    end
    assign OutputData = !FIFOEmtpyCheck ? FIFOMem[Tail[DEPTH_W-1:0]] : 0;

    // Handshake Outputs
    assign InputACK  = !FIFOFullCheck;
    assign OutputREQ = !FIFOEmtpyCheck;

endmodule : handshake_fifo
