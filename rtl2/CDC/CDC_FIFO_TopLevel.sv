module CDC_FIFO_TopLevel #(
    parameter DATA_BITWIDTH = 8,
    parameter DEPTH = 16,
    parameter OUTPUT_MUX_ENABLE = 0 // 0 - Output is always read, 1 - Output is only read when OutputREQ is high
)(
    input async_rst,

    input                      InputClk,
    input                      InputREQ,
    output                     InputACK,
    input  [DATA_BITWIDTH-1:0] InputData,

    input                      OutputClk,
    output                     OutputREQ,
    input                      OutputACK,
    output [DATA_BITWIDTH-1:0] OutputData
);

    localparam DEPTH_BITWIDTH = (DEPTH == 1) ? 1 : $clog2(DEPTH);

    always_ff @(posedge InputClk) begin
        $display("> Head:Grey:Tail:Grey - %0d:%06b:%0d:%06b", Head, HeadGreyCount_Desyncronized, Tail, TailGreyCount_Desyncronized);
    end

    //? Head Tracking
        //                                                                   //
        //* Head Counter
            wire   [DEPTH_BITWIDTH:0] TailGreyCount_Syncronized;
            wire [DEPTH_BITWIDTH-1:0] Head;
            wire   [DEPTH_BITWIDTH:0] HeadGreyCount_Desyncronized;
            CDC_FIFO_Counter #(
                .DEPTH  (DEPTH),
                .FULL_EN(1)
            ) Head_Counter (
                .clk                (InputClk),
                .async_rst          (async_rst),
                .CountREQ           (InputREQ),
                .CountACK           (InputACK),
                .OpposingGreyCounter(TailGreyCount_Syncronized),
                .CountBinary        (Head),
                .CountGrey          (HeadGreyCount_Desyncronized)
            );
        //                                                                   //
        //* Head Syncronization
            wire   [DEPTH_BITWIDTH:0] HeadGreyCount_Syncronized;
            CDC_FIFO_Sequencer #(
                .DATA_BITWIDTH(DEPTH_BITWIDTH+1),
                .INPUT_DEPTH  (1),
                .OUTPUT_DEPTH (3)
            ) Head_Syncronizer (
                .async_rst (async_rst),
                .InputClk  (InputClk),
                .InputData (HeadGreyCount_Desyncronized),
                .OutputClk (OutputClk),
                .OutputData(HeadGreyCount_Syncronized)
            );
        //                                                                   //
    //?

    //? Tail Tracking
        //                                                                   //
        //* Tail Counter
            wire [DEPTH_BITWIDTH-1:0] Tail;
            wire   [DEPTH_BITWIDTH:0] TailGreyCount_Desyncronized;
            CDC_FIFO_Counter #(
                .DEPTH  (DEPTH),
                .FULL_EN(0)
            ) Tail_Counter (
                .clk                (OutputClk),
                .async_rst          (async_rst),
                .CountREQ           (OutputACK), // Flipped Handshakes for Output
                .CountACK           (OutputREQ), // Flipped Handshakes for Output
                .OpposingGreyCounter(HeadGreyCount_Syncronized),
                .CountBinary        (Tail),
                .CountGrey          (TailGreyCount_Desyncronized)
            );
        //                                                                   //
        //* Tail Syncronization
            CDC_FIFO_Sequencer #(
                .DATA_BITWIDTH(DEPTH_BITWIDTH+1),
                .INPUT_DEPTH  (1),
                .OUTPUT_DEPTH (3)
            ) Tail_Syncronizer (
                .async_rst (async_rst),
                .InputClk  (OutputClk),
                .InputData (TailGreyCount_Desyncronized),
                .OutputClk (InputClk),
                .OutputData(TailGreyCount_Syncronized)
            );
        //                                                                   //
    //?

    //? Memory Instaitation
        //                                                                   //
        reg  [DATA_BITWIDTH-1:0] DataBuffer [DEPTH-1:0];
        wire DataBufferTrigger = InputREQ && InputACK;
        always_ff @(posedge InputClk) begin
            if (DataBufferTrigger) begin
                DataBuffer[Head] <= InputData;
            end
        end
    //?

    //? Output Assignments
        //                                                                   //
        //* Output
        generate
            if (OUTPUT_MUX_ENABLE == 0) begin
                assign OutputData = DataBuffer[Tail];
            end
            else begin
                assign OutputData = OutputREQ ? DataBuffer[Tail] : {DATA_BITWIDTH{1'b0}};
            end
        endgenerate
        //                                                                   //
    //?

endmodule : CDC_FIFO_TopLevel