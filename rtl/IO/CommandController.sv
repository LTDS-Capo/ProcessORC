// 32'b[0000_0][000]_0000_0000_0000_0000_0000_0000
module CommandController #(
    parameter PORTBYTEWIDTH = 4,
    parameter CLOCKCOMMAND_ENABLE = 1,
    parameter CLOCKCOMMAND_LSB = 27,
    parameter CLOCKCOMMAND_MSB = 31,
    parameter CLOCKCOMMAND_OPCODE = 5'h1F,
    parameter CLOCKCOMMAND_CLKSELLSB = 24,
    parameter DATABITWIDTH = 16
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

    output        IOClk,
    output        IOOut_ACK,
    input         IOOut_REQ,
    output        IOOut_ResponseRequested,
    output  [3:0] IOOut_DestReg,
    output [15:0] IOOut_Data,

    input         IOIn_ACK,
    output        IOIn_REQ,
    input         IOIn_RegResponseFlag,
    input         IOIn_MemResponseFlag,
    input   [3:0] IOIn_DestReg,
    input  [15:0] IOIn_Data

    //output [(PORTBYTEWIDTH*8)-1:0] LoadBuffer_TEST
    //output [3:0] TEST_VECTOR,
    //output [1:0] TEST_VECTOR2

);

    //assign LoadBuffer_TEST = LoadBuffer;

    // assign TEST_VECTOR = {ClockUpdate, ClockSelect};
    // assign TEST_VECTOR2 = {ClockUpdate_Tmp, LocalCommandACK};

    always_ff @(posedge sys_clk) begin
		// $display(">>> CMDCTRLR - SL:L:S  - %0b:%0b:%0b", CommandLoadEn, CommandAtomicLoadEn, CommandStoreEn);
		// // $display>>("> CMDCTRLR - REQCond - %0b", CommandREQCondition);
		// $display(">>> CMDCTRLR - C(S>S) - ACK:REQ - %0b:%0b", SysCommandACK, SysCommandREQ);
		// $display(">>> CMDCTRLR - S(S>T) - ACK:REQ - %0b:%0b", LocalCommandACK, LocalCommandREQ_Tmp);
		// $display(">>> CMDCTRLR - T(S>T) - ACK:REQ - %0b:%0b", TargetCommandACK, TargetCommandREQ);
		// $display(">>> CMDCTRLR - T(T>S) - ACK:REQ - %0b:%0b", TargetResponseACK, TargetResponseREQ);
		// $display(">>> CMDCTRLR - S(T>S) - ACK:REQ - %0b:%0b:%0b", LocalResponseACK, LocalResponseREQ, LocalIORegResponse);
    end

    localparam PORTINDEXBITWIDTH = (PORTBYTEWIDTH == 1) ? 1 : $clog2(PORTBYTEWIDTH);
    localparam ODDPORTWIDTHCHECK = (((PORTBYTEWIDTH * 8) % DATABITWIDTH) != 0) ? 1 : 0;
    localparam BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : (((PORTBYTEWIDTH * 8) / DATABITWIDTH) + ODDPORTWIDTHCHECK);
    
    // Command Decoding
        wire CommandLoadEn = ~MinorOpcodeIn[2] && ~MinorOpcodeIn[3]; // Validated
        wire CommandAtomicLoadEn = ~MinorOpcodeIn[2] && MinorOpcodeIn[3]; // Validated
        wire CommandStatusLoadEn = MinorOpcodeIn[2] && MinorOpcodeIn[3]; // Validated
        wire CommandStoreEn = MinorOpcodeIn[2] && ~MinorOpcodeIn[3]; // Validated

        wire LocalCommandAtomicLoadEn = ~MinorOpcodeLocal[2] && MinorOpcodeLocal[3];
        // wire LocalCommandStatusLoadEn = MinorOpcodeLocal[2] && MinorOpcodeLocal[3];
    //

    // Clock Selection
        wire       ClockUpdate_Tmp = CLOCKCOMMAND_OPCODE == LocalCommandData[CLOCKCOMMAND_MSB:CLOCKCOMMAND_LSB];
        // wire       ClockUpdate = ClockUpdate_Tmp && LocalCommandACK;
        wire       ClockUpdate = ClockUpdate_Tmp && LocalCommandACK_Tmp;
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
        assign IOClk = CLOCKCOMMAND_ENABLE[0] ? target_clk : sys_clk;
    //

    // System Handshakes and Command Generation
        localparam SYSTOTARGETBITWIDTH = (PORTBYTEWIDTH*8) + 5;
        localparam TARGETTOSYSBITWIDTH = (PORTBYTEWIDTH*8) + 5;
        localparam REGOUTLOWERBIT = TARGETTOSYSBITWIDTH - 5;
        // Loads: Forward to Writeback Handshake
        // Stores: Forward to SysToTargetCDC


        // assign CommandREQ = CommandLoadEn ? (WritebackREQ && ~LocalResponseACK) : SysCommandREQ;
        assign CommandREQ = (CommandLoadEn || CommandStatusLoadEn) ? (WritebackREQ && ~LocalResponseACK) : SysCommandREQ;

        // Writeback Handshake
        // > Sources:
        //   - Loads
        //   - Responses (Takes priority)
        localparam REGRESPONSEBITWIDTH = (DATABITWIDTH >= (PORTBYTEWIDTH*8)) ? (PORTBYTEWIDTH*8) : DATABITWIDTH;
        // wire                    RegResponse_Tmp = LocalIORegResponse && TargetCommandACK; 
        wire                    RegResponse_Tmp = LocalIORegResponse && LocalResponseACK; 
        wire                    LocalResponseACK;
        // wire                    LocalResponseREQ = (RegResponse_Tmp && WritebackREQ) || ~RegResponse_Tmp;
        wire                    LocalResponseREQ = (LocalIORegResponse && WritebackREQ) || ~LocalIORegResponse;
        // assign                  WritebackACK = RegResponse_Tmp ? LocalResponseACK : ((CommandACK && CommandLoadEn) || (LocalCommandACK_Tmp && LocalCommandStatusLoadEn));
        // assign                  WritebackACK = RegResponse_Tmp ? LocalResponseACK : ((CommandACK && CommandLoadEn) || (CommandACK && CommandStatusLoadEn));
        assign                  WritebackACK = LocalIORegResponse ? LocalResponseACK : ((CommandACK && CommandLoadEn) || (CommandACK && CommandStatusLoadEn));
        
        
        // logic [3:0] WritebackDestReg_Tmp;
        // wire  [1:0] WriteBackRegCondition = {RegResponse_Tmp, StatusLoadEn_Tmp};
        // always_comb begin : NextSOMETHINGMux
        //     case (WriteBackRegCondition)
        //         2'b01  : WritebackDestReg_Tmp = DestRegLocal;
        //         2'b10  : WritebackDestReg_Tmp = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-2:REGOUTLOWERBIT];
        //         2'b11  : WritebackDestReg_Tmp = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-2:REGOUTLOWERBIT];
        //         default: WritebackDestReg_Tmp = CommandDestReg; // Default is also case 0
        //     endcase
        // end
        // assign WritebackDestReg = WritebackDestReg_Tmp;
        assign WritebackDestReg = RegResponse_Tmp ? TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-2:REGOUTLOWERBIT] : CommandDestReg;
        
        
        wire   [DATABITWIDTH-1:0] LoadData_Tmp;
        // wire                    StatusLoadEn_Tmp = LocalCommandStatusLoadEn && LocalCommandACK_Tmp;
        wire                    StatusLoadEn_Tmp = CommandStatusLoadEn && CommandACK;
        wire              [3:0] LoadMinorOpcode = MinorOpcodeIn;
        wire [DATABITWIDTH-1:0] LoadAddrIn = CommandAddressIn_Offest;
        wire [DATABITWIDTH-1:0] LoadDataIn = StatusLoadEn_Tmp ? LocalCommandData : LoadBuffer;
        IOLoadDataAlignment #(
            .DATABITWIDTH(DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH)
        ) LoadDataAlignment (
            .MinorOpcodeIn(LoadMinorOpcode),
            .DataAddrIn   (LoadAddrIn),
            .DataIn       (LoadDataIn),
            .DataOut      (LoadData_Tmp)
        );
        assign WritebackDataOut = RegResponse_Tmp ? {'0, TargetToSysCDC_dOut[REGRESPONSEBITWIDTH-1:0]} : LoadData_Tmp;
    //

    // Data Store Buffer System
        // wire SysCommandACK = (CommandACK && CommandStoreEn) || (CommandACK && CommandAtomicLoadEn) || (CommandACK && CommandStatusLoadEn);
        wire SysCommandACK = (CommandACK && CommandStoreEn) || (CommandACK && CommandAtomicLoadEn);
        wire SysCommandREQ;
        wire LocalCommandACK_Tmp;
        wire LocalCommandREQ_Tmp;
        // wire LocalCommandREQ = LocalCommandREQ_Tmp || ClockUpdate_Tmp || (LocalCommandStatusLoadEn && WritebackREQ && ~LocalResponseACK);
        wire LocalCommandREQ = LocalCommandREQ_Tmp || ClockUpdate_Tmp;
        wire [(PORTBYTEWIDTH*8)-1:0] LocalCommandData;
        wire                   [3:0] MinorOpcodeLocal;
        wire                   [3:0] DestRegLocal;
        wire      [DATABITWIDTH-1:0] DataAddrLocal;
        IOCommandInterface #(
            .DATABITWIDTH (DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH),
            .BUFFERCOUNT  (BUFFERCOUNT)
        ) StoreBuffer (
            .clk            (sys_clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .CommandInACK   (SysCommandACK),
            .CommandInREQ   (SysCommandREQ),
            .MinorOpcodeIn  (MinorOpcodeIn),
            .RegisterDestIn (CommandDestReg),
            .DataAddrIn     (CommandAddressIn_Offest),
            .DataIn         (CommandDataIn),
            .CommandOutACK  (LocalCommandACK_Tmp),
            .CommandOutREQ  (LocalCommandREQ),
            .MinorOpcodeOut (MinorOpcodeLocal),
            .RegisterDestOut(DestRegLocal),
            .DataAddrOut    (DataAddrLocal),
            .DataOut        (LocalCommandData)
        );
    //

    // Sys to Target FIFO CDC
        // wire                           LocalCommandACK = LocalCommandACK_Tmp && ~ClockUpdate && ~LocalCommandStatusLoadEn;
        wire                           LocalCommandACK = LocalCommandACK_Tmp && ~ClockUpdate;
        wire                           TargetCommandACK;
        wire                           TargetCommandREQ;
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dIn = {LocalCommandAtomicLoadEn, DestRegLocal, LocalCommandData};
        wire [SYSTOTARGETBITWIDTH-1:0] SysToTargetCDC_dOut;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH  (SYSTOTARGETBITWIDTH),
            .DEPTH     (8),
            .TESTENABLE(0)
        ) SysToTargetCDC (
            // .rst    (async_rst),
            .rst    (sync_rst),
            .w_clk  (sys_clk),
            .dInACK (LocalCommandACK),
            .dInREQ (LocalCommandREQ_Tmp),
            .dIN    (SysToTargetCDC_dIn),
            .r_clk  (target_clk),
            // .dOutACK(TargetCommandACK),
            // .dOutREQ(TargetCommandREQ),
            .dOutACK(IOOut_ACK),
            .dOutREQ(IOOut_REQ),
            .dOUT   (SysToTargetCDC_dOut)
        );
    //

    // Data Load Buffer System
        reg  [(PORTBYTEWIDTH*8)-1:0] LoadBuffer;
        wire                         LoadBufferTrigger = (LocalResponseACK && LocalResponseREQ && clk_en) || sync_rst;
        wire [(PORTBYTEWIDTH*8)-1:0] NextLoadBuffer = (sync_rst) ? 0 : TargetToSysCDC_dOut[(PORTBYTEWIDTH*8)-1:0];
        always_ff @(posedge sys_clk) begin
            if (LoadBufferTrigger) begin
                LoadBuffer <= NextLoadBuffer;
            end
        end
    //

    // Target to Sys FIFO CDC
        wire                           TargetResponseACK;
        wire                           TargetResponseREQ;
        // wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dIn = {IORegResponseFlag, IODestRegIn, IODataIn};
        wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dIn = {IOIn_RegResponseFlag, IOIn_DestReg, IOIn_Data};
        wire [TARGETTOSYSBITWIDTH-1:0] TargetToSysCDC_dOut;
        wire LocalIORegResponse = TargetToSysCDC_dOut[TARGETTOSYSBITWIDTH-1];
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(TARGETTOSYSBITWIDTH),
            .DEPTH   (8),
            .TESTENABLE(0)
        ) TargetToSysCDC (
            // .rst    (async_rst),
            .rst    (sync_rst),
            .w_clk  (target_clk),
            // .dInACK (TargetResponseACK),
            // .dInREQ (TargetResponseREQ),
            .dInACK (IOIn_ACK),
            .dInREQ (IOIn_REQ),
            .dIN    (TargetToSysCDC_dIn),
            .r_clk  (sys_clk),
            .dOutACK(LocalResponseACK),
            .dOutREQ(LocalResponseREQ),
            .dOUT   (TargetToSysCDC_dOut)
        );
    //

    // IO Domain Control
        assign IOOut_ResponseRequested = SysToTargetCDC_dOut[SYSTOTARGETBITWIDTH-1];
        assign IOOut_DestReg = SysToTargetCDC_dOut[SYSTOTARGETBITWIDTH-2:(PORTBYTEWIDTH*8)];
        assign IOOut_Data = SysToTargetCDC_dOut[(PORTBYTEWIDTH*8)-1:0];
    //

endmodule