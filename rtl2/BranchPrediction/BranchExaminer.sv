module BranchExaminer #(
    parameter DATABITWIDTH = 16,
    // How many lower bits from the incoming address do you want to be included in the final Hash.
    parameter PRESERVEDBITCOUNT = 3, // Must be equal or less than HASHBITWIDTH - //! forced to minimum of 1
    parameter PREDICTIONLOOKUPADDRESSBITWIDTH = 6 //! Do Not Change ... for now, not parameterized properly
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  [DATABITWIDTH-1:0] FetchedInstructionAddress,
    input              [15:0] FetchedInstruction,

    input                     EndSpeculationPulse,
    input  [DATABITWIDTH-1:0] ActualDestination,
    input                     MispredictedSpeculationPulse,

    output                    Speculating,
    output                    BeginSpeculationPulse,
    output                    RelativeSpeculation,
    output                    PredictingTrue,
    output [DATABITWIDTH-1:0] SpeculativeDestination,

    output SpeculationStall // Raises when a branch comes in, but your already speculating
);

    //! START_NOTE:
    //* Potentially have a mechanism for flushing the predictors
    //! END_NOTE:

    // Speculation Status
        reg  [1:0] SpeculationStatus;
        wire       SpeculationRequired = FetchedInstruction[15] && ~FetchedInstruction[14] && ~ImmediateRegisterAZero;
        wire [1:0] NextSpeculationStatus = sync_rst ? 0 : {FetchedInstruction[12], SpeculationRequired};
        wire       SpeculationStatusTrigger = sync_rst || (clk_en && SpeculationRequired && ~SpeculationStatus[0]) || EndSpeculationPulse;
        always_ff @(posedge clk) begin
            if (SpeculationStatusTrigger) begin
                SpeculationStatus <= NextSpeculationStatus;
            end
        end
        wire   PredictingImmediateBranch = SpeculationStatus[1] && SpeculationStatus[0];
        wire   PredictingRegisterBranch = ~SpeculationStatus[1] && SpeculationStatus[0];
        // Output Assignments
        assign BeginSpeculationPulse = SpeculationRequired && ~SpeculationStatus[0];
        assign RelativeSpeculation = FetchedInstruction[12] || PredictingRegisterBranch;
        assign Speculating = SpeculationStatus[0];
        assign SpeculationStall = SpeculationRequired && SpeculationStatus[0];
    //

    // Prediction Address Generation
        // Generation
        wire [PREDICTIONLOOKUPADDRESSBITWIDTH-1:0] PredictionLookupAddress;
        InstructionAddressHashing #(
            .DATABITWIDTH(DATABITWIDTH),
            .PRESERVEDBITCOUNT(PRESERVEDBITCOUNT),
            .HASHBITWIDTH(PREDICTIONLOOKUPADDRESSBITWIDTH)
        ) AddressGeneration (
            .InstructionAddress(FetchedInstructionAddress),
            .HashedAddress     (PredictionLookupAddress)
        );
        // Address Buffer for Updating Post-Speculation
        reg  [PREDICTIONLOOKUPADDRESSBITWIDTH-1:0] SpeculationUpdateAddress;
        wire [PREDICTIONLOOKUPADDRESSBITWIDTH-1:0] NextSpeculationUpdateAddress = sync_rst ? 0 : (PredictionLookupAddress);
        wire SpeculationUpdateAddressTrigger = sync_rst || (clk_en && BeginSpeculationPulse);
        always_ff @(posedge clk) begin
            if (SpeculationUpdateAddressTrigger) begin
                SpeculationUpdateAddress <= NextSpeculationUpdateAddress;
            end
        end
        wire [PREDICTIONLOOKUPADDRESSBITWIDTH-1:0] ActivePredictionAddress = Speculating ? SpeculationUpdateAddress : PredictionLookupAddress;
    //

    // Predictor
        wire BranchResolvedTaken = ~MispredictedSpeculationPulse;
        // Unconditional Detection
            wire ImmediateRegisterAZero = ~FetchedInstruction[11] && ~FetchedInstruction[10] && FetchedInstruction[12];
            wire NonImmediateRegisterAZero = ~FetchedInstruction[11] && ~FetchedInstruction[10] && ~FetchedInstruction[9] && ~FetchedInstruction[8] && ~FetchedInstruction[12];
            wire CheckingRegisterZero = ImmediateRegisterAZero || NonImmediateRegisterAZero;
        // Global Predictor
            reg  [1:0] GlobalPrediction;
            wire [1:0] UpdatedGlobalPrediction;
            ModifiedTwoBitPredictor GlobalPredictor (
                .StateIn (GlobalPrediction),
                .Taken   (BranchResolvedTaken),
                .StateOut(UpdatedGlobalPrediction)
            );
            wire [1:0] NextGlobalPrediction = sync_rst ? 0 : (UpdatedGlobalPrediction);
            wire GlobalPredictionTrigger = sync_rst || (clk_en && EndSpeculationPulse);
            always_ff @(posedge clk) begin
                if (GlobalPredictionTrigger) begin
                    GlobalPrediction <= NextGlobalPrediction;
                end
            end
        // Immediate Predictor
        // > Stores 2 bit values for branches issued in the past, based on Instruction Address.
            wire       ImmediatePredictorValid;
            wire [1:0] ImmediatePrediction;
            ImmediatePredictor #(
                .PREDICTIONLOOKUPADDRESSBITWIDTH(PREDICTIONLOOKUPADDRESSBITWIDTH),
                .LINECOUNT                      (3),
                .LINEWIDTH                      (3)
            ) ImmPredictor (
                .clk                      (clk),
                .clk_en                   (clk_en),
                .sync_rst                 (sync_rst),
                .Address                  (ActivePredictionAddress),
                .PredictingImmediateBranch(PredictingImmediateBranch),
                .UpdateEnable             (EndSpeculationPulse),
                .BranchTaken              (BranchResolvedTaken),
                .PredictionValid          (ImmediatePredictorValid),
                .Prediction               (ImmediatePrediction)
            );

        // Output Assignment
            logic  Prediction;
            wire   [1:0] PredictionCondition;
            assign       PredictionCondition[0] = (ImmediatePredictorValid) && ~CheckingRegisterZero;
            assign       PredictionCondition[1] = (BTBEntryValid || FetchedInstruction[12]) && ~CheckingRegisterZero;
            always_comb begin : PredictionMux
                case (PredictionCondition)
                    2'b00  : Prediction = 1'b1; // Unconditional Branch
                    2'b01  : Prediction = BTBPrediction[1]; // Use BTB Prediction
                    2'b10  : Prediction = GlobalPrediction[1]; // Use Global Predictor
                    2'b11  : Prediction = ImmediatePrediction[1]; // Use Immediate Predictor
                    default: Prediction = 0;
                endcase
            end
            assign PredictingTrue = BTBEntryValid ? BTBPrediction[1] : GlobalPrediction[0];
    //

    // Destination Generation
        // Branch Target Buffer
        // Output: Entry Valid, 2bit Prediction, Speculative Destination
        // TODO:
            wire                    BTBEntryValid;
            wire              [1:0] BTBPrediction;
            wire [DATABITWIDTH-1:0] BTBDestination;
            BranchTargetBuffer #(
                .DATABITWIDTH  (DATABITWIDTH),
                .PREDICTORDEPTH(64)
            ) BTBPredictor (
                .clk                      (clk),
                .clk_en                   (clk_en),
                .sync_rst                 (sync_rst),
                .Address                  (ActivePredictionAddress),
                .PredictingRegisterBranch (PredictingRegisterBranch),
                .UpdateEnable             (EndSpeculationPulse),
                .ActualDestination        (ActualDestination),
                .BranchTaken              (BranchResolvedTaken),
                .PredictionValid          (BTBEntryValid),
                .Prediction               (BTBPrediction),
                .PredictedDestination     (BTBDestination)
            );
        // Immediate
            wire [DATABITWIDTH-11:0] ImmediateDesinationSign = {DATABITWIDTH-10{FetchedInstruction[9]}};
            wire  [DATABITWIDTH-1:0] ImmediateDesination = {ImmediateDesinationSign, FetchedInstruction};
        // Output Assignment
            assign SpeculativeDestination = FetchedInstruction[12] ? ImmediateDesination : BTBDestination;
    //

endmodule : BranchExaminer