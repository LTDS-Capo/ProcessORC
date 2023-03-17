module SimpleALU0 #(
    parameter DATABITWIDTH = 16
)(
    input               [3:0] MinorOpcode,
    input  [DATABITWIDTH-1:0] OperandAData,
    input  [DATABITWIDTH-1:0] OperandBData,
    
    output [DATABITWIDTH-1:0] ResultOut
);

    wire   [DATABITWIDTH:0] PaddedOperandA = {0, OperandAData};
    wire   [DATABITWIDTH:0] PaddedOperandB = {0, OperandBData};
    wire   [DATABITWIDTH:0] PaddedAdditionResult = PaddedOperandA + PaddedOperandB;
    wire   [DATABITWIDTH:0] PaddedSubtractionResult = PaddedOperandA - PaddedOperandB;

    wire [DATABITWIDTH-2:0] CheckResultUpper = 0;
    wire [DATABITWIDTH-1:0] CarryCheckResult = {CheckResultUpper, PaddedAdditionResult[DATABITWIDTH]};
    wire [DATABITWIDTH-1:0] BorrowCheckResult = {CheckResultUpper, PaddedSubtractionResult[DATABITWIDTH]};
    wire                    AddMSBXOR = OperandAData[DATABITWIDTH-1] ^ PaddedAdditionResult[DATABITWIDTH-1];
    wire                    SubMSBXOR = OperandAData[DATABITWIDTH-1] ^ PaddedSubtractionResult[DATABITWIDTH-1];
    wire                    InputMSBXNOR = ~(OperandAData[DATABITWIDTH-1] ^ OperandBData[DATABITWIDTH-1]);
    wire                    AddOverflowAND = AddMSBXOR && InputMSBXNOR;
    wire                    SubOverflowAND = SubMSBXOR && InputMSBXNOR;
    wire [DATABITWIDTH-1:0] AddOverflowCheckResult = {CheckResultUpper, AddOverflowAND}; 
    wire [DATABITWIDTH-1:0] SubOverflowCheckResult = {CheckResultUpper, SubOverflowAND}; 

    wire [DATABITWIDTH-1:0] ANDResult = OperandAData & OperandBData;
    wire [DATABITWIDTH-1:0] XORResult = OperandAData ^ OperandBData;
    wire [DATABITWIDTH-1:0] ORResult = OperandAData | OperandBData;

    logic [DATABITWIDTH-1:0] TempOutput;
    always_comb begin : TempOutputMux
        case (MinorOpcode)
            4'h0   : TempOutput = PaddedAdditionResult[DATABITWIDTH-1:0];    // Add
            4'h1   : TempOutput = OperandBData + 1;                          // Inc
            4'h2   : TempOutput = PaddedSubtractionResult[DATABITWIDTH-1:0]; // Sub
            4'h3   : TempOutput = OperandBData - 1;                          // Dec
            4'h4   : TempOutput = ANDResult;                                 // AND
            4'h5   : TempOutput = XORResult;                                 // XOR
            4'h6   : TempOutput = ORResult;                                  // OR
            4'h7   : TempOutput = OperandBData;                              // Move
            4'h8   : TempOutput = CarryCheckResult;                          // Carry Check
            4'h9   : TempOutput = AddOverflowCheckResult;                    // Add Overflow Check
            4'hA   : TempOutput = BorrowCheckResult;                         // Borrow Check
            4'hB   : TempOutput = SubOverflowCheckResult;                    // Sub Overflow Check
            4'hC   : TempOutput = ~ANDResult;                                // NAND
            4'hD   : TempOutput = ~XORResult;                                // XNOR
            4'hE   : TempOutput = ~ORResult;                                 // NOR
            4'hF   : TempOutput = ~OperandBData;                             // NOT B
            default: TempOutput = 0;
        endcase
    end

    assign ResultOut = TempOutput;

endmodule : SimpleALU0