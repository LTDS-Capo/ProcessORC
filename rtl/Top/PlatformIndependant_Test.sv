module PlatformIndependent_Test #(
    parameter DATABITWIDTH = 16
)(
    input sys_clk,
    input clk_en,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input   [7:0] GPIO_DIn,
    output  [7:0] GPIO_DOut,
    output  [7:0] GPIO_DOutEn,

    output CPU_Halted

    // Test Outputs
    // output        Test_InstFlashEn,
    // output        Test_DataFlashEn,
    // output  [9:0] Test_FlashAddr,
    // output [15:0] Test_FlashData,
    // output        Test_SystemEnable,
    // output [DATABITWIDTH-1:0] RegisterWriteData_OUT,
    // output                    RegisterWriteEn_OUT,
    // output              [3:0] RegisterWriteAddr_OUT,

    // input  [3:0] TESTBITS_IN,
    // output [3:0] TESTBITS_OUT
);

    assign CPU_Halted = Halted;
    
    // assign Test_InstFlashEn = InstFlashEn;
    // assign Test_DataFlashEn = DataFlashEn;
    // assign Test_FlashAddr = FlashAddr;
    // assign Test_FlashData = FlashData;
    // assign Test_SystemEnable = SystemEn;

    // Reset Syncronization
        localparam CLOCKDOMAINS = 4;
        wire [CLOCKDOMAINS-2:0] ResetClks = {src_clk2, src_clk1, src_clk0};
        wire [CLOCKDOMAINS-1:0] sync_rst_trigger = '0;
        wire [CLOCKDOMAINS-1:0] clk_en_out;
        wire [CLOCKDOMAINS-1:0] sync_rst_out;
        wire [CLOCKDOMAINS-1:0] init_out;
        TopLevelReset #(
            .RESETWAITCYCLES      (625000),
            .RESETCYCLELENGTH     (16),
            .OPERATIONALWAITCYCLES(25000),
            .INITIALIZEWAITCYCLES (1024),
            .CLOCKDOMAINS         (CLOCKDOMAINS)
        ) ResetSystem (
            .sys_clk         (sys_clk),
            .clk_en          (clk_en),
            .async_rst_in    (async_rst),
            .clks            (ResetClks),
            .sync_rst_trigger(sync_rst_trigger),
            .clk_en_out      (clk_en_out),
            .sync_rst_out    (sync_rst_out),
            .init_out        (init_out)
        );
    //

    // Flashing System
        wire        InstFlashEn;
        wire        DataFlashEn;
        wire  [9:0] FlashAddr;
        wire [15:0] FlashData;
        wire        SystemEn;
        MemoryFlasher #(
            .MEMMAPSTARTADDR(384),
            .MEMMAPENDADDR(511)
        )Flasher (
            .clk         (sys_clk),
            .clk_en      (clk_en_out[3]),
            .sync_rst    (sync_rst_out[3]),
            .FlashInit   (init_out[3]),
            .InstFlashEn (InstFlashEn),
            .DataFlashEn (DataFlashEn),
            .FlashAddr   (FlashAddr),
            .FlashData   (FlashData),
            .SystemEnable(SystemEn)
        );
    //

    // CPU - ProcessORC
        wire Halted;
        wire IOOutACK;
        wire IOOutREQ;
        wire IOMinorOpcode;
        wire IOOutAddress;
        wire IOOutData;
        wire IOOutDestReg;
        wire IOInACK;
        wire IOInREQ;
        wire IOInDestReg;
        wire IOInData;
        CPU #(
            .DATABITWIDTH(DATABITWIDTH)
        ) MainCPU (
            .clk                  (sys_clk),
            .clk_en               (clk_en_out[3]),
            .sync_rst             (sync_rst_out[3]),
            .SystemEn             (SystemEn),
            .HaltOut              (Halted),
            .InstFlashEn          (InstFlashEn),
            .DataFlashEn          (DataFlashEn),
            .FlashAddr            (FlashAddr),
            .FlashData            (FlashData),
            .IOOutACK             (IOOutACK),
            .IOOutREQ             (IOOutREQ),
            .IOMinorOpcode        (IOMinorOpcode),
            .IOOutAddress         (IOOutAddress),
            .IOOutData            (IOOutData),
            .IOOutDestReg         (IOOutDestReg),
            .IOInACK              (IOInACK),
            .IOInREQ              (IOInREQ),
            .IOInDestReg          (IOInDestReg),
            .IOInData             (IOInData),
            .RegisterWriteData_OUT(RegisterWriteData_OUT), // Do Not Connect - Test Output
            .RegisterWriteEn_OUT  (RegisterWriteEn_OUT), // Do Not Connect - Test Output
            .RegisterWriteAddr_OUT(RegisterWriteAddr_OUT)  // Do Not Connect - Test Output
        );
    //

    // IO Interfaces
            // wire GPIO_IO_Clk;
            // wire GPIO_IO_ACK;
            // wire GPIO_IO_REQ;
            // wire GPIO_IO_CommandEn;
            // wire GPIO_IO_ResponseRequested;
            // wire GPIO_IO_CommandResponse;
            // wire GPIO_IO_RegResponseFlag;
            // wire GPIO_IO_MemResponseFlag;
            // wire GPIO_IO_DestRegIn;
            // wire GPIO_IO_DestRegOut;
            // wire GPIO_IO_DataIn;
            // wire GPIO_IO_DataOut;
            IOManager_Test #(
                .IOBASEADDR  (384),
                .TOTALIOBYTES(128)
            ) IOInterface (
                .sys_clk         (sys_clk),
                .clk_en          (clk_en_out[3]),
                .sync_rst        (sync_rst_out[3]),
                .async_rst       (async_rst),
                .src_clk0        (src_clk0),
                .src_clk1        (src_clk1),
                .src_clk2        (src_clk2),
                .CommandACK      (IOOutACK),
                .CommandREQ      (IOOutREQ),
                .MinorOpcodeIn   (IOMinorOpcode),
                .CommandAddressIn(IOOutAddress),
                .CommandDataIn   (IOOutData),
                .CommandDestReg  (IOOutDestReg),
                .WritebackACK    (IOInACK),
                .WritebackREQ    (IOInREQ),
                .WritebackDestReg(IOInDestReg),
                .WritebackDataOut(IOInData),
                .GPIO_IO_Clk              (GPIO_IO_Clk),
                .GPIO_IO_ACK              (GPIO_IO_ACK),
                .GPIO_IO_REQ              (GPIO_IO_REQ),
                .GPIO_IO_CommandEn        (GPIO_IO_CommandEn),
                .GPIO_IO_ResponseRequested(GPIO_IO_ResponseRequested),
                .GPIO_IO_CommandResponse  (GPIO_IO_CommandResponse),
                .GPIO_IO_RegResponseFlag  (GPIO_IO_RegResponseFlag),
                .GPIO_IO_MemResponseFlag  (GPIO_IO_MemResponseFlag),
                .GPIO_IO_DestRegIn        (GPIO_IO_DestRegIn),
                .GPIO_IO_DestRegOut       (GPIO_IO_DestRegOut),
                .GPIO_IO_DataIn           (GPIO_IO_DataIn),
                .GPIO_IO_DataOut          (GPIO_IO_DataOut)
            );
        // IO Modules
            GPIOController GPIOInterface(
                .clk                 (GPIO_IO_Clk),
                .clk_en              (clk_en_out[3]),
                .sync_rst            (sync_rst_out[3]),
                .IO_ACK              (GPIO_IO_ACK),
                .IO_REQ              (GPIO_IO_REQ),
                .IO_CommandEn        (GPIO_IO_CommandEn),
                .IO_ResponseRequested(GPIO_IO_ResponseRequested),
                .IO_CommandResponse  (GPIO_IO_CommandResponse),
                .IO_RegResponseFlag  (GPIO_IO_RegResponseFlag),
                .IO_MemResponseFlag  (GPIO_IO_MemResponseFlag),
                .IO_DestRegIn        (GPIO_IO_DestRegOut),
                .IO_DestRegOut       (GPIO_IO_DestRegIn),
                .IO_DataIn           (GPIO_IO_DataOut),
                .IO_DataOut          (GPIO_IO_DataIn),
                .GPIO_DIn            (GPIO_DIn),
                .GPIO_DOut           (GPIO_DOut),
                .GPIO_DOutEn         (GPIO_DOutEn)
            );
    //


endmodule