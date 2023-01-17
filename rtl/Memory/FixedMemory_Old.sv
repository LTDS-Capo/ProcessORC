module FixedMemory_Old #(
    parameter DATABITWIDTH = 16,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,

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
    // ToDo: Make fully parameterizable based on DATABITWIDTH.

    // Store Data Alignment
        logic [DATABITWIDTH-1:0] StoreValue_Tmp;
        always_comb begin : DataInMux
            case (MinorOpcodeIn[1:0])
                2'b01  : StoreValue_Tmp = DataIn; // Store Word
                2'b10  : StoreValue_Tmp = 16'hFFFF; // Store Double
                2'b11  : StoreValue_Tmp = 16'hFFFF; // Store Quad
                default: StoreValue_Tmp = DataAddrIn[0] ? {DataIn[7:0], DataRead[7:0]} : {DataRead[15:8], DataIn[7:0]} ; // Store Byte
            endcase
        end
    //

    reg  [DATABITWIDTH-1:0] DataMemory [511:0];
    wire              [8:0] MemAddr = FlashEn ? FlashAddr[9:1] : {DataAddrIn[9:1]};
    wire                    DataMemoryWriteTrigger = (~MinorOpcodeIn[3] && MinorOpcodeIn[2] && LoadStore_ACK && clk_en) || (FlashEn && clk_en);
    wire [DATABITWIDTH-1:0] NextStoreData = FlashEn ? FlashData : StoreValue_Tmp;
    always_ff @(posedge clk) begin
        if (DataMemoryWriteTrigger) begin
            DataMemory[MemAddr] <= NextStoreData;
        end
    end
    wire[DATABITWIDTH-1:0] DataRead = DataMemoryWriteTrigger ? '0 : DataMemory[DataAddrIn[9:1]];

    // Load Data Alignment
        logic [DATABITWIDTH-1:0] DataOut_Tmp;
        always_comb begin : DataOutMux
            case (MinorOpcodeIn[1:0])
                2'b01  : DataOut_Tmp = DataRead; // Load Word
                2'b10  : DataOut_Tmp = 16'hFFFF; // Load Double
                2'b11  : DataOut_Tmp = 16'hFFFF; // Load Quad
                default: DataOut_Tmp = DataAddrIn[0] ? {'0, DataRead[15:8]} : {'0, DataRead[7:0]} ; // Default is also case 0 - Load Byte
            endcase
        end
    //


    assign DataOut = DataOut_Tmp;
    assign LoadStore_REQ = (~MinorOpcodeIn[3] && MinorOpcodeIn[2]) ? LoadStore_ACK : Writeback_REQ;
    assign Writeback_ACK = LoadStore_ACK && ~DataMemoryWriteTrigger;
    assign DestRegisterOut = DestRegisterIn;

endmodule