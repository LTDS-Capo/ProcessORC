module CDC_FIFO_Sequencer #(
    parameter DATA_BITWIDTH = 5,
    parameter INPUT_DEPTH = 1,
    parameter OUTPUT_DEPTH = 3
)(
    input async_rst,
    
    input                      InputClk,
    input  [DATA_BITWIDTH-1:0] InputData,

    input                      OutputClk,
    output [DATA_BITWIDTH-1:0] OutputData
);



    reg  [DATA_BITWIDTH-1:0] InputBufferVector [INPUT_DEPTH-1:0];
    genvar INPUT_BUFFER_INDEX;
    generate
        for (INPUT_BUFFER_INDEX = 0; INPUT_BUFFER_INDEX < INPUT_DEPTH; INPUT_BUFFER_INDEX = INPUT_BUFFER_INDEX + 1) begin : InputBufferGeneration
            //                                                                   //
            //* Zero Index Exception - Takes data from Input
            if (INPUT_BUFFER_INDEX == 0) begin
                //                                                                   //
                always_ff @(posedge InputClk or posedge async_rst) begin
                    if (async_rst) begin
                        InputBufferVector[INPUT_BUFFER_INDEX] <= 0;
                    end
                    else begin
                        InputBufferVector[INPUT_BUFFER_INDEX] <= InputData;
                    end
                end
                //                                                                   //
            end
            else begin
                //                                                                   //
                always_ff @(posedge InputClk or posedge async_rst) begin
                    if (async_rst) begin
                        InputBufferVector[INPUT_BUFFER_INDEX] <= 0;
                    end
                    else begin
                        InputBufferVector[INPUT_BUFFER_INDEX] <= InputBufferVector[INPUT_BUFFER_INDEX-1];
                    end
                end
                //                                                                   //
            end
        end
    endgenerate


    reg  [DATA_BITWIDTH-1:0] OutputBufferVector [OUTPUT_DEPTH-1:0];
    genvar OUTPUT_BUFFER_INDEX;
    generate
        for (OUTPUT_BUFFER_INDEX = 0; OUTPUT_BUFFER_INDEX < OUTPUT_DEPTH; OUTPUT_BUFFER_INDEX = OUTPUT_BUFFER_INDEX + 1) begin : OutputBufferGeneration
            //                                                                   //
            //* Zero Index Exception - Takes data from InputBufferVector
            if (OUTPUT_BUFFER_INDEX == 0) begin
                //                                                                   //
                always_ff @(posedge OutputClk or posedge async_rst) begin
                    if (async_rst) begin
                        OutputBufferVector[OUTPUT_BUFFER_INDEX] <= 0;
                    end
                    else begin
                        OutputBufferVector[OUTPUT_BUFFER_INDEX] <= InputBufferVector[INPUT_DEPTH-1];
                        // OutputBufferVector[OUTPUT_BUFFER_INDEX] <= InputData;
                    end
                end
                //                                                                   //
            end
            else begin
                //                                                                   //
                always_ff @(posedge OutputClk or posedge async_rst) begin
                    if (async_rst) begin
                        OutputBufferVector[OUTPUT_BUFFER_INDEX] <= 0;
                    end
                    else begin
                        OutputBufferVector[OUTPUT_BUFFER_INDEX] <= OutputBufferVector[OUTPUT_BUFFER_INDEX-1];
                    end
                end
                //                                                                   //
            end
        end
    endgenerate

    assign OutputData = OutputBufferVector[OUTPUT_DEPTH-1];


endmodule : CDC_FIFO_Sequencer