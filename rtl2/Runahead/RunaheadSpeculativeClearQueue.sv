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
    output                       ClearQueueValid,
    output [COUNTERBITWIDTH-1:0] CurrentSpeculativeDepth
);

    //* Current Speculation Depth
    //! Clear Queue Output Valid
    // Add 1 to a counter every time a speculative instruction is added to the runahead queue
    // - When recieving a EndSpeculationPulse; Push Counter and Mispredicted bit to Clear Queue, Clear Counter
    //! Clear Queue Output Not Valid
    // Counter Modifiction:
    // - Enqueue Speculative Instruction WITHOUT Issuing Speculative Instruction -> Add 1
    // - Enqueue Speculative Instruction WITH Issuing Speculative Instruction -> Do Nothing
    // - Issuing Speculative Instruction WITHOUT Enqueue Speculative Instruction -> Subtract 1
    // When recieving a EndSpeculationPulse;
    // - If Counter == 0 -> Do Nothing
    // - If Counter != 0 -> Add the current output of the Clear Queue to the RunaheadFIFO's Tail, Clear Counter
    
    //*

    //* Speculation Clear Queue
    // Entry: {Mispredicted, SpeculationDepth}
        localparam FIFOINDEXBITWIDTH = (QUEUEDEPTH == 1) ? 1 : $clog2(QUEUEDEPTH);
        wire [FIFOINDEXBITWIDTH-1:0] FIFOTailOffset = 1;
        BufferedFIFO #(
            .DATABITWIDTH(COUNTERBITWIDTH+1),
            .FIFODEPTH   (QUEUEDEPTH)
        ) ClearQueue (
            .clk       (clk),
            .clk_en    (clk_en),
            .sync_rst  (sync_rst),
            .InputREQ  (),
            .InputACK  (),
            .InputData (),
            .OutputREQ (),
            .OutputACK (),
            .FIFOTailOffset(FIFOTailOffset),
            .OutputData()
        );
    //*

    //* Runahead Validation Depth
    //! Id Mispredicted:
    // When Clear Queue has a valid output that is marked Mispredicted,
    //   Add the current output of the Clear Queue to the RunaheadFIFO's Tail. ACK Output
    //! If Properly Prediced:
    // When Clear Queue has a valid output that is marked Predicted Correct,
    //   Count amount of executed properly speculated instructions until the value
    //   matches the current output of the Clear Queue. ACK Output.

    //*


endmodule : RunaheadSpeculativeClearQueue