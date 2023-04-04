module PriorityEncoder #(
    parameter DATABITWIDTH = 16,
    parameter INDEXBITWIDTH = (DATABITWIDTH == 1) ? 1 : $clog2(DATABITWIDTH)
)(
    input   [DATABITWIDTH-1:0] DataInput,
    output [INDEXBITWIDTH-1:0] LowestOneIndex
);

    // Lowest Bit Isolation
    wire [DATABITWIDTH-1:0] IsolatedLowerBit = DataInput & -DataInput;
    // Index Generation
    wire [DATABITWIDTH-1:0] Bitmask [INDEXBITWIDTH-1:0];
    wire [INDEXBITWIDTH-1:0] BitScanResult_temp;
    genvar CurrentMask;
    genvar CurrentBit;
    generate
        // For every Output bit
        for (CurrentMask = 0; CurrentMask < INDEXBITWIDTH; CurrentMask = CurrentMask + 1) begin : MaskScan
            // For every Input bit
            for (CurrentBit = 0; CurrentBit < DATABITWIDTH; CurrentBit = CurrentBit + 1) begin : BitScan
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
    assign LowestOneIndex = BitScanResult_temp;

endmodule : PriorityEncoder