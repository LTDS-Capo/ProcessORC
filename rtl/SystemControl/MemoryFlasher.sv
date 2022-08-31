module MemoryFlasher #(
    parameter MEMMAPSTARTADDR = 384,
    parameter MEMMAPENDADDR = 511,
)(
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

    // Needs to support the fact that Data has 512 addresses of 16byte data...
    // Data has 1024 addresses of 16byte data...

    parameter FINAL_MEMMAPSTARTADDR = MEMMAPSTARTADDR / 2;
    parameter FINAL_MEMMAPENDADDR = (MEMMAPENDADDR - 1) / 2;

    // Active Register
    reg  [1:0] Active;
    wire       ActiveTrigger = (FlashFinished && clk_en) || (FlashInit && clk_en) || sync_rst;
    wire       FlashFinished = FlashAddress[10];
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
    reg   [10:0] FlashAddress;
    wire         FlashAddressTrigger = (Active[0] && clk_en) || sync_rst;
    logic [10:0] NextFlashAddress;
    wire   [1:0] NextFlashAddressCondition;
    wire   [8:0] MemMapStart = FINAL_MEMMAPSTARTADDR;
    wire   [8:0] MemMapEnd = FINAL_MEMMAPENDADDR;
    wire  [10:0] MemMapCompareAddr = {2'b01, MemMapStart}
    wire         MemMapSkipTrigger = FlashAddr == MemMapCompareAddr;
    assign NextFlashAddressCondition[0] = clk_en && ~sync_rst;
    assign NextFlashAddressCondition[1] = MemMapSkipTrigger && ~sync_rst;
    always_comb begin : NextFlashAddressMux
        case (NextFlashAddressCondition)
            2'b01  : NextFlashAddress = FlashAddress + 1;
            2'b10  : NextFlashAddress = {FlashAddress[10:9] , MemMapEnd};
            2'b11  : NextFlashAddress = {FlashAddress[10:9] , MemMapEnd};
            default: NextFlashAddress = '0; // Default is also case 0
        endcase
    end
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
    assign FlashAddr = {FlashAddress[8:0], 1'b0};
    assign FlashData = FlashAddress[9] ? CurrentData : CurrentInstruction;  
    assign InstFlashEn = Active[0] && ~FlashAddress[9] && ~FlashFinished;
    assign DataFlashEn = Active[0] && FlashAddress[9] && ~FlashFinished;


endmodule