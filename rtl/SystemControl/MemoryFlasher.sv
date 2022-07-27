// /* VALIDATED */
module MemoryFlasher (
    input clk,
    input clk_en,
    input sync_rst,

    input         FlashInit,

    output        InstFlashEn,
    output        DataFlashEn,
    output  [9:0] FlashAddr,
    output [15:0] FlashData,

    output SystemEnable
);

    // Active Register
    reg  [1:0] Active;
    wire       ActiveTrigger = (FlashFinished && clk_en) || (FlashInit && clk_en) || sync_rst;
    wire       FlashFinished = FlashAddress[11];
    // wire       FlashFinished = FlashAddress[5]; // FOR TESTING
    wire [1:0] NextActive;
    assign     NextActive[0] = FlashInit && ~FlashFinished && ~sync_rst;
    assign     NextActive[1] = FlashFinished && ~sync_rst;
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            Active[0] <= NextActive[0];
            Active[1] <= NextActive[1];
        end
    end

    // Address Generation
    reg  [11:0] FlashAddress;
    wire        FlashAddressTrigger = (Active[0] && clk_en) || sync_rst;
    wire [11:0] NextFlashAddress = (sync_rst) ? 0 : FlashAddress + 1;
    always_ff @(posedge clk) begin
        if (FlashAddressTrigger) begin
            FlashAddress <= NextFlashAddress;
        end
    end

    // Instruction ROM
    wire [15:0] CurrentInstruction;
    FlashROM_Instruction InstROM (
        .Address(FlashAddress[9:0]),
        .Value  (CurrentInstruction)
    );

    // Data ROM
    wire [15:0] CurrentData;
    FlashROM_Data DataROM (
        .Address(FlashAddress[9:0]),
        .Value  (CurrentData)
    );

    // Output Assignments
    assign SystemEnable = Active[1];
    assign FlashAddr = FlashAddress[9:0];
    assign FlashData = FlashAddress[10] ? CurrentData : CurrentInstruction; 
    assign InstFlashEn = Active[0] && ~FlashAddress[10] && ~FlashFinished;
    assign DataFlashEn = Active[0] && FlashAddress[10] && ~FlashFinished;


endmodule