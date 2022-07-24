module FixedMemory #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,

    output                    LoadStore_REQ,
    input                     LoadStore_ACK,
    input               [3:0] MinorOpcodeIn,
    input  [DATABITWIDTH-1:0] DataAddrIn,
    input  [DATABITWIDTH-1:0] DataIn,

    input                     Writeback_REQ,
    output                    Writeback_ACK,
    output [DATABITWIDTH-1:0] DataOut
);

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

    reg [DATABITWIDTH-1:0] DataMemory [511:0];
    wire [9:0] MemAddr = {DataAddrIn[9:1], 1'b0};
    wire DataMemoryWriteTrigger = (~MinorOpcodeIn[3] && MinorOpcodeIn[2] && clk_en);
    always_ff @(posedge clk) begin
        if (DataMemoryWriteTrigger) begin
            DataMemory[MemAddr] <= StoreValue_Tmp;
        end
    end
    wire[DATABITWIDTH-1:0] DataRead = DataMemory[MemAddr];

    logic [DATABITWIDTH-1:0] DataOut_Tmp;
    always_comb begin : DataOutMux
        case (MinorOpcodeIn[1:0])
            2'b01  : DataOut_Tmp = DataRead; // Load Word
            2'b10  : DataOut_Tmp = 16'hFFFF; // Load Double
            2'b11  : DataOut_Tmp = 16'hFFFF; // Load Quad
            default: DataOut_Tmp = DataAddrIn[0] ? {'0, DataRead[15:8]} : {'0, DataRead[7:0]} ; // Default is also case 0 - Load Byte
        endcase
    end
    assign DataOut = DataOut_Tmp;

    assign LoadStore_REQ = Writeback_REQ || (LoadStore_ACK && DataMemoryWriteTrigger);
    assign Writeback_ACK = LoadStore_ACK && ~DataMemoryWriteTrigger;

endmodule