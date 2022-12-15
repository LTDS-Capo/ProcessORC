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

);

    assign CPU_Halted = Halted;
    

    // Reset Syncronization
        localparam CLOCKDOMAINS = 4;
        wire [CLOCKDOMAINS-2:0] ResetClks = {src_clk2, src_clk1, src_clk0};
        wire [CLOCKDOMAINS-2:0] Lower_sync_rst_trigger = '0;
        wire [CLOCKDOMAINS-1:0] sync_rst_trigger = {ResetTrigger, Lower_sync_rst_trigger};
        wire [CLOCKDOMAINS-1:0] clk_en_out;
        wire [CLOCKDOMAINS-1:0] sync_rst_out;
        wire [CLOCKDOMAINS-1:0] init_out;
        wire async_rst_Tmp;
        wire Local_async_rst = async_rst || async_rst_Tmp;
        TopLevelReset #(
            // .RESETWAITCYCLES      (625000),
            .RESETWAITCYCLES      (64),
            .RESETCYCLELENGTH     (32),
            // .OPERATIONALWAITCYCLES(25000),
            .OPERATIONALWAITCYCLES(64),
            // .INITIALIZEWAITCYCLES (1024),
            .INITIALIZEWAITCYCLES (32),
            .CLOCKDOMAINS         (CLOCKDOMAINS)
        ) ResetSystem (
            .sys_clk         (sys_clk),
            .clk_en          (clk_en),
            .async_rst_in    (async_rst),
            .async_rst_out   (async_rst_Tmp),
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
        // MemoryFlasher #(
        //     .MEMMAPSTARTADDR(384),
        //     .MEMMAPENDADDR(511)
        // ) Flasher (
        //     .clk         (sys_clk),
        //     .clk_en      (clk_en_out[3]),
        //     .sync_rst    (sync_rst_out[3]),
        //     .FlashInit   (init_out[3]),
        //     .InstFlashEn (InstFlashEn),
        //     .DataFlashEn (DataFlashEn),
        //     .FlashAddr   (FlashAddr),
        //     .FlashData   (FlashData),
        //     .SystemEnable(SystemEn)
        // );

        wire        SoftwareReset;
        wire  [3:0] ResetVector;
        wire        ResetResponse;
        wire        ResetTrigger;
        wire        CPUResetLockout;
        wire        IOResetLockout;

        wire        Flasher_IOOut_ACK;
        wire        Flasher_IOOut_REQ;
        wire        Flasher_IOOut_ResponseRequested;
        wire  [3:0] Flasher_IOOut_DestReg;
        wire [31:0] Flasher_IOOut_Data;

        wire        Flasher_IOIn_ACK;
        wire        Flasher_IOIn_REQ;
        wire        Flasher_IOIn_RegResponseFlag;
        wire        Flasher_IOIn_MemResponseFlag;
        wire  [3:0] Flasher_IOIn_DestReg;
        wire [31:0] Flasher_IOIn_Data;
        IO_MemoryFlasher #(
            .MEMMAPSTARTADDR(384),
            .MEMMAPENDADDR(511)
        ) IOFlasher(
            .clk                    (sys_clk),
            .clk_en                 (clk_en_out[3]),
            .sync_rst               (sync_rst_out[3]),
            .FlashInit              (init_out[3]),
            .InstFlashEn            (InstFlashEn),
            .DataFlashEn            (DataFlashEn),
            .FlashAddr              (FlashAddr),
            .FlashData              (FlashData),
            .SoftwareResetIn        (SoftwareReset),
            .ResetVectorIn          (ResetVector),
            .ResetResponseOut       (ResetResponse),
            .ResetTriggerOut        (ResetTrigger),
            .CPUResetLockoutOut     (CPUResetLockout),
            .IOResetLockoutOut      (IOResetLockout),
            .SystemEnable           (SystemEn),
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

    // CPU - ProcessORC
        wire CPU_sync_rst = sync_rst_out[3] && ~CPUResetLockout;
        wire Halted;
        wire IOOutACK;
        wire IOOutREQ;
        wire              [3:0] IOMinorOpcode;
        wire [DATABITWIDTH-1:0] IOOutAddress;
        wire [DATABITWIDTH-1:0] IOOutData;
        wire              [3:0] IOOutDestReg;
        wire                    IOInACK;
        wire                    IOInREQ;
        wire              [3:0] IOInDestReg;
        wire [DATABITWIDTH-1:0] IOInData;
        CPU #(
            .DATABITWIDTH(DATABITWIDTH)
        ) MainCPU (
            .clk                  (sys_clk),
            .clk_en               (clk_en_out[3]),
            .sync_rst             (CPU_sync_rst),
            .SystemEn             (SystemEn),
            .HaltOut              (Halted),
            .SoftwareResetOut     (SoftwareReset),
            .ResetVector          (ResetVector),
            .ResetResponse        (ResetResponse),
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
            .RegisterWriteData_OUT(), // Do Not Connect - Test Output
            .RegisterWriteEn_OUT  (), // Do Not Connect - Test Output
            .RegisterWriteAddr_OUT()  // Do Not Connect - Test Output
        );
    //

    // IO Interfaces
            wire IO_sync_rst = sync_rst_out[3] && ~IOResetLockout;
            
            wire        GPIO_IO_Clk;

            wire        GPIO_IOOut_ACK;
            wire        GPIO_IOOut_REQ;
            wire        GPIO_IOOut_ResponseRequested;
            wire  [3:0] GPIO_IOOut_DestReg;
            wire [15:0] GPIO_IOOut_Data;

            wire        GPIO_IOIn_ACK;
            wire        GPIO_IOIn_REQ;
            wire        GPIO_IOIn_RegResponseFlag;
            wire        GPIO_IOIn_MemResponseFlag;
            wire  [3:0] GPIO_IOIn_DestReg;
            wire [15:0] GPIO_IOIn_Data;

            IOManager_Test #(
                .IOBASEADDR  (384),
                .TOTALIOBYTES(128)
            ) IOInterface (
                .sys_clk         (sys_clk),
                .clk_en          (clk_en_out[3]),
                .sync_rst        (IO_sync_rst),
                .async_rst       (Local_async_rst),
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
                .GPIO_IO_Clk                 (GPIO_IO_Clk),
                .GPIO_IOOut_ACK              (GPIO_IOOut_ACK),
                .GPIO_IOOut_REQ              (GPIO_IOOut_REQ),
                .GPIO_IOOut_ResponseRequested(GPIO_IOOut_ResponseRequested),
                .GPIO_IOOut_DestReg          (GPIO_IOOut_DestReg),
                .GPIO_IOOut_Data             (GPIO_IOOut_Data),
                .GPIO_IOIn_ACK               (GPIO_IOIn_ACK),
                .GPIO_IOIn_REQ               (GPIO_IOIn_REQ),
                .GPIO_IOIn_RegResponseFlag   (GPIO_IOIn_RegResponseFlag),
                .GPIO_IOIn_MemResponseFlag   (GPIO_IOIn_MemResponseFlag),
                .GPIO_IOIn_DestReg           (GPIO_IOIn_DestReg),
                .GPIO_IOIn_Data              (GPIO_IOIn_Data),
                .Flasher_IOOut_ACK              (Flasher_IOOut_ACK),
                .Flasher_IOOut_REQ              (Flasher_IOOut_REQ),
                .Flasher_IOOut_ResponseRequested(Flasher_IOOut_ResponseRequested),
                .Flasher_IOOut_DestReg          (Flasher_IOOut_DestReg),
                .Flasher_IOOut_Data             (Flasher_IOOut_Data),
                .Flasher_IOIn_ACK               (Flasher_IOIn_ACK),
                .Flasher_IOIn_REQ               (Flasher_IOIn_REQ),
                .Flasher_IOIn_RegResponseFlag   (Flasher_IOIn_RegResponseFlag),
                .Flasher_IOIn_MemResponseFlag   (Flasher_IOIn_MemResponseFlag),
                .Flasher_IOIn_DestReg           (Flasher_IOIn_DestReg),
                .Flasher_IOIn_Data              (Flasher_IOIn_Data)
            );
        // IO Modules
            GPIOController GPIOInterface(
                .clk                    (GPIO_IO_Clk),
                .clk_en                 (clk_en_out[3]),
                .sync_rst               (sync_rst_out[3]),
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
                .IOIn_Data              (GPIO_IOIn_Data),       
                .GPIO_DIn            (GPIO_DIn),
                .GPIO_DOut           (GPIO_DOut),
                .GPIO_DOutEn         (GPIO_DOutEn)
            );
    //


endmodule