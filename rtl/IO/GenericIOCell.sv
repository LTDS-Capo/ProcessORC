module GenericIOCell (
    input clk2p5,
    input clk_en,
    input sync_rst,

    input        CellSelect,
    input  [2:0] CellOperation,
    input        DataIn,

    output       CellState,

    input        CellIn,
    output       CellOut,
    output       CellOutEnable,

    input  [3:0] ADDRTEST
);
    
    // Command Decode
    wire UpdateCell = CellOperation[2];
    wire PulseOutput = CellOperation[1];
    wire LatchDataIn = CellOperation[0];


    // Input Buffer
    // Notes:
    // In:
    // Out:
        reg  InputBuffer;
        wire InputBufferTrigger = (UpdateCell && CellSelect && clk_en) || sync_rst;
        wire NextInputBuffer = CellIn && ~sync_rst;
        always_ff @(posedge clk2p5) begin
            if (InputBufferTrigger) begin
                InputBuffer <= NextInputBuffer;
            end
        end
        assign CellState = InputBuffer;
    //

    // Output Buffer
    // Notes:
    // In:
    // Out:
        // Pulse Limiter
        reg  PulseLimit;
        wire PulseLimitTrigger = clk_en || sync_rst;
        wire NextPulseLimit = PulseOutput && CellSelect && ~sync_rst;
        always_ff @(posedge clk2p5) begin
            if (PulseLimitTrigger) begin
                PulseLimit <= NextPulseLimit;
            end
        end
        wire PulseTrigger = NextPulseLimit && ~PulseLimit;
        // Data Buffer
        reg  OutputBuffer;
        wire OutputBufferTrigger = (LatchDataIn && CellSelect && clk_en) || sync_rst;
        wire NextOutputBuffer = DataIn && ~sync_rst;
        always_ff @(posedge clk2p5) begin
            if (OutputBufferTrigger) begin
                OutputBuffer <= NextOutputBuffer;
            end

            // if (CellSelect) begin
            //     $display("(Cell) - Input              - (%0h)%0b", ADDRTEST, InputBuffer);
            //     $display("(Cell) - Pulse:Output       - (%0h)%0b:%0b", ADDRTEST, PulseLimit, OutputBuffer);
            //     $display("(Cell) - Operation          - (%0h)%0b", ADDRTEST, CellOperation);
            //     $display("(Cell) - Update:Pulse:Latch - (%0h)%0b:%0b:%0b", ADDRTEST, UpdateCell, PulseOutput, LatchDataIn);
            // end
        end
        assign CellOut = OutputBuffer ^ PulseTrigger;
        assign CellOutEnable = PulseTrigger;
    //


endmodule




