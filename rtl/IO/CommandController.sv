// 32'b[0000_0][000]_0000_0000_0000_0000_0000_0000
module CommandController #(
    parameter PORTBYTEWIDTH = 4,
    parameter PORTINDEXBITWIDTH = (PORTBYTEWIDTH == 1) ? 1 : $clog2(PORTBYTEWIDTH),
    parameter CLOCKCOMMAND_LSB = 27,
    parameter CLOCKCOMMAND_MSB = 31,
    parameter CLOCKCOMMAND_OPCODE = 5'h1F,
    parameter CLOCKCOMMAND_CLKSELLSB = 24,
    parameter DATABITWIDTH = 16,
    parameter ODDPORTWIDTHCHECK = (((PORTBYTEWIDTH * 8) % DATABITWIDTH) != 0) ? 1 : 0,
    parameter BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : (((PORTBYTEWIDTH * 8) / DATABITWIDTH) + ODDPORTWIDTHCHECK)
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
    output                         IOResponseRequested,
    input                          IOCommandResponse,
    input                          IORegResponseFlag, // Force a Writeback handshake after updating local buffer
    input                          IOMemResponseFlag, // Only update local buffer
    input                    [3:0] IODestRegIn,
    input  [(PORTBYTEWIDTH*8)-1:0] IODataIn,
    output                   [3:0] IODestRegOut,
    output [(PORTBYTEWIDTH*8)-1:0] IODataOut
);

    localparam BUFFERINDEXBITWIDTH = (BUFFERCOUNT == 1) ? 1 : $clog2(BUFFERCOUNT);
    wire CommandStaleLoadEn = ~MinorOpcodeIn[2] && ~MinorOpcodeIn[3];
    wire CommandLoadEn = ~MinorOpcodeIn[2] && MinorOpcodeIn[3];
    wire CommandStoreEn = MinorOpcodeIn[2];

    // Clock Selection
        wire       ClockUpdate_Tmp = CLOCKCOMMAND_OPCODE == LocalCommandData[CLOCKCOMMAND_MSB-1:CLOCKCOMMAND_LSB];
        wire       ClockUpdate = ClockUpdate_Tmp && LocalCommandACK;
        wire [2:0] ClockSelect = LocalCommandData[CLOCKCOMMAND_CLKSELLSB+2:CLOCKCOMMAND_CLKSELLSB];
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
        assign IOClk = target_clk;
    //

    // System Handshakes and Command Generation
        localparam SYSTOTARGETBITWIDTH = (PORTBYTEWIDTH*8) + 5;
        localparam TARGETTOSYSBITWIDTH = (PORTBYTEWIDTH*8) + 5;
        localparam REGOUTLOWERBIT = TARGETTOSYSBITWIDTH - 5;
        // Loads: Forward to Writeback Handshake
        // Stores: Forward to SysToTargetCDC
        logic CommandREQ_Tmp;
        wire  [1:0] CommandREQCondition = {CommandStaleLoadEn, CommandLoadEn};
        always_comb begin : CommandREQConditionMux
            case (CommandREQCondition)
                2'b01  : CommandREQ_Tmp = LocalCommandREQ_Tmp;
                2'b10  : CommandREQ_Tmp = WritebackREQ && ~LocalResponseACK;
                2'b11  : CommandREQ_Tmp = '0;
                default: CommandREQ_Tmp = SysCommandREQ; // Default is also case 0
            endcase
        end
        assign CommandREQ = CommandREQ_Tmp;
        // Writeback Handshake
        // > Sources:
        //   - Loads
        //   - Responses (Takes priority)
        localparam REGRESPONSEBITWIDTH = (DATABITWIDTH >= (PORTBYTEWIDTH*8)) ? (PORTBYTEWIDTH*8) : DATABITWIDTH;
        wire                             LocalResponseACK;
        wire                             LocalResponseREQ = (LocalIORegResponse && WritebackREQ) || ~LocalIORegResponse;
        assign                           WritebackACK = LocalIORegResponse ? LocalResponseACK : (CommandACK && CommandStaleLoadEn);
        assign                           WritebackDestReg = LocalIORegResponse ? TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-2:REGOUTLOWERBIT] : CommandDestReg;
        wire [DATABITWIDTH-1:0] LoadData_Tmp;
        IOLoadDataAlignment #(
            .DATABITWIDTH(DATABITWIDTH)
        ) LoadDataAlignment (
            .MinorOpcodeIn(MinorOpcodeIn),
            .DataAddrIn   (CommandAddressIn_Offest),
            .DataIn       (LoadVector[LoadIndex]),
            .DataOut      (LoadData_Tmp)
        );
        wire   [BUFFERINDEXBITWIDTH-1:0] LoadIndex = CommandAddressIn_Offest[BUFFERINDEXBITWIDTH-1:0];
        assign                           WritebackDataOut = LocalIORegResponse ? {'0, TargetToSysCDC_dOut[REGRESPONSEBITWIDTH-1:0]} : LoadData_Tmp;
    //

    // Data Store Buffer System
        wire SysCommandACK = CommandACK && CommandStoreEn;
        wire SysCommandREQ;
        wire LocalCommandACK_Tmp;
        wire LocalCommandREQ_Tmp;
        wire LocalCommandREQ = (LocalCommandREQ_Tmp && ~CommandLoadEn) || ClockUpdate_Tmp; 
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
            .CommandOutACK(LocalCommandACK_Tmp),
            .CommandOutREQ(LocalCommandREQ),
            .DataOut      (LocalCommandData)
        );
    //

    // Sys to Target FIFO CDC
        wire                           LocalCommandACK = CommandLoadEn ? CommandACK : (LocalCommandACK_Tmp && ~ClockUpdate_Tmp);
        wire                           TargetCommandACK;
        wire                           TargetCommandREQ;
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dIn = {CommandLoadEn, CommandDestReg, LocalCommandData};
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dOut;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH  (SYSTOTARGETBITWIDTH),
            .DEPTH     (8),
            .TESTENABLE(0)
        ) SysToTargetCDC (
            .rst    (async_rst),
            .w_clk  (sys_clk),
            .dInACK (LocalCommandACK),
            .dInREQ (LocalCommandREQ_Tmp),
            .dIN    (SysToTargetCDC_dIn),
            .r_clk  (target_clk),
            .dOutACK(TargetCommandACK),
            .dOutREQ(TargetCommandREQ),
            .dOUT   (SysToTargetCDC_dOut)
        );
    //

    // Data Load Buffer System - // ToDo: Make this update on a store command - nahhhh,,, only if someone bitches
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
            for (BufferIndex = 0; BufferIndex < BUFFERCOUNT; BufferIndex = BufferIndex + 1) begin : LoadIndexGen
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
        assign IOResponseRequested = SysToTargetCDC_dOut[SYSTOTARGETBITWIDTH-1];
        assign IODestRegOut = SysToTargetCDC_dOut[SYSTOTARGETBITWIDTH-2:(PORTBYTEWIDTH*8)];
        assign IODataOut = SysToTargetCDC_dOut[(PORTBYTEWIDTH*8)-1:0];
    //

endmodule