module TagComparisonUnit #(
    parameter TAGBITWIDTH = 6
)(
    input                    AValid,
    input  [TAGBITWIDTH-1:0] ATag,
 
    input                    BValid,
    input  [TAGBITWIDTH-1:0] BTag,

    output                   SelectedValue, // 0 for A, 1 for B
    output                   OutValid,
    output [TAGBITWIDTH-1:0] OutTag
);
    
    // wire BLessThanA = BTag <= ATag;

    wire BLessThanA = BTag[TAGBITWIDTH-2:0] <= ATag[TAGBITWIDTH-2:0];
    wire WrapCheck = BTag[TAGBITWIDTH-1] ^ ATag[TAGBITWIDTH-1];
    wire ProperLessThan = WrapCheck ^ BLessThanA;

    wire BSelect = (ProperLessThan && AValid && BValid) || (BValid && ~AValid);

    assign SelectedValue = ProperLessThan;
    assign OutValid = AValid || BValid;
    assign OutTag = BSelect ? BTag : ATag;




endmodule