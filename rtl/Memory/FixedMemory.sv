module FixedMemory #(
    parameter DATABITWIDTH = 16,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    // Flashing Input
    input        FlashEn,
    input  [9:0] FlashAddr,
    input [15:0] FlashData,

    output                       LoadStore_REQ,
    input                        LoadStore_ACK,
    input                  [3:0] MinorOpcodeIn,
    input  [REGADDRBITWIDTH-1:0] DestRegisterIn,
    input     [DATABITWIDTH-1:0] DataAddrIn,
    input     [DATABITWIDTH-1:0] DataIn,

    input                        Writeback_REQ,
    output                       Writeback_ACK,
    output [REGADDRBITWIDTH-1:0] DestRegisterOut,
    output    [DATABITWIDTH-1:0] DataOut
);

    // Order of Operations
        //  1. Read from memory into a buffer [Check]
        // 2a. IF Load;
        //      Perform Load Alignment, Store Status bit into register and wait for writeback handshake
        // 2b. IF Store;
        //      Write back to memory after doing Store Alignment

    // Memory
        reg  [DATABITWIDTH-1:0] DataMemory [511:0];
        wire              [8:0] MemAddr = FlashEn ? FlashAddr[9:1] : WriteAddr;
        wire                    DataMemoryWriteTrigger = (BufferedStoreFlag && clk_en) || (FlashEn && clk_en);
        wire [DATABITWIDTH-1:0] NextStoreData = FlashEn ? FlashData : StoreValue_Tmp;
        always_ff @(posedge clk) begin
            if (DataMemoryWriteTrigger) begin
                DataMemory[MemAddr] <= NextStoreData;
            end
        end
    //

    // Read Buffer
        reg  [15:0] ReadBuffer;
        wire [15:0] NextReadBuffer = DataMemory[DataAddrIn[9:1]];
        wire ReadBufferTrigger = clk_en;
        always_ff @(posedge clk) begin
            if (ReadBufferTrigger) begin
                ReadBuffer <= NextReadBuffer;
            end
        end
    //

    // Read Status Buffer
        reg  [32:0] ReadStatus;
        wire StoreFlag = ~MinorOpcodeIn[3] && MinorOpcodeIn[2] && LoadStore_ACK;
        wire LoadFlag = ~StoreFlag;
        wire [32:0] NextReadStatus = (sync_rst || (Writeback_REQ && ~LoadStore_ACK) || (BufferedStoreFlag && ~LoadStore_ACK)) ? '0 : {StoreFlag, LoadFlag, DestRegisterIn, MinorOpcodeIn, DataAddrIn[9:1], DataIn};
        wire ReadStatusTrigger = sync_rst || (clk_en && LoadStore_ACK && LoadStore_REQ) || (clk_en && Writeback_REQ && Writeback_ACK) || (clk_en && BufferedStoreFlag);
        always_ff @(posedge clk) begin
            if (ReadStatusTrigger) begin
                ReadStatus <= NextReadStatus;
            end
        end
        wire       BufferedStoreFlag = ReadStatus[32];
        wire       BufferedLoadFlag = ReadStatus[31];
        wire [8:0] WriteRegister = ReadStatus[30:27];
        wire [1:0] WriteMinorOpcodeLower = ReadStatus[26:25];
        wire [8:0] WriteAddr = ReadStatus[24:16];
        wire [8:0] WriteData = ReadStatus[15:0];
    //


    // Store Data Alignment
        logic [DATABITWIDTH-1:0] StoreValue_Tmp;
        always_comb begin : DataInMux
            case (WriteMinorOpcodeLower)
                2'b01  : StoreValue_Tmp = WriteData; // Store Word
                2'b10  : StoreValue_Tmp = 16'hFFFF; // Store Double
                2'b11  : StoreValue_Tmp = 16'hFFFF; // Store Quad
                default: StoreValue_Tmp = WriteAddr[0] ? {WriteData[7:0], ReadBuffer[7:0]} : {ReadBuffer[15:8], WriteData[7:0]}; // Store Byte
            endcase
        end
    //

    // Load Data Alignment
        logic [DATABITWIDTH-1:0] DataOut_Tmp;
        always_comb begin : DataOutMux
            case (WriteMinorOpcodeLower)
                2'b01  : DataOut_Tmp = ReadBuffer; // Load Word
                2'b10  : DataOut_Tmp = 16'hFFFF; // Load Double
                2'b11  : DataOut_Tmp = 16'hFFFF; // Load Quad
                default: DataOut_Tmp = WriteAddr[0] ? {'0, ReadBuffer[15:8]} : {'0, ReadBuffer[7:0]}; // Default is also case 0 - Load Byte
            endcase
        end
    //

    // Writeback Stale Write Buffer
        reg  [16:0] StaleWriteBuffer;
        wire [16:0] NextStaleWriteBuffer = (sync_rst || Writeback_REQ) ? '0 : {Writeback_ACK, DataOut_Tmp};
        wire StaleWriteBufferTrigger = sync_rst || (clk_en && Writeback_ACK);
        always_ff @(posedge clk) begin
            if (StaleWriteBufferTrigger) begin
                StaleWriteBuffer <= NextStaleWriteBuffer;
            end
        end
        wire StaleWriteActive = StaleWriteBuffer[16];
    //  

    // Output Assignments
        assign LoadStore_REQ = LoadFlag ? (~BufferedLoadFlag || Writeback_REQ) : clk_en;
        assign Writeback_ACK = BufferedLoadFlag;
        assign DestRegisterOut = WriteRegister;
        assign DataOut = StaleWriteActive ? StaleWriteBuffer : DataOut_Tmp;
    //

endmodule : FixedMemory