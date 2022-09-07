module IOLoadDataAlignment #(
    parameter DATABITWIDTH = 16,
    parameter PORTBYTEWIDTH = 4,
    parameter ODDPORTWIDTHCHECK = (((PORTBYTEWIDTH * 8) % DATABITWIDTH) != 0) ? 1 : 0,
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : (((PORTBYTEWIDTH * 8) / DATABITWIDTH) + ODDPORTWIDTHCHECK)

)(
    input                    [3:0] MinorOpcodeIn,
    input       [DATABITWIDTH-1:0] DataAddrIn,
    input  [(PORTBYTEWIDTH*8)-1:0] DataIn,

    output      [DATABITWIDTH-1:0] DataOut
);

    // Index Select
        genvar BufferIndex;
        wire [BUFFERCOUNT-1:0][DATABITWIDTH-1:0] CheckVector;
        generate
            for (BufferIndex = 0; BufferIndex < BUFFERCOUNT; BufferIndex = BufferIndex + 1) begin : LoadIndexGen
                if (BufferIndex == (BUFFERCOUNT - 1)) begin
                    localparam LOADLOWERBITWIDTH = BufferIndex * DATABITWIDTH;
                    localparam LOADUPPERBITWIDTH = PORTBYTEWIDTH * 8;
                    assign CheckVector[BufferIndex] = {'0, DataIn[LOADUPPERBITWIDTH-1:LOADLOWERBITWIDTH]};
                end
                else begin
                    localparam LOADLOWERBITWIDTH = BufferIndex * DATABITWIDTH;
                    localparam LOADUPPERBITWIDTH = (BufferIndex + 1) * DATABITWIDTH;
                    assign CheckVector[BufferIndex] = DataIn[LOADUPPERBITWIDTH-1:LOADLOWERBITWIDTH];
                end
            end
        endgenerate
        localparam BUFFERINDEXBITWIDTH = (BUFFERCOUNT == 1) ? 1 : $clog2(BUFFERCOUNT);
        localparam DATAINDEXBITWIDTH = ((DATABITWIDTH/8) == 1) ? 1 : $clog2(DATABITWIDTH/8);
        localparam TOTALINDEXBITWIDTH = BUFFERINDEXBITWIDTH + DATAINDEXBITWIDTH;
        wire [BUFFERINDEXBITWIDTH-1:0] LocalAddr = DataAddrIn[TOTALINDEXBITWIDTH-1:DATAINDEXBITWIDTH];
        generate
            if (BUFFERCOUNT == 1) begin
                wire [DATABITWIDTH-1:0] LocalData = {'0, DataIn};
            end
            else begin
                wire [DATABITWIDTH-1:0] LocalData = CheckVector[LocalAddr];
            end
        endgenerate
    //

    // Data Select
        generate
            // 64 Bit Data
            if (DATABITWIDTH == 64) begin
                logic [DATABITWIDTH-1:0] ByteSelect;
                always_comb begin : ByteSelectMux
                    case (DataAddrIn[1:0])
                        3'b001 : ByteSelect = {'0, LocalData[15:8]};
                        3'b010 : ByteSelect = {'0, LocalData[23:16]};
                        3'b011 : ByteSelect = {'0, LocalData[31:24]};
                        3'b001 : ByteSelect = {'0, LocalData[39:32]};
                        3'b001 : ByteSelect = {'0, LocalData[47:40]};
                        3'b010 : ByteSelect = {'0, LocalData[55:48]};
                        3'b011 : ByteSelect = {'0, LocalData[64:56]};
                        default: ByteSelect = {'0, LocalData[7:0]};
                    endcase
                end
                logic [DATABITWIDTH-1:0] WordSelect;
                always_comb begin : WordSelectMux
                    case (DataAddrIn[2:1])
                        2'b01  : WordSelect = {'0, LocalData[31:16]};
                        2'b10  : WordSelect = {'0, LocalData[47:32]};
                        2'b11  : WordSelect = {'0, LocalData[63:48]}; 
                        default: WordSelect = {'0, LocalData[15:0]};
                    endcase
                end
                logic [DATABITWIDTH-1:0] LoadValue_Tmp;
                always_comb begin : DataMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : LoadValue_Tmp = WordSelect; // Store Word
                        2'b10  : LoadValue_Tmp = DataAddrIn[3] ? {'0, LocalData[63:32]} : {'0, LocalData[31:0]} ; // Store Double
                        2'b11  : LoadValue_Tmp = LocalData; // Store Quad
                        default: LoadValue_Tmp = ByteSelect; // Store Byte
                    endcase
                end
                assign DataOut = LoadValue_Tmp;
            end
            // 32 Bit Data
            else if (DATABITWIDTH == 32) begin
                logic [DATABITWIDTH-1:0] ByteSelect;
                always_comb begin : ByteSelectMux
                    case (DataAddrIn[1:0])
                        2'b01  : ByteSelect = {'0, LocalData[15:8]};
                        2'b10  : ByteSelect = {'0, LocalData[23:16]};
                        2'b11  : ByteSelect = {'0, LocalData[31:24]};
                        default: ByteSelect = {'0, LocalData[7:0]};
                    endcase
                end
                logic [DATABITWIDTH-1:0] LoadValue_Tmp;
                always_comb begin : DataMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : LoadValue_Tmp = DataAddrIn[1] ? {'0, LocalData[31:16]} : {'0, LocalData[15:0]}; // Store Word
                        2'b10  : LoadValue_Tmp = LocalData; // Store Double
                        2'b11  : LoadValue_Tmp = {'0, LocalData}; // Store Quad
                        default: LoadValue_Tmp = ByteSelect; // Store Byte
                    endcase
                end
                assign DataOut = LoadValue_Tmp;
            end
            // 16 Bit Data
            else if (DATABITWIDTH == 16) begin
                logic [DATABITWIDTH-1:0] LoadValue_Tmp;
                always_comb begin : DataMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : LoadValue_Tmp = LocalData; // Store Word
                        2'b10  : LoadValue_Tmp = {'0, LocalData}; // Store Double
                        2'b11  : LoadValue_Tmp = {'0, LocalData}; // Store Quad
                        default: LoadValue_Tmp = DataAddrIn[0] ? {'0, LocalData[15:8]} : {'0, LocalData[7:0]}; // Store Byte
                    endcase
                end
                assign DataOut = LoadValue_Tmp;
            end
            // 8 Bit Data
            else if (DATABITWIDTH == 8) begin
                logic [DATABITWIDTH-1:0] LoadValue_Tmp;
                always_comb begin : DataInMux
                    case (MinorOpcodeIn[1:0])
                        2'b01  : LoadValue_Tmp = {'0, LocalData}; // Store Word
                        2'b10  : LoadValue_Tmp = {'0, LocalData}; // Store Double
                        2'b11  : LoadValue_Tmp = {'0, LocalData}; // Store Quad
                        default: LoadValue_Tmp = LocalData; // Store Byte
                    endcase
                end
                assign DataOut = LoadValue_Tmp;
            end
        endgenerate
    //
    
endmodule