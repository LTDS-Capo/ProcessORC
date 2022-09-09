module GPIO_Cell (
    input clk,
    input clk_en,
    input sync_rst,

    input        Set,
    input        Clear,
    input        PulseInit,
    input  [9:0] LocalDataIn,
    output       LocalDataOut,
    output       PinDataOut,

    input        IODataIn,
    output       IODataOut,
    output       IODataOutEn
);
    
    // Input Register
        reg  InputBuffer;
        wire InputBufferTrigger = clk_en || sync_rst;
        wire NextInputBuffer = IODataIn && ~sync_rst;
        always_ff @(posedge clk) begin
            if (InputBufferTrigger) begin
                InputBuffer <= NextInputBuffer;
            end
        end
        assign PinDataOut = InputBuffer;
    //

    // Pulse Counter
        reg    [10:0] PulseCounter;
        wire          PulseCounterTrigger = (PulseCounter[10] && clk_en) || (PulseInit && clk_en) || sync_rst;
        logic  [10:0] NextPulseCounter;
        wire    [1:0] NextPulseCondition;
        assign        NextPulseCondition[0] = (PulseInit) && ~sync_rst;
        assign        NextPulseCondition[1] = (PulseCounter[10]) && ~sync_rst;
        wire    [9:0] NextPulseCountSub = PulseCounter[9:0] - 1;
        wire          PulseMSB = PulseCounter[10] && ~(PulseCounter[9:0] == 1);
        always_comb begin : PulseCounterMux
            case (NextPulseCondition)
                2'b01  : NextPulseCounter = {1'b1, LocalDataIn};
                2'b10  : NextPulseCounter = {PulseMSB, NextPulseCountSub};
                2'b11  : NextPulseCounter = {1'b1, LocalDataIn};
                default: NextPulseCounter = '0; // Default is also case 0
            endcase
        end
        always_ff @(posedge clk) begin
            if (PulseCounterTrigger) begin
                PulseCounter <= NextPulseCounter;
            end
        end
    //

    // Output Register
        // Data
        reg  DataBuffer;
        wire DataBufferTrigger = (Clear && clk_en) || (Set && clk_en) || sync_rst;
        wire NextDataBuffer = LocalDataIn[0] && ~sync_rst && ~Clear;
        always_ff @(posedge clk) begin
            if (DataBufferTrigger) begin
                DataBuffer <= NextDataBuffer;
            end
        end
        // Out Enable
        reg  DataEnBuffer;
        wire NextDataEnBuffer = Set && ~sync_rst && ~Clear;
        always_ff @(posedge clk) begin
            if (DataBufferTrigger) begin
                DataEnBuffer <= NextDataEnBuffer;
            end
        end
    //

    // Output Assignments
        reg  [1:0] OutputBuffer;
        wire       OutputBufferTrigger = clk_en || sync_rst;
        wire [1:0] NextOutputBuffer = (sync_rst) ? 0 : {LocalDataOut, (DataEnBuffer || PulseCounter[10])};
        always_ff @(posedge clk) begin
            if (OutputBufferTrigger) begin
                OutputBuffer <= NextOutputBuffer;
            end
        end
        assign LocalDataOut = (DataBuffer ^ PulseCounter[10]);
        assign IODataOut = OutputBuffer[0];
        assign IODataOutEn = OutputBuffer[1];
    //

endmodule