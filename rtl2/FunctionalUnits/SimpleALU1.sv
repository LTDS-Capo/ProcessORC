module SimpleALU0 #(
    parameter DATABITWIDTH = 16
)(
    input               [3:0] MinorOpcode,
    input  [DATABITWIDTH-1:0] OperandAData,
    input  [DATABITWIDTH-1:0] OperandBData,
    
    output [DATABITWIDTH-1:0] ResultOut
);

    localparam INDEXBITWIDTH = $clog2(DATABITWIDTH);

    // Bit Manipulation
        wire  [INDEXBITWIDTH-1:0] BitIndex = OperandBData[INDEXBITWIDTH-1:0];
        logic  [DATABITWIDTH-1:0] BitSelectOneHot;
        always_comb begin : BitSelection
            BitSelectOneHot = 0;
            BitSelectOneHot[BitIndex] = 1'b1;
        end
        wire [BITWIDTH-1:0] BitSetResult = OperandAData | BitSelectOneHot;
        wire [BITWIDTH-1:0] BitClearResult = ~OperandAData & BitSelectOneHot;
        wire [BITWIDTH-1:0] BitFlipResult = OperandAData ^ BitSelectOneHot;      
        wire [BITWIDTH-1:0] BitSelectResult = {DATABITWIDTH{Data_InA[BitIndex]}};
    //

    // Shifts
        wire      [INDEXBITWIDTH:0] ShiftAmount = {1'b0, OperandBData[INDEXBITWIDTH-1:0]};
        wire     [DATABITWIDTH-1:0] ShiftRightResult = OperandAData >> ShiftAmount[INDEXBITWIDTH-1:0];
        wire [(DATABITWIDTH*2)-1:0] RotateRightInput = {OperandAData, OperandAData};
        wire [(DATABITWIDTH*2)-1:0] RotateRightTemp = RotateRightInput >> ShiftAmount;
        wire     [DATABITWIDTH-1:0] RotateRightResult = RotateRightTemp[DATABITWIDTH-1:0];
        wire     [DATABITWIDTH-1:0] ArithmeticShiftRightResult = $signed(OperandAData) >>> ShiftAmount[INDEXBITWIDTH-1:0];
        wire     [DATABITWIDTH-1:0] ShiftLeftResult = OperandAData << ShiftAmount[INDEXBITWIDTH-1:0];
    // 

    // Comparisons
        wire IfSignedGreaterEqual = $signed(OperandAData) >= $signed(OperandBData);
        wire IfUnsignedGreaterEqual = $unsigned(OperandAData) >= $unsigned(OperandBData);
        wire IfNotEqual = OperandAData != OperandBData;
    //

    // Reverse B
        genvar                    OperandBReversalIndex;
        wire   [DATABITWIDTH-1:0] OperandBReversed;
        generate
           for (OperandBReversalIndex = 0; OperandBReversalIndex < DATABITWIDTH; OperandBReversalIndex = (OperandBReversalIndex + 1)) begin : OperandBBitReversal
               assign OperandBReversed[OperandBReversalIndex] = [DATABITWIDTH-OperandBReversalIndex-1];
           end
        endgenerate
    //

    // Bit Scans
        wire  [DATABITWIDTH-1:0] ToBePriorityEncoded = MinorOpcode[4] ? OperandBData : OperandBReversed;
        wire [INDEXBITWIDTH-1:0] PriorityEncoderResult_Tmp;
        PriorityEncoder LowestOne (
            .DataInput     (ToBePriorityEncoded),
            .LowestOneIndex(PriorityEncoderResult_Tmp),
        );
        wire [DATABITWIDTH-INDEXBITWIDTH-1:0] PriorityEncoderResultUpperPad = 0;
        wire               [DATABITWIDTH-1:0] PriorityEncoderResult = {PriorityEncoderResultUpperPad, PriorityEncoderResult_Tmp};
    //

    logic [DATABITWIDTH-1:0] TempOutput;
    always_comb begin : TempOutputMux
        case (MinorOpcode)
            4'h0   : TempOutput = BitSetResult; // Bit Set
            4'h1   : TempOutput = BitClearResult; // Bit Clear
            4'h2   : TempOutput = BitFlipResult; // Bit Flip
            4'h3   : TempOutput = BitSelectResult; // Bit Select
            4'h4   : TempOutput = ShiftRightResult; // Shift Right
            4'h5   : TempOutput = RotateRightResult; // Rotate Right
            4'h6   : TempOutput = ArithmeticShiftRightResult; // Arithmatic Right Shift
            4'h7   : TempOutput = ShiftLeftResult; // Shift Left
            4'h8   : TempOutput = {'0, IfSignedGreaterEqual}; // Compare Greater Than Or Equal To SIGNED
            4'h9   : TempOutput = {'0, ~IfSignedGreaterEqual}; // Compare Less Than SIGNED
            4'hA   : TempOutput = {'0, IfUnsignedGreaterEqual}; // Compare Greater Than Or Equal To UNSIGNED
            4'hB   : TempOutput = {'0, ~IfUnsignedGreaterEqual}; // Compare Less Than UNSIGNED
            4'hC   : TempOutput = PriorityEncoderResult; // Bit Scan Forwards
            4'hD   : TempOutput = PriorityEncoderResult; // Bit Scan Backwards
            4'hE   : TempOutput = OperandBReversed; // Reverse B
            4'hF   : TempOutput = {'0, IfNotEqual}; // Compare Not Equal
            default: TempOutput = 0;
        endcase
    end
    assign ResultOut = TempOutput;

endmodule : SimpleALU0