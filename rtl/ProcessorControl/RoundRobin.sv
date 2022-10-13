module RoundRobin #(
    parameter PORTCOUNT = 4,
    parameter PORTADDRWIDTH = 2,
    parameter ROUNDROBINEN = 1
)(
    input clk,
    input clk_en,
    input sync_rst,

    input [PORTCOUNT-1:0] PortACKVector,
    output [PORTADDRWIDTH-1:0] PortSelection
);

// This module will look at n number of ports and forward the output of any active input.
// In the even of a collision, it will use port priority to select which input is serviced first.
// The port priority base index is offset by a Round Robin counter that increments every time
// a port is serviced.

    // Non Power of Two Correction Generation
        localparam SHIFTEDADJUSTMENT = 1 << PORTADDRWIDTH;
        localparam OFFSETCORRECTION_TMP = SHIFTEDADJUSTMENT - PORTCOUNT;

            // Lowest 1 isolation
        wire [PORTCOUNT-1:0] IsolatedLowerBit_Correction = PortACKVector & -PortACKVector;
        // Index Generation
        wire [PORTCOUNT-1:0] Bitmask_Correction [PORTADDRWIDTH-1:0];
        wire [PORTADDRWIDTH-1:0] BitScanResult_Correction;
        genvar CurrentMask_Correction;
        genvar CurrentBit_Correction;
        generate
            // For every Output bit
            for (CurrentMask_Correction = 0; CurrentMask_Correction < PORTADDRWIDTH; CurrentMask_Correction = CurrentMask_Correction + 1) begin : MaskScan_Correction
                // For every Input bit
                for (CurrentBit_Correction = 0; CurrentBit_Correction < PORTCOUNT; CurrentBit_Correction = CurrentBit_Correction + 1) begin : BitScan_Correction
                    // Generate Bitmask
                    // if the CurrentMask-th bit of the bit index CurrentBit is set
                    // then set the CurrentBit-th bit in the CurrentMask-th bitmask to 1, else set to 0
                    assign Bitmask_Correction[CurrentMask_Correction][CurrentBit_Correction] = (CurrentBit_Correction & (1 << CurrentMask_Correction)) >> CurrentMask_Correction;
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
                assign BitScanResult_Correction[CurrentMask_Correction] = |(IsolatedLowerBit_Correction & Bitmask_Correction[CurrentMask_Correction]);
            end
        endgenerate
        wire CorrectionEnabled = BitScanResult_Correction < PriorityIndex;
        wire [PORTADDRWIDTH-1:0] OffestCorrection = CorrectionEnabled ? OFFSETCORRECTION_TMP : '0;
    //


    // Priority Index Generation
        reg  [PORTADDRWIDTH-1:0] PriorityIndex;
        wire                     IndexLimitReached = PriorityIndex == (PORTCOUNT - 1);
        wire                     PriorityIndexTrigger = ((|PortACKVector) && clk_en) || sync_rst;
        wire [PORTADDRWIDTH-1:0] NextPriorityIndex = (sync_rst || IndexLimitReached) ? 0 : PriorityIndex + 1;
        always_ff @(posedge clk) begin
            if (PriorityIndexTrigger) begin
                PriorityIndex <= NextPriorityIndex;
            end
            // $display(" >> SHIFTEDADJUSTMENT  - %0b", SHIFTEDADJUSTMENT);
            // $display(" >> OFFSETCORRECTION   - %0d", OFFSETCORRECTION);
            $display(" >> PortIndex     - %0d", PriorityIndex);
            // $display(" >> ShiftedVec    - %04b", ShiftedPortACKVector);
            // $display(" >> LowestBit     - %04b", IsolatedLowerBit);
            $display(" >> BitScanResult - %0d", BitScanResult);
        end
    //

    // PortACKVector Priority Offest 
        wire [PORTADDRWIDTH:0] ShiftAmount = {'0, PriorityIndex[PORTADDRWIDTH-1:0]};
        wire [(2*PORTCOUNT)-1:0] DoubledPortACKVector = {PortACKVector, PortACKVector};
        wire [(2*PORTCOUNT)-1:0] ShiftedPortACKVector_Tmp = DoubledPortACKVector >> ShiftAmount;
        wire [PORTCOUNT-1:0] ShiftedPortACKVector = ShiftedPortACKVector_Tmp[PORTCOUNT-1:0];
    //

    // Bit Scaning & Reversing
        // Lowest 1 isolation
        wire [PORTCOUNT-1:0] IsolatedLowerBit = ShiftedPortACKVector & -ShiftedPortACKVector;
        // Index Generation
        wire [PORTCOUNT-1:0] Bitmask [PORTADDRWIDTH-1:0];
        wire [PORTADDRWIDTH-1:0] BitScanResult;
        genvar CurrentMask;
        genvar CurrentBit;
        generate
            // For every Output bit
            for (CurrentMask = 0; CurrentMask < PORTADDRWIDTH; CurrentMask = CurrentMask + 1) begin : MaskScan
                // For every Input bit
                for (CurrentBit = 0; CurrentBit < PORTCOUNT; CurrentBit = CurrentBit + 1) begin : BitScan
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
                assign BitScanResult[CurrentMask] = |(IsolatedLowerBit & Bitmask[CurrentMask]);
            end
        endgenerate
    //

    // Output Assignment
        assign PortSelection = BitScanResult + PriorityIndex + OffestCorrection;
    //

endmodule