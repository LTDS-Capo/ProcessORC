module IOLoadDataAlignment #(
    parameter DATABITWIDTH = 16
)(
    input                [3:0] MinorOpcodeIn,
    input   [DATABITWIDTH-1:0] DataAddrIn,
    input   [DATABITWIDTH-1:0] DataIn,

    output  [DATABITWIDTH-1:0] DataOut
);

    generate
        // 64 Bit Data
        if (DATABITWIDTH == 64) begin
            logic [DATABITWIDTH-1:0] ByteSelect;
            always_comb begin : ByteSelectMux
                case (DataAddrIn[1:0])
                    3'b001 : ByteSelect = {'0, DataIn[15:8]};
                    3'b010 : ByteSelect = {'0, DataIn[23:16]};
                    3'b011 : ByteSelect = {'0, DataIn[31:24]};
                    3'b001 : ByteSelect = {'0, DataIn[39:32]};
                    3'b001 : ByteSelect = {'0, DataIn[47:40]};
                    3'b010 : ByteSelect = {'0, DataIn[55:48]};
                    3'b011 : ByteSelect = {'0, DataIn[64:56]};
                    default: ByteSelect = {'0, DataIn[7:0]};
                endcase
            end
            logic [DATABITWIDTH-1:0] WordSelect;
            always_comb begin : WordSelectMux
                case (DataAddrIn[2:1])
                    2'b01  : WordSelect = {'0, DataIn[31:16]};
                    2'b10  : WordSelect = {'0, DataIn[47:32]};
                    2'b11  : WordSelect = {'0, DataIn[63:48]}; 
                    default: WordSelect = {'0, DataIn[15:0]};
                endcase
            end
            logic [DATABITWIDTH-1:0] LoadValue_Tmp;
            always_comb begin : DataMux
                case (MinorOpcodeIn[1:0])
                    2'b01  : LoadValue_Tmp = WordSelect; // Store Word
                    2'b10  : LoadValue_Tmp = DataAddrIn[3] ? {DataIn[31:0], DataIn[31:0]} : {DataIn[63:32], DataIn[31:0]} ; // Store Double
                    2'b11  : LoadValue_Tmp = DataIn; // Store Quad
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
                    2'b01  : ByteSelect = {'0, DataIn[15:8]};
                    2'b10  : ByteSelect = {'0, DataIn[23:16]};
                    2'b11  : ByteSelect = {'0, DataIn[31:24]};
                    default: ByteSelect = {'0, DataIn[7:0]};
                endcase
            end
            logic [DATABITWIDTH-1:0] LoadValue_Tmp;
            always_comb begin : DataMux
                case (MinorOpcodeIn[1:0])
                    2'b01  : LoadValue_Tmp = DataAddrIn[1] ? {'0, DataIn[31:16]} : {'0, DataIn[15:0]}; // Store Word
                    2'b10  : LoadValue_Tmp = DataIn; // Store Double
                    2'b11  : LoadValue_Tmp = {'0, DataIn}; // Store Quad
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
                    2'b01  : LoadValue_Tmp = DataIn; // Store Word
                    2'b10  : LoadValue_Tmp = {'0, DataIn}; // Store Double
                    2'b11  : LoadValue_Tmp = {'0, DataIn}; // Store Quad
                    default: LoadValue_Tmp = DataAddrIn[0] ? {'0, DataIn[15:8]} : {'0, DataIn[7:0]}; // Store Byte
                endcase
            end
            assign DataOut = LoadValue_Tmp;
        end
        // 8 Bit Data
        else if (DATABITWIDTH == 8) begin
            logic [DATABITWIDTH-1:0] LoadValue_Tmp;
            always_comb begin : DataInMux
                case (MinorOpcodeIn[1:0])
                    2'b01  : LoadValue_Tmp = {'0, DataIn}; // Store Word
                    2'b10  : LoadValue_Tmp = {'0, DataIn}; // Store Double
                    2'b11  : LoadValue_Tmp = {'0, DataIn}; // Store Quad
                    default: LoadValue_Tmp = DataIn; // Store Byte
                endcase
            end
            assign DataOut = LoadValue_Tmp;
        end
    endgenerate

endmodule