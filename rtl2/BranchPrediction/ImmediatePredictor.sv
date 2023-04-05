module ImmediatePredictor #(
    parameter PREDICTIONLOOKUPADDRESSBITWIDTH = 6,
    //! BELOW MUST BE TRUE!
    // LINECOUNT*LINEWIDTH == 2^HASHBITWIDTH
    parameter LINECOUNT = 8,
    parameter LINEWIDTH = 8
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  [PREDICTIONLOOKUPADDRESSBITWIDTH-1:0] Address,
    input                                        PredictingImmediateBranch,
    input                                        UpdateEnable,
    input                                        BranchTaken,
    output                                       PredictionValid,
    output                                 [1:0] Prediction
);

    // Prediction Updater
        // Existing Prediction
        wire [1:0] UpdatedPrediction;
        ModifiedTwoBitPredictor ImmediatePredictionUpdate (
            .StateIn (Prediction),
            .Taken   (BranchTaken),
            .StateOut(UpdatedPrediction)
        );
    //

    // Generate Addresses
        localparam LINESELECTBITWITDH = (LINECOUNT == 1) ? 1 : $clog2(LINECOUNT);
        localparam LINEADDRESSLSB = PREDICTIONLOOKUPADDRESSBITWIDTH - LINESELECTBITWITDH;
        wire  [LINESELECTBITWITDH-1:0] LineAddress = Address[PREDICTIONLOOKUPADDRESSBITWIDTH-1:LINEADDRESSLSB];
        logic [LINECOUNT-1:0] UpdateLineSelectOneHot;
        always_comb begin
            UpdateLineSelectOneHot = 0;
            UpdateLineSelectOneHot[LineAddress] = 1'b1;
        end
        localparam PREDICTIONSELECTBITWITDH = (LINEWIDTH == 1) ? 1 : $clog2(LINEWIDTH);
        wire [PREDICTIONSELECTBITWITDH-1:0] Index = Address[PREDICTIONSELECTBITWITDH-1:0];
        logic [LINEWIDTH-1:0] UpdateIndexOneHot;
        always_comb begin
            UpdateIndexOneHot = 0;
            UpdateIndexOneHot[Index] = 1'b1;
        end
    //

    // Prediction Array
        wire   [LINECOUNT-1:0][LINEWIDTH-1:0][2:0] PredictionReadVector;
        genvar LINEINDEX;
        genvar PREDICTIONINDEX;
        generate
            for (LINEINDEX = 0; LINEINDEX < LINECOUNT; LINEINDEX = LINEINDEX + 1) begin : LineGeneration
                localparam LINEBITWIDTH = LINEWIDTH * 3;
                reg  [LINEBITWIDTH-1:0]   LineBuffer;
                wire [LINEWIDTH-1:0][2:0] NextLineBuffer;
                wire [LINEWIDTH-1:0][2:0] LinePredictionVector = LineBuffer;
                for (PREDICTIONINDEX = 0; PREDICTIONINDEX < LINEWIDTH; PREDICTIONINDEX = PREDICTIONINDEX + 1) begin : IndexUpdate
                    logic  [2:0] NextIndexedPrediction;
                    wire   [1:0] NextIndexedPredictionCondition;
                    assign       NextIndexedPredictionCondition[0] = UpdateIndexOneHot[PREDICTIONINDEX]|| sync_rst;
                    assign       NextIndexedPredictionCondition[1] = sync_rst;
                    always_comb begin : NextIndexedPredictionMux
                        case (NextIndexedPredictionCondition)
                            2'b00  : NextIndexedPrediction = LinePredictionVector[PREDICTIONINDEX]; // Preserve Existing Predition
                            2'b01  : NextIndexedPrediction = {1'b1, UpdatedPrediction}; // Updating & New Predictions
                            2'b10  : NextIndexedPrediction = 3'b010; //! Error - Not Valid, Weakly Taken
                            2'b11  : NextIndexedPrediction = 3'b010; // sync_rst - Not Valid, Weakly Taken
                            default: NextIndexedPrediction = 0;
                        endcase
                    end
                    assign NextLineBuffer[PREDICTIONINDEX] = NextIndexedPrediction;
                end
                wire LineBufferTrigger = sync_rst || (clk_en && UpdateEnable && UpdateLineSelectOneHot[LINEINDEX] && PredictingImmediateBranch);
                always_ff @(posedge clk) begin
                    if (LineBufferTrigger) begin
                        LineBuffer <= NextLineBuffer;
                    end
                end
                assign PredictionReadVector[LINEINDEX] = LinePredictionVector;
            end
        endgenerate
    //

    // Output Assignments
        assign PredictionValid = PredictionReadVector[LineAddress][Index][2];
        assign Prediction = PredictionReadVector[LineAddress][Index][1:0];
    //

endmodule : ImmediatePredictor