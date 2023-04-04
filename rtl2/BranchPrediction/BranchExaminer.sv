module BranchExaminer #(
    parameter DATABITWIDTH = 16,
    // How many lower bits from the incoming address do you want to be included in the final Hash.
    parameter PRESERVEDBITCOUNT = 3, // Must be equal or less than HASHBITWIDTH - //! forced to minimum of 1
    parameter PREDICTIONLOOKUPADDRESSBITWIDTH = 6
)(
    input clk,
    input clk_en,
    input sync_rst,

    input  [DATABITWIDTH-1:0] FetchedInstructionAddress,
    input              [15:0] FetchedInstruction,

    input                     EndSpeculationPulse,
    input                     MispredictedSpeculationPulse,

    output                    Speculating,
    output                    BeginSpeculationPulse,
    output                    RelativeSpeculation, // TODO
    output                    PredictingTrue,
    output [DATABITWIDTH-1:0] SpeculativeDestination,

    output SpeculationStall // Raises when a branch comes in, but your already speculating
);

    // Speculation Status
        reg  SpeculationStatus;
        wire SpeculationRequired = FetchedInstruction[15] && ~FetchedInstruction[14] && ~ImmediateRegisterAZero;
        wire NextSpeculationStatus = ~sync_rst && SpeculationRequired && ~EndSpeculationPulse;
        wire SpeculationStatusTrigger = sync_rst || (clk_en && SpeculationRequired && ~SpeculationStatus) || EndSpeculationPulse;
        always_ff @(posedge clk) begin
            if (SpeculationStatusTrigger) begin
                SpeculationStatus <= NextSpeculationStatus;
            end
        end
        // Output Assignments
        assign BeginSpeculationPulse = SpeculationRequired && ~SpeculationStatus;
        assign RelativeSpeculation = FetchedInstruction[12];
        assign Speculating = SpeculationStatus;
        assign SpeculationStall = SpeculationRequired && SpeculationStatus;
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
                .StateOut(UpdatedGlobalPrediction),
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
            ImmediatePredictor #(
                .PREDICTIONLOOKUPADDRESSBITWIDTH(PREDICTIONLOOKUPADDRESSBITWIDTH),
                .LINECOUNT                      (3),
                .LINEWIDTH                      (3)
            ) ImmPredictor (
                .clk            (clk),
                .clk_en         (clk_en),
                .sync_rst       (sync_rst),
                .Address        (ActivePredictionAddress),
                .UpdateEnable   (EndSpeculationPulse),
                .BranchTaken    (BranchResolvedTaken),
                .PredictionValid(),
                .Prediction     ()
            );

        // Output Assignment
            logic  Prediction;
            wire   [1:0] PredictionCondition;
            assign       PredictionCondition[0] = (ImmediatePredictorValid) && ~CheckingRegisterZero;
            assign       PredictionCondition[1] = (BTBEntryValid || FetchedInstruction[12]) && ~CheckingRegisterZero;
            always_comb begin : PredictionMux
                case (PredictionCondition)
                    2'b00  : Prediction = 1'b1; // Unconditional Branch
                    2'b01  : Prediction = BTBPredition[1]; // Use BTB Prediction
                    2'b10  : Prediction = GlobalPrediction[1]; // Use Global Predictor
                    2'b11  : Prediction = ImmediatePrediction[1]; // Use Immediate Predictor
                    default: Prediction = 0;
                endcase
            end
            assign PredictingTrue = BTBEntryValid ? BTBTwoBitPredition[1] : GlobalPrediction[0];
    //

    // Destination Generation
        // Branch Target Buffer
        // Output: Entry Valid, 2bit Prediction, Speculative Destination
        // TODO:
            wire                    BTBEntryValid;
            wire              [1:0] BTBPredition;
            wire [DATABITWIDTH-1:0] BTBDestination = 0; //! set 0 till BTB is finished
        // Immediate
            wire [DATABITWIDTH-11:0] ImmediateDesinationSign = {DATABITWIDTH-10{FetchedInstruction[9]}};
            wire  [DATABITWIDTH-1:0] ImmediateDesination = {ImmediateDesinationSign, FetchedInstruction};
        // Output Assignment
            assign SpeculativeDestination = FetchedInstruction[12] ? ImmediateDesination : BTBDestination;
    //

endmodule : BranchExaminer