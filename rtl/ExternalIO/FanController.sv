module FanController #(
    parameter [6:0] DEFAULTDUTYCYCLE = 40
)(
    input clk2p5,
    input clk_en,
    input sync_rst,



    input        DutyCycleWriteREQ,
    output       DutyCycleWriteACK,
    input  [6:0] DutyCycleIn,

    output       FanControlOut
);

    // IO Handshake Response
    reg  ACKDelay;
    wire ACKDelayTrigger = clk_en || sync_rst;
    wire NextACKDelay = DutyCycleWriteREQ && ~sync_rst;
    always_ff @(posedge clk2p5) begin
        if (ACKDelayTrigger) begin
            ACKDelay <= NextACKDelay;
        end
    end
    assign DutyCycleWriteACK = ACKDelay;

    // DutyCycle Buffer with MSB representing a valid value.
    // Only use this value after MSB has been set.
    wire       DutyCycleOverflow = DutyCycleIn > 100;
    wire [6:0] LimitedDutyCycle = DutyCycleOverflow ? 100 : DutyCycleIn;
    reg  [7:0] DutyCycleBuffer;
    wire       DutyCycleBufferTrigger = (DutyCycleWriteREQ && clk_en) || sync_rst;
    wire [7:0] NextDutyCycleBuffer = (sync_rst) ? 0 : {1'b1, LimitedDutyCycle};
    always_ff @(posedge clk2p5) begin
        if (DutyCycleBufferTrigger) begin
            DutyCycleBuffer <= NextDutyCycleBuffer;
        end

        //$display("(Val)DutyCycleBuffer - (%0b)%0d", DutyCycleBuffer[7], DutyCycleBuffer[6:0]);
        //$display("CycleCounter         - %0d", CycleCounter);

    end

    // 6bit counter with a limit of 100 gives a PWM frequency of 25khz.
    reg  [6:0] CycleCounter;
    wire       CycleCounterTrigger = clk_en || sync_rst;
    wire       CycleLimitReached = CycleCounter == 99;
    wire [6:0] NextCycleCounter = (sync_rst || CycleLimitReached) ? 0 : (CycleCounter + 1);
    always_ff @(posedge clk2p5) begin
        if (CycleCounterTrigger) begin
            CycleCounter <= NextCycleCounter;
        end
    end

    wire [6:0] CycleLimit = DutyCycleBuffer[7] ? DutyCycleBuffer : DEFAULTDUTYCYCLE;
    assign FanControlOut = CycleCounter < CycleLimit;

endmodule