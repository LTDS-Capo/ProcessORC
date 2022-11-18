module MemoryFlasher #(
    parameter MEMMAPSTARTADDR = 384,
    parameter MEMMAPENDADDR = 511
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

    // Active Register
    reg  [1:0] Active;
    wire       ActiveTrigger = (FlashFinished && clk_en) || (FlashInit && clk_en) || sync_rst;
    wire       FlashFinished = FlashAddress[11];
    wire [1:0] NextActive;
    assign     NextActive[0] = FlashInit && ~FlashFinished && ~sync_rst;
    assign     NextActive[1] = FlashFinished && ~sync_rst;
    always_ff @(posedge clk) begin
        if (ActiveTrigger) begin
            Active[0] <= NextActive[0];
            Active[1] <= NextActive[1];
        end
        $display("FlashAddress - %012b", FlashAddress);
        $display(" CompareAddr - %012b", MemMapCompareAddr);
        $display(" FACondition - %02b", NextFlashAddressCondition);
        $display(" SkipTrigger - %01b", MemMapSkipTrigger);
    end

    // Address Generation
    reg   [11:0] FlashAddress;
    wire         FlashAddressTrigger = (Active[0] && clk_en) || sync_rst;
    logic [11:0] NextFlashAddress;
    wire   [1:0] NextFlashAddressCondition;
    wire   [9:0] MemMapStart = MEMMAPSTARTADDR;
    wire   [9:0] MemMapEnd = MEMMAPENDADDR + 1;
    wire  [11:0] MemMapCompareAddr = {2'b01, MemMapStart};
    wire         MemMapSkipTrigger = (FlashAddress == MemMapCompareAddr);
    assign NextFlashAddressCondition[0] = Active[0] && (~FlashAddress[10] || MemMapSkipTrigger) && ~sync_rst;
    assign NextFlashAddressCondition[1] = FlashAddress[10] && ~sync_rst;
    always_comb begin : NextFlashAddressMux
        case (NextFlashAddressCondition)
            2'b01  : NextFlashAddress = FlashAddress + 1;
            2'b10  : NextFlashAddress = FlashAddress + 2;
            2'b11  : NextFlashAddress = {FlashAddress[11:10] , MemMapEnd};
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
    assign FlashAddr = FlashAddress[9:0];
    assign FlashData = FlashAddress[10] ? CurrentData : CurrentInstruction;  
    assign InstFlashEn = Active[0] && ~FlashAddress[10] && ~FlashFinished;
    assign DataFlashEn = Active[0] && FlashAddress[10] && ~FlashFinished;


endmodule