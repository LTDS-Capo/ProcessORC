module RunaheadSpeculativeClearQueue #(
    parameter COUNTERBITWIDTH = 6,
    parameter QUEUEDEPTH = 8
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                        FetchedInstructionValid,
    output                       ClearQueueFull,
    input                        Speculating,
    input                        EndSpeculationPulse,
    input                        MispredictedSpeculationPulse,

    input                        SpeculativeHeadOfRunahead,
    input                        RunaheadInstrucionValid,
    input                        MispredictionQueueACK,
    output                       ClearQueueValid,
    output                       ClearQueueMisprediction,
    output [COUNTERBITWIDTH-1:0] ClearQueueSpeculativeDepth
);

    //? Current Speculation Depth
    //! Clear Queue Output Valid
    // Add 1 to a counter every time a speculative instruction is added to the runahead queue
    // - When recieving a EndSpeculationPulse; Push Counter and Mispredicted bit to Clear Queue, Clear Counter
    //! Clear Queue Output Not Valid
    // Counter Modifiction:
    // - Enqueue Speculative Instruction WITHOUT Issuing Speculative Instruction -> Add 1
    // -    Enqueue Speculative Instruction WITH Issuing Speculative Instruction -> Do Nothing
    // - Issuing Speculative Instruction WITHOUT Enqueue Speculative Instruction -> Subtract 1
    // -                                                                sync_rst -> Clear to 0
    // When recieving a EndSpeculationPulse;
    // - If Counter == 0 -> Do Nothing
    // - If Counter != 0 -> Add the current output of the Clear Queue to the RunaheadFIFO's Tail, Clear Counter
    reg    [COUNTERBITWIDTH-1:0] CurrentSpeculationDepth;
    logic  [COUNTERBITWIDTH-1:0] NextCurrentSpeculationDepth;
    wire   [1:0] NextCurrentSpeculationDepthCondition;
    assign       NextCurrentSpeculationDepthCondition[0] = FetchedInstructionValid && Speculating && ~EndSpeculationPulse && ~sync_rst;
    assign       NextCurrentSpeculationDepthCondition[1] = SpeculativeHeadOfRunahead && RunaheadInstrucionValid && ~ClearQueueOutputREQ && ~EndSpeculationPulse && ~sync_rst;
    always_comb begin : NextCurrentSpeculationDepthMux
        case (NextCurrentSpeculationDepthCondition)
            2'b00  : NextCurrentSpeculationDepth = 0;                           // sync_rst
            2'b01  : NextCurrentSpeculationDepth = CurrentSpeculationDepth + 1; // Enqueue Speculative Instruction
            2'b10  : NextCurrentSpeculationDepth = CurrentSpeculationDepth - 1; // Issue Speculative Instruction
            2'b11  : NextCurrentSpeculationDepth = CurrentSpeculationDepth;     // Enqueue & Issue Speculative Instruction
            default: NextCurrentSpeculationDepth = 0;
        endcase
    end
    
    wire CurrentSpeculationDepthTrigger = sync_rst || (clk_en && FetchedInstructionValid && Speculating) || (clk_en && SpeculativeHeadOfRunahead && RunaheadInstrucionValid && ~ClearQueueOutputREQ) || (clk_en && EndSpeculationPulse);
    always_ff @(posedge clk) begin
        if (CurrentSpeculationDepthTrigger) begin
            CurrentSpeculationDepth <= NextCurrentSpeculationDepth;
        end
    end
    //

    //? Speculation Clear Queue
    // Entry: {Mispredicted, SpeculationDepth}
        localparam FIFOINDEXBITWIDTH = (QUEUEDEPTH == 1) ? 1 : $clog2(QUEUEDEPTH);
        wire                         ClearQueueInputREQ = EndSpeculationPulse && (CurrentSpeculationDepth != 0) && ~(ClearQueueOutputREQ && SpeculativeHeadOfRunahead && MispredictedSpeculationPulse);
        wire                         ClearQueueInputACK;
        wire     [COUNTERBITWIDTH:0] ClearQueueInputData = {MispredictedSpeculationPulse, CurrentSpeculationDepth};
        wire [FIFOINDEXBITWIDTH-1:0] FIFOTailOffset = 1;
        wire                         ClearQueueOutputREQ;
        wire                         ClearQueueOutputACK = (ValidationDepthCheck && SpeculativeHeadOfRunahead && RunaheadInstrucionValid && ~ClearQueueMisprediction) || (SpeculativeHeadOfRunahead && RunaheadInstrucionValid && ~ClearQueueMisprediction) || MispredictionQueueACK;
        wire     [COUNTERBITWIDTH:0] ClearQueueOutputDATA;
        BufferedFIFO #(
            .DATABITWIDTH(COUNTERBITWIDTH+1),
            .FIFODEPTH   (QUEUEDEPTH)
        ) ClearQueue (
            .clk           (clk),
            .clk_en        (clk_en),
            .sync_rst      (sync_rst),
            .InputREQ      (ClearQueueInputREQ),
            .InputACK      (ClearQueueInputACK),
            .InputData     (ClearQueueInputData),
            .OutputREQ     (ClearQueueOutputREQ),
            .OutputACK     (ClearQueueOutputACK),
            .FIFOTailOffset(FIFOTailOffset),
            .OutputData    (ClearQueueOutputDATA)
        );
        assign ClearQueueFull = ~ClearQueueInputACK;
    //

    //? Runahead Validation Depth
    //! Id Mispredicted:
    // When Clear Queue has a valid output that is marked Mispredicted,
    //   Add the current output of the Clear Queue to the RunaheadFIFO's Tail. ACK Output
    //! If Properly Prediced:
    // When Clear Queue has a valid output that is marked Predicted Correct,
    //   Count amount of executed properly speculated instructions until the value
    //   matches the current output of the Clear Queue. ACK Output.
        reg      [COUNTERBITWIDTH:0] ValidationDepth;
        logic    [COUNTERBITWIDTH:0] NextValidationDepth;
        wire                   [1:0] NextValidationDepthCondition;
        assign                       NextValidationDepthCondition[0] = ClearQueueOutputREQ && ~ValidationDepthCheck && ~ValidationIsOne && ~sync_rst;
        assign                       NextValidationDepthCondition[1] = ValidationDepthCheck && ~ValidationIsOne && ~sync_rst;
        wire                         ValidationIsOne = ValidationDepth == 1;
        wire   [COUNTERBITWIDTH-1:0] ValidationDepthMinusOne = ValidationDepth[COUNTERBITWIDTH-1:0] - 1;
        always_comb begin : NextValidationDepthMux
            case (NextValidationDepthCondition)
                2'b00  : NextValidationDepth = 0; // Default sync_rst output
                2'b01  : NextValidationDepth = {1'b1, ClearQueueOutputDATA[COUNTERBITWIDTH-1:0]};
                2'b10  : NextValidationDepth = {1'b1, ValidationDepthMinusOne};
                2'b11  : NextValidationDepth = {1'b1, ClearQueueOutputDATA[COUNTERBITWIDTH-1:0]};
                default: NextValidationDepth = 0;
            endcase
        end
        wire ValidationDepthTrigger = sync_rst || (clk_en && SpeculativeHeadOfRunahead && RunaheadInstrucionValid && ClearQueueOutputREQ && ~ClearQueueMisprediction) && (clk_en && ClearQueueOutputREQ && ~ValidationDepthCheck && ~ClearQueueMisprediction);
        always_ff @(posedge clk) begin
            if (ValidationDepthTrigger) begin
                ValidationDepth <= NextValidationDepth;
            end
        end
        wire ValidationDepthCheck = ValidationDepth[COUNTERBITWIDTH];
        // Output Assignments
        assign ClearQueueValid = ClearQueueMisprediction ? ClearQueueOutputREQ : ValidationDepthCheck;
        assign ClearQueueMisprediction = ClearQueueOutputDATA[COUNTERBITWIDTH] && ClearQueueOutputREQ;
        assign ClearQueueSpeculativeDepth = ClearQueueOutputREQ ? ClearQueueOutputDATA[COUNTERBITWIDTH-1:0] : CurrentSpeculationDepth;
    //


endmodule : RunaheadSpeculativeClearQueue