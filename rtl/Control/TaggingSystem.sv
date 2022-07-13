module TaggingSystem #(
    parameter TAGBITWIDTH = 6
)(
    input clk,
    input clk_en,
    input sync_rst,

    input TagREQ, // Can be thought of as "TagGen" since it is a Post-Inc

    output [TAGBITWIDTH-1:0] TagOut
);

    // Tag Register
    reg  [TAGBITWIDTH-1:0] Tag;
    wire                   TagTrigger = (TagREQ && clk_en) || sync_rst;
    wire [TAGBITWIDTH-1:0] NextTag = (sync_rst) ? 0 : (Tag + 1);
    always_ff @(posedge clk) begin
        if (TagTrigger) begin
            Tag <= NextTag;
        end
    end
    assign TagOut = Tag;

endmodule