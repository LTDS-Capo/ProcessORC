module IOManager_Test #(
    parameter DATABITWIDTH = 16,
    parameter IOBASEADDR = 384,
    parameter TOTALIOBYTES = 116, // 128 minus 8 for Clocks and 4 for Timers
    parameter IODEVICES = 2
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

    output        GPIO_IO_Clk,

    output        GPIO_IOOut_ACK,
    input         GPIO_IOOut_REQ,
    output        GPIO_IOOut_ResponseRequested,
    output  [3:0] GPIO_IOOut_DestReg,
    output [15:0] GPIO_IOOut_Data,

    input         GPIO_IOIn_ACK,
    output        GPIO_IOIn_REQ,
    input         GPIO_IOIn_RegResponseFlag,
    input         GPIO_IOIn_MemResponseFlag,
    input   [3:0] GPIO_IOIn_DestReg,
    input  [15:0] GPIO_IOIn_Data,

    output        Flasher_IOOut_ACK,
    input         Flasher_IOOut_REQ,
    output        Flasher_IOOut_ResponseRequested,
    output  [3:0] Flasher_IOOut_DestReg,
    output [31:0] Flasher_IOOut_Data,

    input         Flasher_IOIn_ACK,
    output        Flasher_IOIn_REQ,
    input         Flasher_IOIn_RegResponseFlag,
    input         Flasher_IOIn_MemResponseFlag,
    input   [3:0] Flasher_IOIn_DestReg,
    input  [31:0] Flasher_IOIn_Data

);
    
    localparam TOTALIODEVICES = IODEVICES + 2; // 1 for Timers, 1 for Clocks
    localparam TOTALIORESPONSES = IODEVICES + 12; // 8 for Timers, 4 for Clocks
    localparam PORTADDRWIDTH = $clog2(TOTALIORESPONSES);
    wire [TOTALIORESPONSES-1:0]                   WritebackACKArray;
    wire [TOTALIORESPONSES-1:0]                   WritebackREQArray;
    wire [TOTALIORESPONSES-1:0]             [3:0] WritebackDestRegArray;
    wire [TOTALIORESPONSES-1:0][DATABITWIDTH-1:0] WritebackDataOutArray;

// Clocks
    localparam CLOCKS_LOWERADDR = 0;
    localparam CLOCKS_UPPERADDR = 7;
    // wire ClockEn = CommandAddressIn inside {[CLOCKS_UPPERADDR:CLOCKS_LOWERADDR]} ? 1 : '0;
    wire                      ClockEn_Min = CommandAddressIn >= (CLOCKS_LOWERADDR + IOBASEADDR);
    wire                      ClockEn_Max = CommandAddressIn <= (CLOCKS_UPPERADDR + IOBASEADDR);
    wire                      ClockEn = ClockEn_Min && ClockEn_Max;
    wire                      ClockCommandACK = ClockEn ? CommandACK : '0;
    wire                      ClockCommandREQ;
    assign                    IOCommandREQArray[0] = ClockCommandREQ && ClockEn;
    wire   [DATABITWIDTH-1:0] ClockAddressIn = CommandAddressIn - CLOCKS_LOWERADDR - IOBASEADDR;
    wire           [7:0]      divided_clks;
    wire           [3:0][1:0] divided_clk_sels;
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

// Timers
    localparam TIMER_LOWERADDR = 8;
    localparam TIMER_UPPERADDR = 11;
    //wire   TimersEn = CommandAddressIn inside {[TIMER_UPPERADDR:TIMER_LOWERADDR]} ? 1 : '0;
    wire                      TimersEn_Min = CommandAddressIn >= (TIMER_LOWERADDR + IOBASEADDR);
    wire                      TimersEn_Max = CommandAddressIn <= (TIMER_UPPERADDR + IOBASEADDR);
    wire                      TimersEn = TimersEn_Min && TimersEn_Max;
    wire                      Timers_CommandACK = TimersEn ? CommandACK : '0;
    wire                      Timers_CommandREQ;
    assign                    IOCommandREQArray[1] = Timers_CommandREQ && TimersEn;
    wire   [DATABITWIDTH-1:0] Timers_AddressIn = CommandAddressIn - TIMER_LOWERADDR - IOBASEADDR;
    CommandTimers #(
        .DATABITWIDTH(DATABITWIDTH)
    ) SystemTimers (
        .clk            (sys_clk),
        .clk_en         (clk_en),
        .sync_rst       (sync_rst),
        .IOInACK        (Timers_CommandACK),
        .IOInREQ        (Timers_CommandREQ),
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
            localparam GPIO_DEVICE_INDEX = 2; // Starts at 2
            localparam GPIO_IO_INDEX = 12; // Starts at 12
            localparam GPIO_LOWERADDR = 12;
            localparam GPIO_UPPERADDR = 13;
            localparam GPIO_PORTBYTEWIDTH = 2;
            localparam GPIO_CLOCKCOMMAND_ENABLE = 1;
            localparam GPIO_CLOCKCOMMAND_LSB = 0;
            localparam GPIO_CLOCKCOMMAND_MSB = 12;
            localparam GPIO_CLOCKCOMMAND_OPCODE = 13'h1C00; // 1_1100_0000_0000
            localparam GPIO_CLOCKCOMMAND_CLKSELLSB = 13;
            // wire                      GPIO_En = CommandAddressIn inside {[GPIO_UPPERADDR:GPIO_LOWERADDR]} ? 1 : '0;
            wire                      GPIO_En_Min = CommandAddressIn >= (GPIO_LOWERADDR + IOBASEADDR);
            wire                      GPIO_En_Max = CommandAddressIn <= (GPIO_UPPERADDR + IOBASEADDR);
            wire                      GPIO_En = GPIO_En_Min && GPIO_En_Max;
            wire                      GPIO_CommandACK = GPIO_En ? CommandACK : '0;
            wire                      GPIO_CommandREQ;
            assign                    IOCommandREQArray[GPIO_DEVICE_INDEX] = GPIO_CommandREQ && GPIO_En;
            wire   [DATABITWIDTH-1:0] GPIO_AddressIn = CommandAddressIn - GPIO_LOWERADDR - IOBASEADDR;
            CommandController #(
                .PORTBYTEWIDTH         (GPIO_PORTBYTEWIDTH),
                .CLOCKCOMMAND_ENABLE   (GPIO_CLOCKCOMMAND_ENABLE),
                .CLOCKCOMMAND_LSB      (GPIO_CLOCKCOMMAND_LSB),
                .CLOCKCOMMAND_MSB      (GPIO_CLOCKCOMMAND_MSB),
                .CLOCKCOMMAND_OPCODE   (GPIO_CLOCKCOMMAND_OPCODE),
                .CLOCKCOMMAND_CLKSELLSB(GPIO_CLOCKCOMMAND_CLKSELLSB),
                .DATABITWIDTH          (DATABITWIDTH)
            ) GPIO_PortController (
                .sys_clk                (sys_clk),
                .clk_en                 (clk_en),
                .sync_rst               (sync_rst),
                .async_rst              (async_rst),
                .src_clk0               (src_clk0),
                .src_clk1               (src_clk1),
                .src_clk2               (src_clk2),
                .divided_clks           (divided_clks),
                .divided_clk_sels       (divided_clk_sels),
                .CommandACK             (GPIO_CommandACK),
                .CommandREQ             (GPIO_CommandREQ),
                .MinorOpcodeIn          (MinorOpcodeIn),
                .CommandAddressIn_Offest(GPIO_AddressIn),
                .CommandDataIn          (CommandDataIn),
                .CommandDestReg         (CommandDestReg),
                .WritebackACK           (WritebackACKArray[GPIO_IO_INDEX]),
                .WritebackREQ           (WritebackREQArray[GPIO_IO_INDEX]),
                .WritebackDestReg       (WritebackDestRegArray[GPIO_IO_INDEX]),
                .WritebackDataOut       (WritebackDataOutArray[GPIO_IO_INDEX]),
                .IOClk                  (GPIO_IO_Clk),
                .IOOut_ACK              (GPIO_IOOut_ACK),
                .IOOut_REQ              (GPIO_IOOut_REQ),
                .IOOut_ResponseRequested(GPIO_IOOut_ResponseRequested),
                .IOOut_DestReg          (GPIO_IOOut_DestReg),
                .IOOut_Data             (GPIO_IOOut_Data),
                .IOIn_ACK               (GPIO_IOIn_ACK),
                .IOIn_REQ               (GPIO_IOIn_REQ),
                .IOIn_RegResponseFlag   (GPIO_IOIn_RegResponseFlag),
                .IOIn_MemResponseFlag   (GPIO_IOIn_MemResponseFlag),
                .IOIn_DestReg           (GPIO_IOIn_DestReg),
                .IOIn_Data              (GPIO_IOIn_Data)
            );
        //

        // Flash Port Controller
            localparam FLASHER_DEVICE_INDEX = 3; // Starts at 2
            localparam FLASHER_IO_INDEX = 13; // Starts at 12
            localparam FLASHER_LOWERADDR = 14; // Starts at 12
            localparam FLASHER_UPPERADDR = 17;
            localparam FLASHER_PORTBYTEWIDTH = 4;
            localparam FLASHER_CLOCKCOMMAND_ENABLE = '0;
            localparam FLASHER_CLOCKCOMMAND_LSB = '0;
            localparam FLASHER_CLOCKCOMMAND_MSB = '0;
            localparam FLASHER_CLOCKCOMMAND_OPCODE = '0; // 1_1100_0000_0000
            localparam FLASHER_CLOCKCOMMAND_CLKSELLSB = '0;
            wire                      Flasher_En_Min = CommandAddressIn >= (FLASHER_LOWERADDR + IOBASEADDR);
            wire                      Flasher_En_Max = CommandAddressIn <= (FLASHER_UPPERADDR + IOBASEADDR);
            wire                      Flasher_En = Flasher_En_Min && Flasher_En_Max;
            wire                      Flasher_CommandACK = Flasher_En ? CommandACK : '0;
            wire                      Flasher_CommandREQ;
            assign                    IOCommandREQArray[FLASHER_DEVICE_INDEX] = Flasher_CommandREQ && Flasher_En;
            wire   [DATABITWIDTH-1:0] Flasher_AddressIn = CommandAddressIn - FLASHER_LOWERADDR - IOBASEADDR;
            CommandController #(
                .PORTBYTEWIDTH         (FLASHER_PORTBYTEWIDTH),
                .CLOCKCOMMAND_ENABLE   (FLASHER_CLOCKCOMMAND_ENABLE),
                .CLOCKCOMMAND_LSB      (FLASHER_CLOCKCOMMAND_LSB),
                .CLOCKCOMMAND_MSB      (FLASHER_CLOCKCOMMAND_MSB),
                .CLOCKCOMMAND_OPCODE   (FLASHER_CLOCKCOMMAND_OPCODE),
                .CLOCKCOMMAND_CLKSELLSB(FLASHER_CLOCKCOMMAND_CLKSELLSB),
                .DATABITWIDTH          (DATABITWIDTH)
            ) Flasher_PortController (
                .sys_clk                (sys_clk),
                .clk_en                 (clk_en),
                .sync_rst               (sync_rst),
                .async_rst              (async_rst),
                .src_clk0               (src_clk0),
                .src_clk1               (src_clk1),
                .src_clk2               (src_clk2),
                .divided_clks           (divided_clks),
                .divided_clk_sels       (divided_clk_sels),
                .CommandACK             (Flasher_CommandACK),
                .CommandREQ             (Flasher_CommandREQ),
                .MinorOpcodeIn          (MinorOpcodeIn),
                .CommandAddressIn_Offest(Flasher_AddressIn),
                .CommandDataIn          (CommandDataIn),
                .CommandDestReg         (CommandDestReg),
                .WritebackACK           (WritebackACKArray[FLASHER_IO_INDEX]),
                .WritebackREQ           (WritebackREQArray[FLASHER_IO_INDEX]),
                .WritebackDestReg       (WritebackDestRegArray[FLASHER_IO_INDEX]),
                .WritebackDataOut       (WritebackDataOutArray[FLASHER_IO_INDEX]),
                .IOOut_ACK              (Flasher_IOOut_ACK),
                .IOOut_REQ              (Flasher_IOOut_REQ),
                .IOOut_ResponseRequested(Flasher_IOOut_ResponseRequested),
                .IOOut_DestReg          (Flasher_IOOut_DestReg),
                .IOOut_Data             (Flasher_IOOut_Data),
                .IOIn_ACK               (Flasher_IOIn_ACK),
                .IOIn_REQ               (Flasher_IOIn_REQ),
                .IOIn_RegResponseFlag   (Flasher_IOIn_RegResponseFlag),
                .IOIn_MemResponseFlag   (Flasher_IOIn_MemResponseFlag),
                .IOIn_DestReg           (Flasher_IOIn_DestReg),
                .IOIn_Data              (Flasher_IOIn_Data)
            );
        //
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
            .InputData (WritebackDataOutArray),
            .InputAddr (WritebackDestRegArray),
            .OutputACK (WritebackACK),
            .OutputREQ (WritebackREQ),
            .OutputData(WritebackDataOut),
            .OutputAddr(WritebackDestReg)
        );
    //

    // Output Assignments
        // Output Handshakes

        // Input Handshake
        assign CommandREQ = |IOCommandREQArray;

    //

endmodule