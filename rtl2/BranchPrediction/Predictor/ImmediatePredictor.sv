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
    input                                        UpdateEnable,
    input                                        BranchTaken,
    output                                       PredictionValid,
    output                                 [1:0] Prediction
);

    // TODO: Add a Valid Bit

    // Prediction Updater
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

    wire   [LINECOUNT-1:0][LINEWIDTH-1:0][1:0] PredictionReadVector;
    genvar LINEINDEX;
    genvar PREDICTIONINDEX;
    generate
        for (LINEINDEX = 0; LINEINDEX < LINECOUNT; LINEINDEX = LINEINDEX + 1) begin : LineGeneration
            localparam LINEBITWIDTH = LINEWIDTH * 2;
            reg  [LINEBITWIDTH-1:0]   LineBuffer;
            wire [LINEWIDTH-1:0][1:0] NextLineBuffer;
            wire [LINEWIDTH-1:0][1:0] LinePredictionVector = LineBuffer;
            for (PREDICTIONINDEX = 0; PREDICTIONINDEX < LINEWIDTH; PREDICTIONINDEX = PREDICTIONINDEX + 1) begin : IndexUpdate
                // TODO: ! Need to add a reset case that sets to Weakly Taken
                assign NextLineBuffer[PREDICTIONINDEX] = UpdateIndexOneHot[PREDICTIONINDEX] ? UpdatedPrediction : LinePredictionVector[PREDICTIONINDEX];
            end
            wire LineBufferTrigger = sync_rst || (clk_en && UpdateEnable && UpdateLineSelectOneHot[LINEINDEX]);
            always_ff @(posedge clk) begin
                if (LineBufferTrigger) begin
                    LineBuffer <= NextLineBuffer;
                end
            end
            assign PredictionReadVector[LINEINDEX] = LinePredictionVector;
        end
    endgenerate
    assign Prediction = PredictionReadVector[LineAddress][Index];

endmodule : ImmediatePredictor