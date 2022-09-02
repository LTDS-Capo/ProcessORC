module PlatformIndependent #(
    parameter DATABITWIDTH = 16
)(
    input sys_clk,
    input clk_en,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

// $$GEN$$ IOGen(TopPorts)

// $$GENEND$$

    input  [3:0] TESTBITS_IN,
    output [3:0] TESTBITS_OUT
);

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
        SystemFlasher #(
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
        CPU_TopLevel #(
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
            .RegisterWriteData_OUT(), // Do Not Connect - Test Output
            .RegisterWriteEn_OUT  (), // Do Not Connect - Test Output
            .RegisterWriteAddr_OUT()  // Do Not Connect - Test Output
        );
    //

    // IO Interfaces
        // $$GEN$$ IOGen(Top)
            IOManager #(
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
                .EXAMPLE_IO_Clk              (EXAMPLE_IO_Clk),
                .EXAMPLE_IO_ACK              (EXAMPLE_IO_ACK),
                .EXAMPLE_IO_REQ              (EXAMPLE_IO_REQ),
                .EXAMPLE_IO_CommandEn        (EXAMPLE_IO_CommandEn),
                .EXAMPLE_IO_ResponseRequested(EXAMPLE_IO_ResponseRequested),
                .EXAMPLE_IO_CommandResponse  (EXAMPLE_IO_CommandResponse),
                .EXAMPLE_IO_RegResponseFlag  (EXAMPLE_IO_RegResponseFlag),
                .EXAMPLE_IO_MemResponseFlag  (EXAMPLE_IO_MemResponseFlag),
                .EXAMPLE_IO_DestRegIn        (EXAMPLE_IO_DestRegIn),
                .EXAMPLE_IO_DestRegOut       (EXAMPLE_IO_DestRegOut),
                .EXAMPLE_IO_DataIn           (EXAMPLE_IO_DataIn),
                .EXAMPLE_IO_DataOut          (EXAMPLE_IO_DataOut)
            );
            // Module Generation

        // $$GENEND$$
    //


endmodule