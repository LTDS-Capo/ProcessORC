module IOCommandInterface #(
    parameter DATABITWIDTH = 16,
    parameter PORTBYTEWIDTH = 8, // Multiple of 2s only for now
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH)
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                            IOInACK,
    output                           IOInREQ,
    input                            LoadEnIn,
    input                            StoreEnIn,
    input          [BUFFERCOUNT-1:0] WordEn,
    input         [DATABITWIDTH-1:0] DataIn,

    output                           IOOutACK,
    input                            IOOutREQ,
    output                           LoadEnOut, 
    output                           StoreEnOut,
    output   [(PORTBYTEWIDTH*8)-1:0] DataOut
);

    genvar BufferIndex;
    wire [(BUFFERCOUNT*DATABITWIDTH)-1:0] DataOutTmp;
    generate
        for (BufferIndex = 0; BufferIndex < BUFFERCOUNT; BufferIndex = BufferIndex + 1) begin : ByteBufferGeneration
            localparam UPPERBITINDEX = (BufferIndex + 1) * DATABITWIDTH;
            localparam LOWERBITINDEX = BufferIndex * DATABITWIDTH;
            if (BufferIndex == (BUFFERCOUNT-1)) begin
                // Smaller bytes left than data width... example 8bit port on 16b system
                // standard pass through
                assign DataOutTmp[UPPERBITINDEX-1:LOWERBITINDEX] = {'0, DataIn};
            end
            else begin
                reg  [DATABITWIDTH-1:0] DataBuffer;
                wire                    DataBufferTrigger = (WordEn[BufferIndex] && IOInACK && clk_en) || sync_rst;
                wire [DATABITWIDTH-1:0] NextDataBuffer = (sync_rst) ? 0 : DataIn;
                always_ff @(posedge clk) begin
                    if (DataBufferTrigger) begin
                        DataBuffer <= NextDataBuffer;
                    end
                end
                assign DataOutTmp[UPPERBITINDEX-1:LOWERBITINDEX] = DataBuffer;
            end
        end
    endgenerate

    generate
        if (BUFFERCOUNT == 1) begin
            assign DataOut = DataOutTmp[(PORTBYTEWIDTH*8)-1:0];
            assign IOOutACK = IOInACK;
            assign IOInREQ = IOOutREQ;
        end
        else begin
            assign DataOut = DataOutTmp[(PORTBYTEWIDTH*8)-1:0];
            assign IOOutACK = WordEn[BUFFERCOUNT-1] && IOInACK;
            assign IOInREQ = WordEn[BUFFERCOUNT-1] ? IOOutREQ : IOInACK;
        end
    endgenerate

    assign LoadEnOut = LoadEnIn;
    assign StoreEnOut = StoreEnIn;

endmodule