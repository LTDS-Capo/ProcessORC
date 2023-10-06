module BufferedFIFO_old #(
    parameter DATABITWIDTH = 16,
    parameter FIFODEPTH = 32,
    parameter FIFOINDEXBITWIDTH = (FIFODEPTH == 1) ? 1 : $clog2(FIFODEPTH)
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                          InputREQ,
    output                         InputACK,
    input       [DATABITWIDTH-1:0] InputData,

    output                         OutputREQ,
    input                          OutputACK,
    input  [FIFOINDEXBITWIDTH-1:0] FIFOTailOffset, // Must be set to 1 if not used
    output      [DATABITWIDTH-1:0] OutputData
);

    // Runahead FIFO
        // Entry following struction
        // [15:0] - Instruction
        // Head Index
            reg  [FIFOINDEXBITWIDTH-1:0] HeadIndex;
            wire [FIFOINDEXBITWIDTH-1:0] NextHeadIndex = sync_rst ? '0 : (HeadIndex + 1);
            wire HeadIndexTrigger = sync_rst || (clk_en && InputREQ && InputACK);
            always_ff @(posedge clk) begin
                if (HeadIndexTrigger) begin
                    HeadIndex <= NextHeadIndex;
                end
            end
        // Tail Index
            reg  [FIFOINDEXBITWIDTH-1:0] TailIndex;
            wire [FIFOINDEXBITWIDTH-1:0] NextTailIndex = sync_rst ? '0 : (TailIndex + FIFOTailOffset);
            wire TailIndexTrigger = sync_rst || (clk_en && OutputREQ && OutputACK);
            always_ff @(posedge clk) begin
                if (TailIndexTrigger) begin
                    TailIndex <= NextTailIndex;
                end
            end
        // Memory
            reg  [DATABITWIDTH-1:0] FIFOMemory [FIFODEPTH-1:0];
            wire        FIFOWriteEn = clk_en && InputREQ && InputACK;
            always_ff @(posedge clk) begin
                if (FIFOWriteEn) begin
                    FIFOMemory[HeadIndex] <= InputData;
                end
            end
        //  

        // FIFO Full/Empty Status
            reg  [1:0] FIFOStatusRegister;
            wire ToBeFullIndexCheck = NextHeadIndex == TailIndex;
            wire ToBeFull = ToBeFullIndexCheck && (InputREQ && InputACK) && ~(OutputREQ && OutputACK);
            wire ToBeEmptyIndexCheck = HeadIndex == NextTailIndex;
            wire ToBeEmpty = ToBeEmptyIndexCheck && (OutputREQ && OutputACK) && ~(InputREQ && InputACK);
            wire [1:0] NextFIFOStatusRegister = sync_rst ? 2'b01 : {ToBeFull, ToBeEmpty};
            wire FIFOStatusRegisterTrigger = sync_rst || (clk_en && InputREQ && InputACK) || (clk_en && OutputREQ && OutputACK);
            always_ff @(posedge clk) begin
                if (FIFOStatusRegisterTrigger) begin
                    FIFOStatusRegister <= NextFIFOStatusRegister;
                end
            end
            wire Full = FIFOStatusRegister[1];
            wire Empty = FIFOStatusRegister[0];
        //

        // Output Assignments
            assign InputACK = ~Full;
            assign OutputREQ = ~Empty;
            assign OutputData = FIFOMemory[TailIndex];
        //

endmodule : BufferedFIFO_old