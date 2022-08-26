module IOStoreDataAlignment #(
    parameter DATABITWIDTH = 16
)(
    input                [3:0] MinorOpcodeIn,
    input   [DATABITWIDTH-1:0] DataAddrIn,
    input   [DATABITWIDTH-1:0] DataIn,
    input   [DATABITWIDTH-1:0] ReadData,

    output  [DATABITWIDTH-1:0] DataOut
);

    generate
        // 64 Bit Data
        if (DATABITWIDTH == 64) begin
            logic [DATABITWIDTH-1:0] ByteSelect;
            always_comb begin : ByteSelectMux
                case (DataAddrIn[2:0])
                    3'b001 : ByteSelect = {ReadData[63:16], DataIn[7:0], ReadData[7:0]};
                    3'b010 : ByteSelect = {ReadData[63:24], DataIn[7:0], ReadData[15:0]};
                    3'b011 : ByteSelect = {ReadData[63:32], DataIn[7:0], ReadData[23:0]};
                    3'b001 : ByteSelect = {ReadData[63:40], DataIn[7:0], ReadData[31:0]};
                    3'b001 : ByteSelect = {ReadData[63:48], DataIn[7:0], ReadData[39:0]};
                    3'b010 : ByteSelect = {ReadData[63:56], DataIn[7:0], ReadData[47:0]};
                    3'b011 : ByteSelect = {DataIn[7:0], ReadData[55:0]};
                    default: ByteSelect = {ReadData[63:8], DataIn[7:0]};
                endcase
            end
            logic [DATABITWIDTH-1:0] WordSelect;
            always_comb begin : WordSelectMux
                case (DataAddrIn[2:1])
                    2'b01  : WordSelect = {ReadData[63:32], DataIn[15:0], ReadData[15:0]};
                    2'b10  : WordSelect = {ReadData[63:48], DataIn[15:0], ReadData[31:0]};
                    2'b11  : WordSelect = {DataIn[15:0], ReadData[47:0]}; 
                    default: WordSelect = {ReadData[63:8], DataIn[15:0]};
                endcase
            end
            logic [DATABITWIDTH-1:0] StoreValue_Tmp;
            always_comb begin : DataMux
                case (MinorOpcodeIn[1:0])
                    2'b01  : StoreValue_Tmp = WordSelect; // Store Word
                    2'b10  : StoreValue_Tmp = DataAddrIn[2] ? {DataIn[31:0], ReadData[31:0]} : {ReadData[63:32], DataIn[31:0]} ; // Store Double
                    2'b11  : StoreValue_Tmp = DataIn; // Store Quad
                    default: StoreValue_Tmp = ByteSelect; // Store Byte
                endcase
            end
            assign DataOut = StoreValue_Tmp;
        end
        // 32 Bit Data
        else if (DATABITWIDTH == 32) begin
            logic [DATABITWIDTH-1:0] ByteSelect;
            always_comb begin : ByteSelectMux
                case (DataAddrIn[1:0])
                    2'b01  : ByteSelect = {ReadData[31:16], DataIn[7:0], ReadData[7:0]};
                    2'b10  : ByteSelect = {ReadData[31:24], DataIn[7:0], ReadData[15:0]};
                    2'b11  : ByteSelect = {DataIn[7:0], ReadData[23:0]};
                    default: ByteSelect = {ReadData[31:8], DataIn[7:0]};
                endcase
            end
            logic [DATABITWIDTH-1:0] StoreValue_Tmp;
            always_comb begin : DataMux
                case (MinorOpcodeIn[1:0])
                    2'b01  : StoreValue_Tmp = DataAddrIn[1] ? {DataIn[15:0], ReadData[15:0]} : {ReadData[31:16], DataIn[15:0]} ; // Store Word
                    2'b10  : StoreValue_Tmp = DataIn; // Store Double
                    2'b11  : StoreValue_Tmp = 32'hFFFF_FFFF; // Store Quad
                    default: StoreValue_Tmp = ByteSelect; // Store Byte
                endcase
            end
            assign DataOut = StoreValue_Tmp;
        end
        // 16 Bit Data
        else if (DATABITWIDTH == 16) begin
            logic [DATABITWIDTH-1:0] StoreValue_Tmp;
            always_comb begin : DataMux
                case (MinorOpcodeIn[1:0])
                    2'b01  : StoreValue_Tmp = DataIn; // Store Word
                    2'b10  : StoreValue_Tmp = 16'hFFFF; // Store Double
                    2'b11  : StoreValue_Tmp = 16'hFFFF; // Store Quad
                    default: StoreValue_Tmp = DataAddrIn[0] ? {DataIn[7:0], ReadData[7:0]} : {ReadData[15:8], DataIn[7:0]}; // Store Byte
                endcase
            end
            assign DataOut = StoreValue_Tmp;
        end
        // 8 Bit Data
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

endmodule