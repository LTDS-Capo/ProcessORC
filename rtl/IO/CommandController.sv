// 32'b[0000_0][000]_0000_0000_0000_0000_0000_0000
module CommandController #(
    parameter PORTBYTEWIDTH = 4, // Multiple of 2s only for now
    parameter PORTINDEXBITWIDTH = (PORTBYTEWIDTH == 1) ? 1 : $clog2(PORTBYTEWIDTH),
    parameter CLOCKCOMMAND_LSB = 27,
    parameter CLOCKCOMMAND_TARGETTOSYSBITWIDTH-1 = 31,
    parameter CLOCKCOMMAND_OPCODE = 5'h1F,
    parameter CLOCKCOMMAND_CLKSELLSB = 24,
    parameter DATABITWIDTH = 16,
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH)
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
    input                    [3:0] MinorOpcodeIn,
    input       [DATABITWIDTH-1:0] CommandAddressIn_Offest,
    input       [DATABITWIDTH-1:0] CommandDataIn,
    input                    [3:0] CommandDestReg,

    output                         WritebackACK,
    input                          WritebackREQ,
    output                   [3:0] WritebackDestReg,
    output      [DATABITWIDTH-1:0] WritebackDataOut,

    output                         IOClk,
    input                          IOACK,
    output                         IOREQ,
    output                         IOCommandEn,
    input                          IOCommandResponse,
    input                          IORegResponseFlag, // Force a Writeback handshake after updating local buffer
    input                          IOMemResponseFlag, // Only update local buffer
    input                    [3:0] IODestRegIn,
    input  [(PORTBYTEWIDTH*8)-1:0] IODataIn,
    output                   [3:0] IODestRegOut,
    output [(PORTBYTEWIDTH*8)-1:0] IODataOut
);

    localparam BUFFERINDEXBITWIDTH = (BUFFERCOUNT == 1) ? 1 : $clog2(BUFFERCOUNT);
    wire CommandLoadEn = ~MinorOpcodeIn[2];
    wire CommandStoreEn = MinorOpcodeIn[2];

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
        assign CommandREQ = CommandLoadEn ? (WritebackREQ && ~LocalResponseACK) : SysCommandREQ;
        // Writeback Handshake
        // > Sources:
        //   - Loads
        //   - Responses (Takes priority)
        local REGRESPONSEBITWIDTH = (DATABITWIDTH >= (PORTBYTEWIDTH*8)) ? (PORTBYTEWIDTH*8) : DATABITWIDTH;
        wire                             LocalResponseACK;
        wire                             LocalResponseREQ = (LocalIORegResponse && WritebackREQ) || ~LocalIORegResponse;
        assign                           WritebackACK = LocalIORegResponse ? LocalResponseACK : (CommandACK && CommandLoadEn);
        assign                           WritebackDestReg = LocalIORegResponse ? TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-2:REGOUTLOWERBIT] : CommandDestReg;
        wire   [BUFFERINDEXBITWIDTH-1:0] LoadIndex = CommandAddressIn_Offest[BUFFERINDEXBITWIDTH-1:0];
        assign                           WritebackDataOut = LocalIORegResponse ? {'0, TargetToSysCDC_dOut[REGRESPONSEBITWIDTH-1:0]} : LoadVector[LoadIndex];
    //

    // Data Store Buffer System
        wire   SysCommandACK = CommandACK && CommandStoreEn;
        wire   SysCommandREQ;
        wire LocalCommandACK;
        wire LocalCommandREQ;
        // // ElementEn Gen
        //     localparam DATAINDEXBITWIDTH = ((DATABITWIDTH/8) == 1) ? 1 : $clog2((DATABITWIDTH/8));
        //     localparam ELEMENTADDRUPPER = DATAINDEXBITWIDTH + BUFFERINDEXBITWIDTH;
        //     logic [BUFFERCOUNT-1:0] ElementDecoder;
        //     always_comb begin
        //         ElementDecoder = 0;
        //         ElementDecoder[CommandAddressIn_Offest[ELEMENTADDRUPPER-1:DATAINDEXBITWIDTH]] = 1'b1;
        //     end
        //     wire [BUFFERCOUNT-1:0] SysWordEn = ElementDecoder;
        // // 
        wire [(PORTBYTEWIDTH*8)-1:0] LocalCommandData;
        IOCommandInterface #(
            .DATABITWIDTH (DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH),
            .BUFFERCOUNT  (BUFFERCOUNT)
        ) StoreBuffer (
            .clk          (sys_clk),
            .clk_en       (clk_en),
            .sync_rst     (sync_rst),
            .CommandInACK (SysCommandACK),
            .CommandInREQ (SysCommandREQ),
            .MinorOpcodeIn(MinorOpcodeIn),
            .DataAddrIn   (CommandAddressIn_Offest),
            .DataIn       (CommandDataIn),
            .CommandOutACK(LocalCommandACK),
            .CommandOutREQ(LocalCommandREQ),
            .DataOut      (LocalCommandData)
        );
    //

    // Sys to Target FIFO CDC
        wire                           TargetCommandACK;
        wire                           TargetCommandREQ;
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dIn = {CommandDestReg, LocalCommandData};
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dOut;
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
            .dOutACK(TargetCommandACK),
            .dOutREQ(TargetCommandREQ),
            .dOUT   (SysToTargetCDC_dOut)
        );
    //

    // Data Load Buffer System
        reg  [(PORTBYTEWIDTH*8)-1:0] LoadBuffer;
        wire                         LoadBufferTrigger = (TargetResponseACK && TargetResponseREQ && clk_en) || sync_rst;
        wire [(PORTBYTEWIDTH*8)-1:0] NextLoadBuffer = (sync_rst) ? 0 : TargetToSysCDC_dOut[(PORTBYTEWIDTH*8)-1:0];
        always_ff @(posedge sys_clk) begin
            if (LoadBufferTrigger) begin
                LoadBuffer <= NextLoadBuffer;
            end
        end
        genvar BufferIndex;
        wire [BUFFERCOUNT-1:0][DATABITWIDTH-1:0] LoadVector;
        generate
            for (BufferIndex == 0; BufferIndex < BUFFERCOUNT; BufferIndex = BufferIndex + 1) begin : LoadIndexGen
                if (BufferIndex == (BUFFERCOUNT - 1)) begin
                    localparam LOADLOWERBITWIDTH = BufferIndex * DATABITWIDTH;
                    localparam LOADUPPERBITWIDTH = PORTBYTEWIDTH * 8;
                    assign LoadVector[BufferIndex] = {'0, LoadBuffer[LOADUPPERBITWIDTH-1:LOADLOWERBITWIDTH]};
                end
                else begin
                    localparam LOADLOWERBITWIDTH = BufferIndex * DATABITWIDTH;
                    localparam LOADUPPERBITWIDTH = (BufferIndex + 1) * DATABITWIDTH;
                    assign LoadVector[BufferIndex] = LoadBuffer[LOADUPPERBITWIDTH-1:LOADLOWERBITWIDTH];
                end
            end
        endgenerate
    //

    // Target to Sys FIFO CDC
        wire                           TargetResponseACK;
        wire                           TargetResponseREQ;
        wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dIn = {IORegResponseFlag, IODestRegIn, IODataIn};
        wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dOut;
        wire LocalIORegResponse = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1];
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(TARGETTOSYSBITWIDTH),
            .DEPTH   (8),
            .TESTENABLE(0)
        ) TargetToSysCDC (
            .rst    (async_rst),
            .w_clk  (target_clk),
            .dInACK (TargetResponseACK),
            .dInREQ (TargetResponseREQ),
            .dIN    (TargetToSysCDC_dIn),
            .r_clk  (sys_clk),
            .dOutACK(LocalResponseACK),
            .dOutREQ(LocalResponseREQ),
            .dOUT   (TargetToSysCDC_dOut)
        );
    //

    // IO Domain Control
        // Target to Sys Handshake
        assign TargetResponseACK = (IOMemResponseFlag || IORegResponseFlag) && IOACK;
        // Sys to Target Handshake
        assign TargetCommandREQ = IOCommandResponse && IOCommandEn && IOACK;
        // IO Hanshake
        assign IOREQ = TargetResponseREQ || TargetCommandACK; // Handshake direction is flipped here due to full-duplex communication
        assign IOCommandEn = TargetCommandACK;
        assign IODestRegOut = SysToTargetCDC_dOut[SYSTOTARGETBITWIDTH-1:(PORTBYTEWIDTH*8)];
        assign IODataOut = SysToTargetCDC_dOut[(PORTBYTEWIDTH*8)-1:0];
    //

endmodule