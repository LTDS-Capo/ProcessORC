module IOManager_PreGen #(
    parameter IOBASEADDR = 384,
    parameter TOTALIOBYTES = 116, // 128 minus 8 for Clocks and 4 for Timers

// $$GEN$$ gen_parameter(IO)
    parameter IODEVICES = 1,
    parameter IORESPONSES = 8,
// $$ENDGEN$$
)(
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input                     CommandACK,
    output                    CommandREQ,
    input               [3:0] MinorOpcodeIn,
    input  [DATABITWIDTH-1:0] CommandAddressIn,
    input  [DATABITWIDTH-1:0] CommandDataIn,
    input               [3:0] CommandDestReg,

    output                    WritebackACK,
    input                     WritebackREQ,
    output              [3:0] WritebackDestReg,
    output [DATABITWIDTH-1:0] WritebackDataOut,

// $$GEN$$ IOGen_Ports
    // $TEMPLATE$ Ports
    output       EXAMPLE_IO_Clk,
    input        EXAMPLE_IO_ACK,
    output       EXAMPLE_IO_REQ,
    output       EXAMPLE_IO_CommandEn,
    output       EXAMPLE_IO_ResponseRequested,
    input        EXAMPLE_IO_CommandResponse,
    input        EXAMPLE_IO_RegResponseFlag, // Force a Writeback handshake after updating local buffer
    input        EXAMPLE_IO_MemResponseFlag, // Only update local buffer
    input  [3:0] EXAMPLE_IO_DestRegIn,
    output [3:0] EXAMPLE_IO_DestRegOut,
    input  [#:0] EXAMPLE_IO_DataIn,
    output [#:0] EXAMPLE_IO_DataOut
    // $ENDTEMPLATE$
// $$ENDGEN$$
);
    
    localparam TOTALIODEVICES = IODEVICES + 2; // 1 for Timers, 1 for Clocks
    localparam TOTALIORESPONSES = IORESPONSES + 12; // 8 for Timers, 4 for Clocks
    localparam PORTADDRWIDTH = $clog2(TOTALIORESPONSES);
    wire                                          LoadEn = ~MinorOpcodeIn[2] && MinorOpcodeIn[3];
    wire                                          StoreEn = MinorOpcodeIn[2];
    wire [TOTALIORESPONSES-1:0]                   WritebackACKArray;
    wire [TOTALIORESPONSES-1:0]                   WritebackREQArray;
    wire [TOTALIORESPONSES-1:0]             [3:0] WritebackDestRegArray;
    wire [TOTALIORESPONSES-1:0][DATABITWIDTH-1:0] WritebackDataOutArray;

// Clocks
    localparam CLOCKS_LOWERADDR = 0;
    localparam CLOCKS_UPPERADDR = 7;
    assign ClockEn = CommandAddressIn inside {[CLOCKS_UPPERADDR:CLOCKS_LOWERADDR]};
    wire ClockCommandACK = ClockEn ? CommandACK : '0;
    wire ClockCommandREQ;
    wire IOCommandREQArray[0] = ClockCommandREQ && ClockEn;
    wire ClockAddressIn = CommandAddressIn - CLOCKS_LOWERADDR - IOBASEADDR;
    wire [7:0]      divided_clks;
    wire [3:0][1:0] divided_clk_sels;
    IOClkGeneration #(
        .DATABITWIDTH(DATABITWIDTH)
    ) ClockGeneration (
        .sys_clk                (sys_clk),
        .clk_en                 (clk_en),
        .sync_rst               (sync_rst),
        .src_clk0               (src_clk0),
        .src_clk1               (src_clk1),
        .src_clk2               (src_clk2),
        .CommandACK             (ClockCommandACK),
        .CommandREQ             (ClockCommandREQ),
        .MinorOpcodeIn          (MinorOpcodeIn),
        .CommandAddressIn_Offest(ClockAddressIn),
        .CommandDataIn          (CommandDataIn),
        .CommandDestReg         (CommandDestReg),
        .WritebackACK           (WritebackACKArray[3:0]),
        .WritebackREQ           (WritebackREQArray[3:0]),
        .WritebackDestReg       (WritebackDestRegArray[3:0]),
        .WritebackDataOut       (WritebackDataOutArray[3:0]),
        .divided_clk_out        (divided_clks),
        .divided_clk_sel_out    (divided_clk_sels)
    );
//

// Timers  // TODO: Load Alignment
    localparam TIMER_LOWERADDR = 8;
    localparam TIMER_UPPERADDR = 11;
    assign Timers_En = CommandAddressIn inside {[TIMER_UPPERADDR:TIMER_LOWERADDR]};
    wire   Timers_CommandACK = TimersEn ? CommandACK : '0;
    wire   Timers_CommandREQ;
    wire   IOCommandREQArray[1] = TimersCommandREQ && TimersEn;
    wire   Timers_AddressIn = CommandAddressIn - TIMER_LOWERADDR - IOBASEADDR;
    FBI_Timers #(
        .DATABITWIDTH(16)
    ) SystemTimers (
        .clk            (sys_clk),
        .clk_en         (clk_en),
        .sync_rst       (sync_rst),
        .IOInACK        (TimersCommandACK),
        .IOInREQ        (TimersCommandREQ),
        .MinorOpcodeIn  (MinorOpcodeIn),
        .RegisterDestIn (CommandDestReg),
        .DataAddrIn     (Timers_AddressIn),
        .DataIn         (CommandDataIn),
        .TimerOutACK    (WritebackACKArray[11:4]),
        .TimerOutREQ    (WritebackREQArray[11:4]),
        .RegisterDestOut(WritebackDestRegArray[11:4]),
        .TimerDataOut   (WritebackDataOutArray[11:4])
    );
//

// IO Interfaces
    // $$GEN$$ IOGen_Controllers(IO)
        wire [TOTALIODEVICES-1:0] IOCommandREQArray;
        // IO Port Controllers
            // $TEMPLATE$
            localparam EXAMPLE_IO_INDEX = 12; // Starts at 12
            localparam EXAMPLE_LOWERADDR = 4;
            localparam EXAMPLE_UPPERADDR = 11;
            localparam EXAMPLE_PORTBYTEWIDTH = 4;
            localparam EXAMPLE_CLOCKCOMMAND_LSB = 27;
            localparam EXAMPLE_CLOCKCOMMAND_MSB = 31;
            localparam EXAMPLE_CLOCKCOMMAND_OPCODE = 5'h1F,
            localparam EXAMPLE_CLOCKCOMMAND_CLKSELLSB = 24;
            assign                    EXAMPLE_En = CommandAddressIn inside {[EXAMPLE_UPPERADDR:EXAMPLE_LOWERADDR]};
            wire                      EXAMPLE_CommandACK = EXAMPLE_En ? CommandACK : '0;
            wire                      EXAMPLE_CommandREQ;
            wire                      IOCommandREQArray[EXAMPLE_IO_INDEX] = EXAMPLE_CommandREQ && EXAMPLE_En;
            wire                      EXAMPLE_AddressIn = CommandAddressIn - EXAMPLE_LOWERADDR - IOBASEADDR;
            CommandController #(
                .PORTBYTEWIDTH         (PORTBYTEWIDTH),
                .CLOCKCOMMAND_LSB      (CLOCKCOMMAND_LSB),
                .CLOCKCOMMAND_MSB      (CLOCKCOMMAND_MSB),
                .CLOCKCOMMAND_OPCODE   (CLOCKCOMMAND_OPCODE),
                .CLOCKCOMMAND_CLKSELLSB(CLOCKCOMMAND_CLKSELLSB),
                .DATABITWIDTH          (DATABITWIDTH)
            ) EXAMPLE_PortController (
                .sys_clk                (sys_clk),
                .clk_en                 (clk_en),
                .sync_rst               (sync_rst),
                .async_rst              (async_rst),
                .src_clk0               (src_clk0),
                .src_clk1               (src_clk1),
                .src_clk2               (src_clk2),
                .divided_clks           (divided_clks),
                .divided_clk_sels       (divided_clk_sels),
                .CommandACK             (EXAMPLE_CommandACK),
                .CommandREQ             (EXAMPLE_CommandREQ),
                .MinorOpcodeIn          (MinorOpcodeIn),
                .CommandAddressIn_Offest(EXAMPLE_AddressIn),
                .CommandDataIn          (CommandDataIn),
                .CommandDestReg         (CommandDestReg),
                .WritebackACK           (WritebackACKArray[EXAMPLE_IO_INDEX]),
                .WritebackREQ           (WritebackREQArray[EXAMPLE_IO_INDEX]),
                .WritebackDestReg       (WritebackDestRegArray[EXAMPLE_IO_INDEX]),
                .WritebackDataOut       (WritebackDataOutArray[EXAMPLE_IO_INDEX]),
                .IOClk                  (EXAMPLE_IO_Clk),
                .IOACK                  (EXAMPLE_IO_ACK),
                .IOREQ                  (EXAMPLE_IO_REQ),
                .IOCommandEn            (EXAMPLE_IO_CommandEn),
                .IOResponseRequested    (EXAMPLE_IO_ResponseRequested),
                .IOCommandResponse      (EXAMPLE_IO_CommandResponse),
                .IORegResponseFlag      (EXAMPLE_IO_RegResponseFlag),
                .IOMemResponseFlag      (EXAMPLE_IO_MemResponseFlag),
                .IODestRegIn            (EXAMPLE_IO_DestRegIn),
                .IODataIn               (EXAMPLE_IO_DestRegOut),
                .IODestRegOut           (EXAMPLE_IO_DataIn),
                .IODataOut              (EXAMPLE_IO_DataOut)
            );
            // $ENDTEMPLATE$
        //
    // $$ENDGEN$$


//

    // Writeback Handshake Control
        HandshakeMux #(
            .DATABITWIDTH(DATABITWIDTH),
            .INPUTPORTCOUNT(TOTALIORESPONSES),
            .PORTADDRWIDTH(PORTADDRWIDTH),
            .REGADDRBITWIDTH(4)
        ) WritebackMux (
            .clk       (sys_clk),
            .clk_en    (clk_en),
            .sync_rst  (sync_rst),
            .InputREQ  (WritebackREQArray),
            .InputACK  (WritebackACKArray),
            .InputData (WritebackDestRegArray),
            .InputAddr (WritebackDataOutArray),
            .OutputACK (WritebackACK),
            .OutputREQ (WritebackREQ),
            .OutputData(WritebackDestReg),
            .OutputAddr(WritebackDataOut)
        );
    //

    // Output Assignments
        // Output Handshakes

        // Input Handshake
        assign CommandREQ = |IOCommandREQArray;

    //

endmodule