// 32'b[0000_0][000]_0000_0000_0000_0000_0000_0000
module CommandController #(
    parameter PORTBYTEWIDTH = 4, // Multiple of 2s only for now
    parameter CLOCKCOMMAND_LSB = 27,
    parameter CLOCKCOMMAND_TARGETTOSYSBITWIDTH-1 = 31,
    parameter CLOCKCOMMAND_OPCODE = 5'h1F,
    parameter CLOCKCOMMAND_CLKSELLSB = 24
)(
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input               [7:0]      divided_clks,
    input               [3:0][1:0] divided_clk_sels,

    input                          CommandACK,
    output                         CommandREQ,
    input                          CommandLoadEn,
    input                          CommandStoreEn,
    input       [DATABITWIDTH-1:0] CommandAddressIn, // Use the lower bits to do word select on Loads
    input                    [3:0] CommandDestReg,
    input       [DATABITWIDTH-1:0] CommandDataIn,
    input  [(PORTBYTEWIDTH*8)-1:0] CommandDataIn,

    output                         WritebackACK,
    input                          WritebackREQ,
    output                   [3:0] WritebackDestReg,
    output      [DATABITWIDTH-1:0] WritebackDataOut,

    output                         IOClk,
    output                         IOOutACK,
    input                          IOOutREQ,
    output                         IOCommandEn,
    input                          IOCommandResponse,
    input                          IORegResponseFlag, // Force a Writeback handshake after updating local buffer
    input                    [3:0] IODestRegIn,
    input  [(PORTBYTEWIDTH*8)-1:0] IODataIn,
    output                   [3:0] IODestRegOut,
    output [(PORTBYTEWIDTH*8)-1:0] IODataOut
);
    // Clock Selection
        wire       ClockUpdate = CLOCKCOMMAND_OPCODE == CommandDataIn[CLOCKCOMMAND_TARGETTOSYSBITWIDTH-1:CLOCKCOMMAND_LSB];
        wire [2:0] ClockSelect = CommandDataIn[CLOCKCOMMAND_CLKSELLSB+2:CLOCKCOMMAND_CLKSELLSB];
        wire       target_clk;
        IOClkSelectionBuffer ClockSelection (
            .sys_clk         (sys_clk),
            .clk_en          (clk_en),
            .sync_rst        (sync_rst),
            .src_clk0        (src_clk0),
            .src_clk1        (src_clk1),
            .src_clk2        (src_clk2),
            .divided_clks    (divided_clks),
            .divided_clk_sels(divided_clk_sels),
            .ClockUpdate     (ClockUpdate),
            .ClockSelect     (ClockSelect),
            .target_clk      (target_clk)
        );
    //


    // System Handshakes and Command Generation
        localparam SYSTOTARGETBITWIDTH = (PORTBYTEWIDTH*8) + 4;
        localparam TARGETTOSYSBITWIDTH = (PORTBYTEWIDTH*8) + 5;
        localparam REGOUTLOWERBIT = TARGETTOSYSBITWIDTH - 5;
        // Loads: Forward to Writeback Handshake
        // Stores: Forward to SysToTargetCDC
        assign CommandREQ = CommandLoadEn ? (WritebackREQ && ~LocalResponseACK) : LocalCommandREQ;
        // Writeback Handshake
        // > Sources:
        //   - Loads
        //   - Responses (Takes priority)
        wire   LocalResponseACK;
        wire   LocalResponseREQ = (TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1] && WritebackREQ) || ~TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1];
        assign WritebackACK = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1] ? LocalResponseACK : (CommandACK && CommandLoadEn);
        assign WritebackDestReg = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1] ? TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-2:REGOUTLOWERBIT] : CommandDestReg;
        assign WritebackDataOut = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1] ? TargetToSysCDC_dOut[DATABITWIDTH-1:0] : BufferData; // ToDo: Buffer data
    //

    // Sys_clk data buffer
        // ToDo: Make an output buffer that can be properly addressed
        wire [DATABITWIDTH-1:0][BUFFERCOUNT-1:0] BufferOutput;
        genvar Buffers;
        generate
            for (Buffers = 0; Buffers < BUFFERCOUNT; Buffers = Buffers + 1) begin : BufferGen
                reg  [DATABITWIDTH-1:0] DataBuffer;
                wire                    DataBufferTrigger = ( && clk_en) || sync_rst;
                wire [DATABITWIDTH-1:0] NextDataBuffer = (sync_rst) ? 0 : IODataIn[];
                always_ff @(posedge sys_clk) begin
                    if (DataBufferTrigger) begin
                        DataBuffer <= NextDataBuffer;
                    end
                end
                localparam InverseBuffers = DEPTH - 1 - Buffers;
                assign DataOut[(DATABITWIDTH*(InverseBuffers+1))-1:(DATABITWIDTH*InverseBuffers)] = DataBuffer; 
            end
        endgenerate

        // Byte/Word/Double/Quad Selection - Make into a module to allow full parameterization of everything.. then put into FixedMemory
        // todo: make this non-paramterized
    //

    // Data Input Buffer System

    //

    // Sys to Target FIFO CDC
        wire                           LocalCommandACK;
        wire                           LocalCommandREQ;
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dIn = {CommandDestReg, CommandDataIn};
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dOut;
        assign IODataOut = SysToTargetCDC_dOut[(PORTBYTEWIDTH*8)-1:0];
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(SYSTOTARGETBITWIDTH),
            .DEPTH   (8),
            .TESTENABLE(0)
        ) SysToTargetCDC (
            .rst    (async_rst),
            .w_clk  (sys_clk),
            .dInACK (LocalCommandACK),
            .dInREQ (LocalCommandREQ),
            .dIN    (SysToTargetCDC_dIn),
            .r_clk  (target_clk),
            .dOutACK(),
            .dOutREQ(),
            .dOUT   (SysToTargetCDC_dOut)
        );
    //

    // Target to Sys FIFO CDC
        wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dIn = {~RegResponseEn, DestReg, IODataIn};
        wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dOut;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(TARGETTOSYSBITWIDTH),
            .DEPTH   (8),
            .TESTENABLE(0)
        ) TargetToSysCDC (
            .rst    (async_rst),
            .w_clk  (target_clk),
            .dInACK (),
            .dInREQ (),
            .dIN    (TargetToSysCDC_dIn),
            .r_clk  (sys_clk),
            .dOutACK(LocalResponseACK),
            .dOutREQ(LocalResponseREQ),
            .dOUT   (TargetToSysCDC_dOut)
        );
    //

    // IO Domain Control
        // Target to Sys Handshake

        // Sys to Target Handshake

        // IO Hanshake

    //

endmodule