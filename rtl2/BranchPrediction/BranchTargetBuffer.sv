module BranchTargetBuffer #(
    parameter DATABITWIDTH = 16,
    parameter PREDICTORDEPTH = 64,
    parameter PREDICTORINDEXBITWIDTH = (PREDICTORDEPTH == 1) ? 1 : $clog2(PREDICTORDEPTH)
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  [PREDICTORINDEXBITWIDTH-1:0] Address,
    input                               PredictingRegisterBranch,
    input                               UpdateEnable,
    input            [DATABITWIDTH-1:0] ActualDestination, 
    input                               BranchTaken,
    output                              PredictionValid,
    output                        [1:0] Prediction,
    output           [DATABITWIDTH-1:0] PredictedDestination
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

    // Prediction Array
        // TODO this needs a proper reset mechanism... this wont work, put them in a genblock like the registers
        reg  [DATABITWIDTH+1:0] PredictionArray [PREDICTORDEPTH-1:0];
        wire [DATABITWIDTH-1:0] ZeroPadd = 0;
        // resets to weakly not-taken
        wire [DATABITWIDTH+1:0] NextIndexedPrediction = sync_rst ? {2'b01, ZeroPadd} : {UpdatedPrediction, ActualDestination};
        wire PredictionArrayTrigger = sync_rst || (clk_en && UpdateEnable && PredictingRegisterBranch);
        always_ff @(posedge clk) begin
            if (PredictionArrayTrigger) begin
                PredictionArray[Address] <= NextIndexedPrediction;
            end
        end
        // Prediction Valid Vector
        reg   [PREDICTORDEPTH-1:0] ValidPredictionVector;
        logic [PREDICTORDEPTH-1:0] DecodedPredictionAddress;
        always_comb begin
            DecodedPredictionAddress = 0;
            DecodedPredictionAddress[Address] = 1'b1;
        end
        wire [PREDICTORDEPTH-1:0] NextValidPredictionVector = sync_rst ? 0 : (ValidPredictionVector | DecodedPredictionAddress);
        always_ff @(posedge clk) begin
            if (PredictionArrayTrigger) begin
                ValidPredictionVector <= NextValidPredictionVector;
            end
        end
    //

    // Output Assignments
        assign PredictionValid = ValidPredictionVector[Address];
        assign Prediction = PredictionArray[Address][DATABITWIDTH+1:DATABITWIDTH];
        assign PredictedDestination = PredictionArray[Address][DATABITWIDTH-1:0];
    //

endmodule : BranchTargetBuffer