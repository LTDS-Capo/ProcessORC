module RoundRobinPortPriority #(
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

    // Priority Index Generation
        reg  [PORTADDRWIDTH-1:0] PriorityIndex;
        wire                     PriorityIndexTrigger = ((|PortACKVector) && clk_en) || sync_rst;
        wire [PORTADDRWIDTH-1:0] NextPriorityIndex = (sync_rst) ? 0 : PriorityIndex + 1;
        always_ff @(posedge clk) begin
            if (PriorityIndexTrigger) begin
                PriorityIndex <= NextPriorityIndex;
            end
            $display(" >> PortIndex     - %0d", PriorityIndex);
            $display(" >> ShiftedVec    - %04b", ShiftedPortACKVector);
            $display(" >> LowestBit     - %04b", IsolatedLowerBit);
            $display(" >> BitScanResult - %04b", BitScanResult);
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
        assign PortSelection = BitScanResult + PriorityIndex;
    //

endmodule