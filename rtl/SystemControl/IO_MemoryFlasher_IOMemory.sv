module IO_MemoryFlasher_IOMemory (
    input clk,
    input clk_en,
    input sync_rst,

    input         FlashReadEn,
    input  [10:0] FlashAddr,
    // output [15:0] FlashData,

    input         IOOut_ACK,
    output        IOOut_REQ,
    input         IOOut_ResponseRequested,
    input   [3:0] IOOut_DestReg,
    input  [31:0] IOOut_Data,

    output        IOIn_ACK,
    input         IOIn_REQ,
    output        IOIn_RegResponseFlag,
    output        IOIn_MemResponseFlag,
    output  [3:0] IOIn_DestReg,
    output [31:0] IOIn_Data
);


    // When IO handshake is made:
    //      ResponseRequested = 1 : Load data from address and respond with a RegResponse
    //      ResponseRequested = 0 : Store data to address.

    // IO Data
    // 31:27 -  5b - *Reserved*
    // 26:16 - 11b - Address
    //  15:0 - 16b - Data 

    wire [10:0] FlashWriteAddr = IOOut_Data[26:16];
    wire [15:0] FlashWrireData = IOOut_Data[15:0];

    reg [15:0] FlashMem [2047:0];
    wire       MemWriteEn = IOOut_ACK && IOOut_REQ && ~IOOut_ResponseRequested && clk_en;
    always_ff @(posedge clk) begin
        if (MemWriteEn) begin
            FlashMem[FlashWriteAddr] <= FlashWrireData;
        end
    end

    wire         MemReadEn = IOOut_ACK && IOOut_REQ && IOOut_ResponseRequested && clk_en;
    logic [10:0] FlashReadAddr;
    wire   [1:0] NextCaseCondition = {FlashReadEn, MemReadEn};
    always_comb begin : FlashReadAddrMux
        case (NextCaseCondition)
            2'b00  : FlashReadAddr = '0;
            2'b01  : FlashReadAddr = FlashWriteAddr;
            2'b10  : FlashReadAddr = FlashAddr;
            2'b11  : FlashReadAddr = FlashAddr;
            default: FlashReadAddr = '0; // Default is also case 0
        endcase
    end

    assign IOOut_REQ = IOOut_ResponseRequested ? IOIn_REQ : clk_en;
    assign IOIn_ACK = IOOut_ResponseRequested & IOOut_ACK && clk_en;
    assign IOIn_RegResponseFlag = IOOut_ResponseRequested & IOOut_ACK && clk_en;
    assign IOIn_MemResponseFlag = '0;
    assign IOIn_DestReg = IOOut_DestReg;
    assign IOIn_Data = {'0, FlashMem[FlashReadAddr]};

    // assign FlashData = FlashMem[FlashReadAddr];


endmodule