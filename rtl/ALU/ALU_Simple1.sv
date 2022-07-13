module ALU_Simple1 #(
    parameter BITWIDTH = 16
)(
    input  [BITWIDTH-1:0] Data_InA,
    input  [BITWIDTH-1:0] Data_InB,

    input                 ALU_Enable,
    input           [3:0] Opcode,

    output [BITWIDTH-1:0] ResultOut
);

    localparam INDEXBITWIDTH = $clog2(BITWIDTH);

    // Bit Index Generation
    wire                     IndexZeroCheck = Data_InB[INDEXBITWIDTH:0] == 0;
    wire                     OutOfBoundsCheck = (Data_InB[INDEXBITWIDTH:0] > BITWIDTH);
    wire   [INDEXBITWIDTH:0] BitIndex_temp = Data_InB[INDEXBITWIDTH:0] - 1;
    wire [INDEXBITWIDTH-1:0] BitIndex = BitIndex_temp[INDEXBITWIDTH-1:0];

    // Bit Selection 
    // (Generate a decoder)
    logic [BITWIDTH-1:0] BitSelectOneHot_tmp;
    always_comb begin : BitSelection
        BitSelectOneHot_tmp = 0;
        BitSelectOneHot_tmp[BitIndex] = 1'b1;
    end
    wire [BITWIDTH-1:0] BitSelectOneHot = (IndexZeroCheck || OutOfBoundsCheck) ? 0 : BitSelectOneHot_tmp;

    // Bit Manipulation Results
    wire [BITWIDTH-1:0] BitSetResult = Data_InA | BitSelectOneHot;
    wire [BITWIDTH-1:0] BitClearResult = Data_InA & ~BitSelectOneHot;     
    wire [BITWIDTH-1:0] BitFlipResult = Data_InA ^ BitSelectOneHot;      
    wire [BITWIDTH-1:0] BitSelectResult = {BITWIDTH{Data_InA[BitIndex]}};

    // Comparisons
    wire IfSignedGreater = $signed(Data_InA) >= $signed(Data_InB);
    wire IfUnsignedGreater = $unsigned(Data_InA) >= $unsigned(Data_InB); 
    
    // Shift Amount Calculations
    wire [INDEXBITWIDTH:0] ShiftAmount = {'0, Data_InB[INDEXBITWIDTH-1:0]};

    // Rotate Right Partial Sums
    wire [(2*BITWIDTH)-1:0] RotateRightInput = {Data_InA, Data_InA};
    wire [(2*BITWIDTH)-1:0] RotateRightResult = RotateRightInput >> ShiftAmount;
    wire [BITWIDTH-1:0] ShiftRightResult = Data_InA >> ShiftAmount[INDEXBITWIDTH-1:0];
    wire [BITWIDTH-1:0] ArithmeticRightResult = $signed(Data_InA) >>> ShiftAmount[INDEXBITWIDTH-1:0];
    wire [BITWIDTH-1:0] ShiftLeftResult = Data_InA << ShiftAmount[INDEXBITWIDTH-1:0];
    
    // Bit Scaning & Reversing
        // Reversing
        genvar ReversingIndex;
        wire [BITWIDTH-1:0] ReversedData_InB;
        generate
            for (ReversingIndex = 0; ReversingIndex < BITWIDTH; ReversingIndex = ReversingIndex + 1) begin : BitFlip
                assign ReversedData_InB[ReversingIndex] = Data_InB[BITWIDTH-ReversingIndex-1];
            end
        endgenerate
        wire [BITWIDTH-1:0] ScanInput = Opcode[0] ? Data_InB : ReversedData_InB;
        // Lowest Bit Isolation
        wire [BITWIDTH-1:0] IsolatedLowerBit = ScanInput & -ScanInput;
        // Index Generation
        wire [BITWIDTH-1:0] Bitmask [INDEXBITWIDTH-1:0];
        wire [INDEXBITWIDTH-1:0] BitScanResult_temp;
        genvar CurrentMask;
        genvar CurrentBit;
        generate
            // For every Output bit
            for (CurrentMask = 0; CurrentMask < INDEXBITWIDTH; CurrentMask = CurrentMask + 1) begin : MaskScan
                // For every Input bit
                for (CurrentBit = 0; CurrentBit < BITWIDTH; CurrentBit = CurrentBit + 1) begin : BitScan
                    // Generate Bitmask
                    // if the CurrentMask-th bit of the bit index CurrentBit is set
                    // then set the CurrentBit-th bit in the CurrentMask-th bitmask to 1, else set to 0
                    assign Bitmask[CurrentMask][CurrentBit] = (CurrentBit & (1 << CurrentMask)) >> CurrentMask;
                end
                // Use Bitmask
                    // ex. (Think matrix multiplication... AND is Mult, OR is Add)
                    // Input:
                    // 0000 1000 0000 0000
                    // Mask: (AND Vertically)
                    // 1010 1010 1010 1010 b0
                    // 1111 0000 1111 0000 b1
                    // 1100 1100 1100 1100 b2
                    // 1111 1111 0000 0000 b3
                    // Partial Output: (OR Horizontally)
                    // 0000 1000 0000 0000
                    // 0000 1000 0000 0000
                    // 0000 0000 0000 0000
                    // 0000 1000 0000 0000
                    // Reduced Output:
                    // 1011
                assign BitScanResult_temp[CurrentMask] = |(IsolatedLowerBit & Bitmask[CurrentMask]);
            end
        endgenerate
        wire                    IfBZero = Data_InB == 0;
        logic [INDEXBITWIDTH:0] BitScanResult_Offset;
        wire              [1:0] BitScanResult_Condition;
        assign                  BitScanResult_Condition[0] = Opcode[0];
        assign                  BitScanResult_Condition[1] = IfBZero;
        always_comb begin : BitScanResultMux
            case (BitScanResult_Condition)
                2'b01  : BitScanResult_Offset = BitScanResult_temp + 1;
                2'b10  : BitScanResult_Offset = 0;
                2'b11  : BitScanResult_Offset = 0;
                default: BitScanResult_Offset = BITWIDTH - BitScanResult_temp;
            endcase
        end
        wire [INDEXBITWIDTH:0] BitScanResult = BitScanResult_Offset;
    //

    // Operation Mux  
    logic [BITWIDTH-1:0] TempOutput;
    always_comb begin : ALU_Simple0_OperationSelectionMux
        case (Opcode)
            4'h1   : TempOutput = BitClearResult;                  // Bit Clear
            4'h2   : TempOutput = BitFlipResult;                   // Bit Flip
            4'h3   : TempOutput = BitSelectResult;                 // Bit Select
            4'h4   : TempOutput = ShiftRightResult;                // Shift Right
            4'h5   : TempOutput = RotateRightResult[BITWIDTH-1:0]; // Rotate Right
            4'h6   : TempOutput = ArithmeticRightResult;           // Arithmatic Right Shift
            4'h7   : TempOutput = ShiftLeftResult;                 // Shift Left
            4'h8   : TempOutput = {'0, IfSignedGreater};           // Compare Greater Than Or Equal To SIGNED
            4'h9   : TempOutput = {'0, ~IfSignedGreater};          // Compare Less Than SIGNED
            4'hA   : TempOutput = {'0, IfUnsignedGreater};         // Compare Greater Than Or Equal To UNSIGNED
            4'hB   : TempOutput = {'0, ~IfUnsignedGreater};        // Compare Less Than UNSIGNED
            4'hC   : TempOutput = {'0, BitScanResult};             // Bit Scan Forwards
            4'hD   : TempOutput = {'0, BitScanResult};             // Bit Scan Backwards
            4'hE   : TempOutput = ReversedData_InB;                // Reverse B
            4'hF   : TempOutput = '0;                              // // Reserved
            default: TempOutput = BitSetResult;                    // Bit Set (Default is 4'h0) 
        endcase
    end

    // Assign Output
    //assign ResultOut = ALU_Enable ? TempOutput : 0;
    assign ResultOut = TempOutput;

endmodule                