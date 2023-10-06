module CDC_FIFO_Counter #(
    parameter DEPTH = 16,
    // FULL_EN = 0 - CountACK lowers when FIFO is Empty;
    // FULL_EN = 1 - CountACK lowers when FIFO is Full;
    parameter FULL_EN = 0,
    //* Do Not Modify
    parameter DEPTH_BITWIDTH = (DEPTH == 1) ? 1 : $clog2(DEPTH)
)(
    input clk,
    input async_rst,

    input                       CountREQ,
    output                      CountACK,
    input    [DEPTH_BITWIDTH:0] OpposingGreyCounter,
    output [DEPTH_BITWIDTH-1:0] CountBinary,
    output   [DEPTH_BITWIDTH:0] CountGrey
);

    always_ff @(posedge clk) begin
        // $display("> Head[1]/Tail[0] - REQ:ACK:Opp:Bin:Grey - %0b:%0b:%05b:%0d:%05b", CountREQ, CountACK, OpposingGreyCounter, CountBinary, CountGrey);
    end

    //? Binary Counter
        reg  [DEPTH_BITWIDTH:0] BinaryCounter;
        wire [DEPTH_BITWIDTH:0] NextBinaryCounter = BinaryCounter + 1;
        wire                    BinaryCounterTrigger = CountREQ && CountACK;
        always_ff @(posedge clk or posedge async_rst) begin
            if (async_rst) begin
                BinaryCounter <= 0;
            end
            else if (BinaryCounterTrigger) begin
                BinaryCounter <= NextBinaryCounter;
            end
        end
    //?

    //? Grey Code Counter
        reg  [DEPTH_BITWIDTH:0] GreyCodeCounter;
        wire [DEPTH_BITWIDTH:0] ShiftedBinaryCounter = NextBinaryCounter >> 1;
        wire [DEPTH_BITWIDTH:0] NextGreyCodeCounter = NextBinaryCounter ^ ShiftedBinaryCounter;
        wire GreyCodeCounterTrigger = CountREQ && CountACK;
        always_ff @(posedge clk or posedge async_rst) begin
            if (async_rst) begin
                GreyCodeCounter <= 0;
            end
            else if (GreyCodeCounterTrigger) begin
                GreyCodeCounter <= NextGreyCodeCounter;
            end
        end
    //?

    //? Output Assignments
        wire [DEPTH_BITWIDTH:0] ComparisonTarget;
        generate
            if (FULL_EN == 0) begin
                assign ComparisonTarget = OpposingGreyCounter;
            end
            else begin
                assign ComparisonTarget = {~OpposingGreyCounter[DEPTH_BITWIDTH], OpposingGreyCounter[DEPTH_BITWIDTH-1:0]};
            end
        endgenerate
        assign CountACK = ~(ComparisonTarget == GreyCodeCounter);
        assign CountBinary = BinaryCounter[DEPTH_BITWIDTH-1:0];
        assign CountGrey = GreyCodeCounter;
    //?

endmodule : CDC_FIFO_Counter