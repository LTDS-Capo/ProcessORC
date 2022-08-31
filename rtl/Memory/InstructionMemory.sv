module InstructionMemory (
    input clk,
    input clk_en,

    // Flashing Input
    input         FlashEn,
    input   [9:0] FlashAddr,
    input  [15:0] FlashData,

    input  [15:0] ReadAddressIn,
    output [15:0] DataOut
);

    // Memory Instantiation
    reg  [15:0] DataMemoryBlock [9:0];
    wire        WriteEn = clk_en && FlashEn;
    always_ff @(posedge clk) begin
        if (WriteEn) begin
            DataMemoryBlock[FlashAddr] <= FlashData;
        end
    end

    // Output Assignments
    assign DataOut = DataMemoryBlock[ReadAddressIn[9:0]];

endmodule