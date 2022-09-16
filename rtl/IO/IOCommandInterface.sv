module IOCommandInterface #(
    parameter DATABITWIDTH = 16,
    parameter PORTBYTEWIDTH = 8,
    parameter REGADDRBITWIDTH = 4,
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH)
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                          CommandInACK,
    output                         CommandInREQ,
    input                    [3:0] MinorOpcodeIn,
    input    [REGADDRBITWIDTH-1:0] RegisterDestIn,
    input       [DATABITWIDTH-1:0] DataAddrIn,
    input       [DATABITWIDTH-1:0] DataIn,

    output                         CommandOutACK,
    input                          CommandOutREQ,
    output                   [3:0] MinorOpcodeOut,
    output   [REGADDRBITWIDTH-1:0] RegisterDestOut,
    output      [DATABITWIDTH-1:0] DataAddrOut,
    output [(PORTBYTEWIDTH*8)-1:0] DataOut
);

// Command Active & Hankshakes
    reg  Active;
    wire ActiveTrigger = (CommandOutACK && CommandOutREQ && clk_en) || (CommandInACK && CommandInREQ && clk_en) || sync_rst;
    wire UpperByteEn;
    // ByteEn Gen
        generate
            if (DATABITWIDTH == 64) begin
                assign UpperByteEn = (MinorOpcodeIn[1:0] == 2'b11) || ((MinorOpcodeIn[1:0] == 2'b10) && DataAddrIn[2]) || ((MinorOpcodeIn[1:0] == 2'b01) && DataAddrIn[2] && DataAddrIn[1]) || ((MinorOpcodeIn[1:0] == 2'b00) && DataAddrIn[2] && DataAddrIn[1] && DataAddrIn[0]);
            end
            else if (DATABITWIDTH == 32) begin
                assign UpperByteEn = (MinorOpcodeIn[1:0] >= 2'b10) || ((MinorOpcodeIn[1:0] == 2'b01) && DataAddrIn[1]) || ((MinorOpcodeIn[1:0] == 2'b00) && DataAddrIn[1] && DataAddrIn[0]);
            end
            else if (DATABITWIDTH == 16) begin
                assign UpperByteEn = (MinorOpcodeIn[1:0] >= 2'b01) || DataAddrIn[0];
            end
            else if (DATABITWIDTH == 8) begin
                assign UpperByteEn = 1'b1;
            end
        endgenerate
    //
    wire CommandAtomicLoadEn = ~MinorOpcodeIn[2] && MinorOpcodeIn[3];
    wire CommandStatusLoadEn = MinorOpcodeIn[2] && MinorOpcodeIn[3];
    wire NextActive = (CommandInACK && WordEn[BUFFERCOUNT-1] && UpperByteEn && ~sync_rst) || (CommandInACK && CommandAtomicLoadEn && ~sync_rst) || (CommandInACK && CommandStatusLoadEn && ~sync_rst);
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            Active <= NextActive;
        end
    end

    reg  [3:0] MinorOpcodeBuffer;
    wire [3:0] NextMinorOpcodeBuffer = (sync_rst) ? '0 : MinorOpcodeIn;
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            MinorOpcodeBuffer <= NextMinorOpcodeBuffer;
        end
    end

    reg  [REGADDRBITWIDTH-1:0] RegisterDestBuffer;
    wire [REGADDRBITWIDTH-1:0] NextRegisterDestBuffer = (sync_rst) ? '0 : RegisterDestIn;
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            RegisterDestBuffer <= NextRegisterDestBuffer;
        end
    end

    reg  [DATABITWIDTH-1:0] AddrBuffer;
    wire [DATABITWIDTH-1:0] NextAddrBuffer = (sync_rst) ? '0 : DataAddrIn;
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            AddrBuffer <= NextAddrBuffer;
        end
    end

    assign CommandInREQ = ~Active;
    assign MinorOpcodeOut = MinorOpcodeBuffer;
    assign RegisterDestOut = RegisterDestBuffer;
    assign DataAddrOut = AddrBuffer;
    assign CommandOutACK = Active;
//

// WordEn
    localparam DATAINDEXBITWIDTH = ((DATABITWIDTH/8) == 1) ? 1 : $clog2((DATABITWIDTH/8));
    localparam BUFFERINDEXBITWIDTH = (BUFFERCOUNT == 1) ? 1 : $clog2(BUFFERCOUNT);
    localparam ELEMENTADDRUPPER = DATAINDEXBITWIDTH + BUFFERINDEXBITWIDTH;
    logic [BUFFERCOUNT-1:0] WordEn;
    always_comb begin
        WordEn = 0;
        WordEn[DataAddrIn[ELEMENTADDRUPPER-1:DATAINDEXBITWIDTH]] = 1'b1;
    end
// 

// Buffers
    genvar BufferIndex;
    wire [(DATABITWIDTH*BUFFERCOUNT)-1:0] DataOutTmp;
    generate
        for (BufferIndex = 0; BufferIndex < BUFFERCOUNT; BufferIndex = BufferIndex + 1) begin : BufferGeneration
            reg  [DATABITWIDTH-1:0] DataBuffer;
            wire                    DataBufferTrigger = (WordEn[BufferIndex] && CommandInREQ && CommandInACK && clk_en) || sync_rst;
            wire [DATABITWIDTH-1:0] NextDataBuffer = (sync_rst) ? '0 : NextDataBuffer_Tmp;
            always_ff @(posedge clk) begin
                if (DataBufferTrigger) begin
                    DataBuffer <= NextDataBuffer;
                end
            end
            wire [DATABITWIDTH-1:0] NextDataBuffer_Tmp;
            IOStoreDataAlignment #(
                .DATABITWIDTH(DATABITWIDTH)
            ) DataAligment (
                .MinorOpcodeIn(MinorOpcodeIn),
                .DataAddrIn   (DataAddrIn),
                .DataIn       (DataIn),
                .ReadData     (DataBuffer),
                .DataOut      (NextDataBuffer_Tmp)
            );
            localparam OUTPUTINDEXUPPERBIT = (BufferIndex + 1) * DATABITWIDTH;
            localparam OUTPUTINDEXLOWERBIT = BufferIndex * DATABITWIDTH;
            assign DataOutTmp[OUTPUTINDEXUPPERBIT-1:OUTPUTINDEXLOWERBIT] = DataBuffer;
        end
    endgenerate
    assign DataOut = DataOutTmp[(PORTBYTEWIDTH*8)-1:0];
//

endmodule