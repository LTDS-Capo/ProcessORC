module IOStoreAlignment #(
    parameter DATABITWIDTH = 16,
    parameter PORTBYTEWIDTH = 16,
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH),
    parameter PORTINDEXBITWIDTH = (PORTBYTEWIDTH == 1) ? 1 : $clog2(PORTBYTEWIDTH)
)(
    input                [3:0] MinorOpcodeIn,
    input   [DATABITWIDTH-1:0] DataAddrIn,
    input   [DATABITWIDTH-1:0] DataIn,
    input   [DATABITWIDTH-1:0] DataRead,

    output   [BUFFERCOUNT-1:0] ElementEn,
    output [PORTBYTEWIDTH-1:0] ByteEn,
    output  [DATABITWIDTH-1:0] DataOut
);

    // ElementEn Gen
        localparam DATAINDEXBITWIDTH = ((DATABITWIDTH/8) == 1) ? 1 : $clog2((DATABITWIDTH/8));
        localparam BUFFERINDEXBITWIDTH = (BUFFERCOUNT == 1) ? 1 : $clog2(BUFFERCOUNT);
        localparam ELEMENTADDRUPPER = DATAINDEXBITWIDTH + BUFFERINDEXBITWIDTH;
        logic [BUFFERCOUNT-1:0] BufferDecoder;
        always_comb begin
            BufferDecoder = 0;
            BufferDecoder[DataAddrIn[ELEMENTADDRUPPER-1:DATAINDEXBITWIDTH]] = 1'b1;
        end
    // 

    // ByteEn Gen
        logic [PORTBYTEWIDTH-1:0] ByteDecoder;
        always_comb begin
            ByteDecoder = 0;
            ByteDecoder[DataAddrIn[PORTINDEXBITWIDTH-1:0]] = 1'b1;
        end
        generate
            if (DATABITWIDTH == 64) begin
                wire [PORTBYTEWIDTH-1:0] B0Enable = ByteDecoder;
                wire [PORTBYTEWIDTH-1:0] B1Enable = (MinorOpcodeIn[1:0] >= 2'b01) ? (ByteDecoder < 1) : '0;
                wire [PORTBYTEWIDTH-1:0] B2Enable = (MinorOpcodeIn[1:0] >= 2'b10) ? (ByteDecoder < 2) : '0;
                wire [PORTBYTEWIDTH-1:0] B3Enable = (MinorOpcodeIn[1:0] >= 2'b10) ? (ByteDecoder < 3) : '0;
                wire [PORTBYTEWIDTH-1:0] B4Enable = (MinorOpcodeIn[1:0] == 2'b11) ? (ByteDecoder < 4) : '0;
                wire [PORTBYTEWIDTH-1:0] B5Enable = (MinorOpcodeIn[1:0] == 2'b11) ? (ByteDecoder < 5) : '0;
                wire [PORTBYTEWIDTH-1:0] B6Enable = (MinorOpcodeIn[1:0] == 2'b11) ? (ByteDecoder < 6) : '0;
                wire [PORTBYTEWIDTH-1:0] B7Enable = (MinorOpcodeIn[1:0] == 2'b11) ? (ByteDecoder < 7) : '0;
                assign ByteEn = B7Enable | B6Enable | B5Enable | B4Enable | B3Enable | B2Enable | B1Enable | B0Enable;
            end
            else if (DATABITWIDTH == 32) begin
                wire [PORTBYTEWIDTH-1:0] B0Enable = ByteDecoder;
                wire [PORTBYTEWIDTH-1:0] B1Enable = (MinorOpcodeIn[1:0] >= 2'b01) ? (ByteDecoder < 1) : '0;
                wire [PORTBYTEWIDTH-1:0] B2Enable = (MinorOpcodeIn[1:0] >= 2'b10) ? (ByteDecoder < 2) : '0;
                wire [PORTBYTEWIDTH-1:0] B3Enable = (MinorOpcodeIn[1:0] >= 2'b10) ? (ByteDecoder < 3) : '0;
                assign ByteEn = B3Enable | B2Enable | B1Enable | B0Enable;
            end
            else if (DATABITWIDTH == 16) begin
                wire [PORTBYTEWIDTH-1:0] B0Enable = ByteDecoder;
                wire [PORTBYTEWIDTH-1:0] B1Enable = (MinorOpcodeIn[1:0] >= 2'b01) ? (ByteDecoder < 1) : '0;
                assign ByteEn = B1Enable | B0Enable;
            end
            else if (DATABITWIDTH == 8) begin
                assign ByteEn = ByteDecoder;
            end
        endgenerate
    //

    // DataOut Gen
        generate
            if (DATABITWIDTH == 64) begin
                logic [DATABITWIDTH-1:0] ByteSelect;
                always_comb begin : ByteSelectMux
                    case (DataAddrIn[1:0])
                        3'b001 : ByteSelect = {DataRead[63:16], DataIn[7:0], DataRead[7:0]};
                        3'b010 : ByteSelect = {DataRead[63:24], DataIn[7:0], DataRead[15:0]};
                        3'b011 : ByteSelect = {DataRead[63:32], DataIn[7:0], DataRead[23:0]};
                        3'b001 : ByteSelect = {DataRead[63:40], DataIn[7:0], DataRead[31:0]};
                        3'b001 : ByteSelect = {DataRead[63:48], DataIn[7:0], DataRead[39:0]};
                        3'b010 : ByteSelect = {DataRead[63:56], DataIn[7:0], DataRead[47:0]};
                        3'b011 : ByteSelect = {DataIn[7:0], DataRead[55:0]};
                        default: ByteSelect = {DataRead[63:8], DataIn[7:0]};
                    endcase
                end
                logic [DATABITWIDTH-1:0] WordSelect;
                always_comb begin : WordSelectMux
                    case (DataAddrIn[2:1])
                        2'b01  : WordSelect = {DataRead[63:32], DataIn[31:16], DataRead[15:0]};
                        2'b10  : WordSelect = {DataRead[63:48], DataIn[15:0], DataRead[31:0]};
                        2'b11  : WordSelect = {DataIn[15:0], DataRead[47:0]}; 
                        default: WordSelect = {DataRead[63:8], DataIn[15:0]};
                    endcase
                end
                logic [DATABITWIDTH-1:0] StoreValue_Tmp;
                always_comb begin : DataMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : StoreValue_Tmp = WordSelect; // Store Word
                        2'b10  : StoreValue_Tmp = DataAddrIn[3] ? {DataIn[31:0], DataRead[31:0]} : {DataRead[63:32], DataIn[31:0]} ; // Store Double
                        2'b11  : StoreValue_Tmp = DataIn; // Store Quad
                        default: StoreValue_Tmp = ByteSelect; // Store Byte
                    endcase
                end
                assign DataOut = StoreValue_Tmp;
            end
            else if (DATABITWIDTH == 32) begin
                logic [DATABITWIDTH-1:0] ByteSelect;
                always_comb begin : ByteSelectMux
                    case (DataAddrIn[1:0])
                        2'b01  : ByteSelect = {DataRead[31:16], DataIn[7:0], DataRead[7:0]};
                        2'b10  : ByteSelect = {DataRead[31:24], DataIn[7:0], DataRead[15:0]};
                        2'b11  : ByteSelect = {DataIn[7:0], DataRead[23:0]};
                        default: ByteSelect = {DataRead[31:8], DataIn[7:0]};
                    endcase
                end
                logic [DATABITWIDTH-1:0] StoreValue_Tmp;
                always_comb begin : DataMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : StoreValue_Tmp = DataAddrIn[1] ? {DataIn[15:0], DataRead[15:0]} : {DataRead[31:16], DataIn[15:0]} ; // Store Word
                        2'b10  : StoreValue_Tmp = DataIn; // Store Double
                        2'b11  : StoreValue_Tmp = 32'hFFFF; // Store Quad
                        default: StoreValue_Tmp = ByteSelect; // Store Byte
                    endcase
                end
                assign DataOut = StoreValue_Tmp;
            end
            else if (DATABITWIDTH == 16) begin
                logic [DATABITWIDTH-1:0] StoreValue_Tmp;
                always_comb begin : DataMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : StoreValue_Tmp = DataIn; // Store Word
                        2'b10  : StoreValue_Tmp = 16'hFFFF; // Store Double
                        2'b11  : StoreValue_Tmp = 16'hFFFF; // Store Quad
                        default: StoreValue_Tmp = DataAddrIn[0] ? {DataIn[7:0], DataRead[7:0]} : {DataRead[15:8], DataIn[7:0]} ; // Store Byte
                    endcase
                end
                assign DataOut = StoreValue_Tmp;
            end
            else if (DATABITWIDTH == 8) begin
                logic [DATABITWIDTH-1:0] StoreValue_Tmp;
                always_comb begin : DataInMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : StoreValue_Tmp = 8'hFF; // Store Word
                        2'b10  : StoreValue_Tmp = 8'hFF; // Store Double
                        2'b11  : StoreValue_Tmp = 8'hFF; // Store Quad
                        default: StoreValue_Tmp = DataIn; // Store Byte
                    endcase
                end
                assign DataOut = StoreValue_Tmp;
            end
        endgenerate
    //
endmodule