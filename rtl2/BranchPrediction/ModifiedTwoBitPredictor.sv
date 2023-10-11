module ModifiedTwoBitPredictor (
    input  [1:0] StateIn,
    input        Taken,

    output [1:0] StateOut
);
    // States
    // Bin - Name               - When Taken - When Not Taken
    //  11 - Strongly Taken     - S. Taken   - W. NTaken
    //  10 - Weakly Taken       - S. Taken   - S. NTaken
    //  01 - Weakly Not Taken   - S. Taken   - S. NTaken
    //  00 - Strongly Not Taken - W. NTaken  - S. NTaken
    logic [1:0] NextPredictorState;
    wire  [2:0] PredictorStateCondition = {Taken, StateIn};
    always_comb begin : NextPredictorStateMux
        case (PredictorStateCondition)
            3'b000 : NextPredictorState = 2'b00; // S.NTaken -> S.NTaken
            3'b001 : NextPredictorState = 2'b00; // W.NTaken -> S.NTaken
            3'b010 : NextPredictorState = 2'b00; // W.Taken  -> S.NTaken
            3'b011 : NextPredictorState = 2'b01; // S.Taken  -> W.NTaken
            3'b100 : NextPredictorState = 2'b10; // S.NTaken -> W.Taken
            3'b101 : NextPredictorState = 2'b11; // W.NTaken -> S.Taken
            3'b110 : NextPredictorState = 2'b11; // W.Taken  -> S.Taken
            3'b111 : NextPredictorState = 2'b11; // S.Taken  -> S.Taken
            default: NextPredictorState = 0;
        endcase
    end
    assign StateOut = NextPredictorState;

endmodule : ModifiedTwoBitPredictor
