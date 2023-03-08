module ForwardDetection (
    input clk,
    input clk_en,
    input sync_rst,

    input       ReadingFromA,
    input       WritingToA,
    input [3:0] RegisterAAddress,

    input       ReadingFromB,
    input [3:0] RegisterBAddress,

    output      Forward0ToA,
    output      Forward1ToA,
    output      Forward0ToB,
    output      Forward1ToB
);

    reg  [9:0] WriteDestinationHistory;
    wire       ActuallyWritingA = (RegisterAAddress != 0) && WritingToA;
    wire [9:0] NextWriteDestinationHistory = sync_rst ? 0 : {WriteDestinationHistory[4:0], ActuallyWritingA, RegisterAAddress};
    wire WriteDestinationHistoryTrigger = sync_rst || clk_en;
    always_ff @(posedge clk) begin
        if (WriteDestinationHistoryTrigger) begin
            WriteDestinationHistory <= NextWriteDestinationHistory;
        end
    end

    assign Forward0ToA = (RegisterAAddress == WriteDestinationHistory[3:0]) && ReadingFromA;
    assign Forward1ToA = (RegisterAAddress == WriteDestinationHistory[8:5]) && ReadingFromA;
    assign Forward0ToB = (RegisterBAddress == WriteDestinationHistory[3:0]) && ReadingFromB;
    assign Forward1ToB = (RegisterBAddress == WriteDestinationHistory[8:5]) && ReadingFromB;

endmodule : ForwardDetection
