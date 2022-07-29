module ORConfig_IO_SPI (
    input clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input clk_25,
    input clk_en_25,
    input sync_rst_25, 

    input  PortREQ,
    output PortACK,
    input   [3:0] Command,
    input  [15:0] DataIn,
    output [15:0] DataOutLower,
    output [15:0] DataOutUpper,

    output TransferBusy,

    output sclk,
    output ss,
    input  miso,
    output mosi
);
    
    // Configurability Update
    // Notes:
    //  Need a configuration register
    //  r0 [3:0] - Read Padding Length - 1 [Max 16]
    //  r0 [7:4] - Write Padding Length -1 [Max 16]
    //  r0   [4] - Read Padding Enable
    //  r0   [5] - Write Padding Enable
    //  r0   [6] - Command Padding Enable [Padds 1 bit after Read/Write Command]
    //  r0   [7] - Command Polarity [If 0 - Read Command is a 0, If 1 Read Command is a 1]
    //  r0   [8] - MSB First Enable
    //  r1 [7:0] - Data Length [Max 32]
    //  r1[15:8] - Address Length [Max 32]

    always_ff @(posedge clk) begin
        if (clk_en) begin
            $display(">'> REQ:ACK:Command:DataIn       - %0b:%0b:%0h:%0h", PortREQ, PortACK, Command, DataIn);
            $display(">'> TransferBusy                 - %0b", TransferBusy);
            $display(">'> OutputCDC_dIn (REQ:Cmd:Ad:D) - %0b:%0b:%0h:%0h", SPIOutputCDC_dIn[56], SPIOutputCDC_dIn[55:54], SPIOutputCDC_dIn[53:32], SPIOutputCDC_dIn[31:0]);
            $display(">'> OutputCDC_dOut(REQ:Cmd:Ad:D) - %0b:%0b:%0h:%0h", SPIOutputCDC_dOut[56], SPIOutputCDC_dOut[55:54], SPIOutputCDC_dOut[53:32], SPIOutputCDC_dOut[31:0]);
            $display(">'> InputCDC_dIn  (ACK:Busy:D)   - %0b:%0b:%0h", SPIInputCDC_dIn[33], SPIInputCDC_dIn[32], SPIInputCDC_dIn[31:0]);
            $display(">'> InputCDC_dOut (ACK:Busy:D)   - %0b:%0b:%0h", SPIInputCDC_dOut[33], SPIInputCDC_dOut[32], SPIInputCDC_dOut[31:0]);
        end
    end

    // Configuration Register
    // Notes:
    //  r0 [3:0] - Read Padding Length - 1 [Max 16]
    //  r0 [7:4] - Write Padding Length -1 [Max 16]
    //  r0   [4] - Read Padding Enable
    //  r0   [5] - Write Padding Enable
    //  r0   [6] - Command Padding Enable [Padds 1 bit after Read/Write Command]
    //  r0   [7] - Command Polarity [If 0 - Read Command is a 0, If 1 Read Command is a 1]
    //  r0   [8] - MSB First Enable
    //  r1 [7:0] - Data Length [Max 32]
    //  r1[15:8] - Address Length [Max 32]
    // In:
    // Out:
        // Config Reg 0
        reg  [15:0] ConfigReg0;
        wire       ConfigReg0Trigger = (PortREQ && (Command == 4'b1110) && clk_en) || sync_rst;
        wire [15:0] NextConfigReg0 = (sync_rst) ? 0 : DataIn;
        always_ff @(posedge clk) begin
            if (ConfigReg0Trigger) begin
                ConfigReg0 <= NextConfigReg0;
            end
        end
        // Config Reg 1
        reg  [15:0] ConfigReg1;
        wire        ConfigReg1Trigger = (PortREQ && (Command == 4'b1111) && clk_en) || sync_rst;
        wire [15:0] NextConfigReg1 = (sync_rst) ? 0 : DataIn;
        always_ff @(posedge clk) begin
            if (ConfigReg1Trigger) begin
                ConfigReg1 <= NextConfigReg1;
            end
        end
    //

    // Conditional Handshake
    // Notes:
    //  Commands:
    //  4'b0101[5] - Initiate Read [Contains Address Lower] (Handshake through SPI Controller)
    //  4'b0110[6] - Initiate Write [Contains Address Lower] (Handshake through SPI Controller)
    //  4'b1001[9] - Load Address Upper (Instant Handshake)
    //  4'b1010[A] - Load Data Lower (Instant Handshake)
    //  4'b1011[B] - Load Data Upper (Instant Handshake)
    //  4'b1110[E] - Config Register 0
    //  4'b1111[F] - Config Register 1
    // In:
    // Out:
        // Load Response
        reg  LoadResponse;
        wire LoadResponseTrigger = clk_en || sync_rst;
        wire NextLoadResponse = Command[3] && PortREQ && ~sync_rst;
        always_ff @(posedge clk) begin
            if (LoadResponseTrigger) begin
                LoadResponse <= NextLoadResponse;
            end
        end
        assign PortACK = LoadResponse || SPITransferACK;
    //

    // Build Transaction
    // Notes:
    // In:
    // Out:
        // Address Upper
        reg  [15:0] AddressUpper;
        wire       AddressUpperTrigger = (PortREQ && (Command == 4'b1001) && clk_en) || sync_rst;
        wire [15:0] NextAddressUpper = (sync_rst) ? 0 : DataIn;
        always_ff @(posedge clk) begin
            if (AddressUpperTrigger) begin
                AddressUpper <= NextAddressUpper;
            end
        end
        // Data Lower
        reg  [15:0] DataLower;
        wire        DataLowerTrigger = (PortREQ && (Command == 4'b1010) && clk_en) || sync_rst;
        wire [15:0] NextDataLower = (sync_rst) ? 0 : DataIn;
        always_ff @(posedge clk) begin
            if (DataLowerTrigger) begin
                DataLower <= NextDataLower;
            end
        end
        // Data Upper
        reg  [15:0] DataUpper;
        wire        DataUpperTrigger = (PortREQ && (Command == 4'b1011) && clk_en) || sync_rst;
        wire [15:0] NextDataUpper = (sync_rst) ? 0 : DataIn;
        always_ff @(posedge clk) begin
            if (DataUpperTrigger) begin
                DataUpper <= NextDataUpper;
            end
        end
    //

    wire        LocalSPITransferACK;
    wire [31:0] LocalSPIDataOut;
    wire        LocalBusy;
    SPIController_Advanced #(
        .READPADDINGBYTES(3)
    ) SPI_Controller (
        .clk25         (clk_25),
        .clk_en        (clk_en_25),
        .sync_rst      (sync_rst_25),
        .SPITransferREQ(LocalSPITransferREQ),
        .SPITransferACK(LocalSPITransferACK),
        .Config        (LocalSPIConfigIn),
        .Command       (LocalSPICommandIn),
        .AddressIn     (LocalSPIAddressIn),
        .DataIn        (LocalSPIDataIn),
        .DataOut       (LocalSPIDataOut),
        .TransferBusy  (LocalBusy),
        .sclk          (sclk),
        .ss            (ss),
        .miso          (miso),
        .mosi          (mosi)
    );
    // Output CDC (Sys to SPI) for Write and Read Commands
    wire        SPITransferREQ = PortREQ && Command[2];
    wire [31:0] SPIConfigIn = {ConfigReg1, ConfigReg0};
    wire [31:0] SPIAddressIn = {AddressUpper, DataIn};
    wire [31:0] SPIDataIn = {DataUpper, DataLower};
    wire [98:0] SPIOutputCDC_dIn = {SPITransferREQ, SPIConfigIn, Command[1:0], SPIAddressIn, SPIDataIn};
    wire [98:0] SPIOutputCDC_dOut;
    wire        LocalSPITransferREQ = SPIOutputCDC_dOut[98];
    wire [31:0] LocalSPIConfigIn = SPIOutputCDC_dOut[97:66];
    wire [1:0]  LocalSPICommandIn = SPIOutputCDC_dOut[65:64];
    wire [21:0] LocalSPIAddressIn = SPIOutputCDC_dOut[63:32];
    wire [31:0] LocalSPIDataIn = SPIOutputCDC_dOut[31:0];
    FIFO_ClockDomainCrosser #(
        .BITWIDTH(99),
        .DEPTH   (8),
        .TESTENABLE(0)
    ) SPIOutputCDC (
        .rst    (async_rst),
        .w_clk  (clk),
        .dInACK (SPITransferREQ),
        .dInREQ (), // Do Not Connect
        .dIN    (SPIOutputCDC_dIn),
        .r_clk  (clk_25),
        .dOutACK(), // Do Not Connect
        .dOutREQ(clk_en_25),
        .dOUT   (SPIOutputCDC_dOut)
    );
    // Input CDC (SPI to Sys) for Command Response and Result
    wire [33:0] SPIInputCDC_dIn = {LocalSPITransferACK, LocalBusy, LocalSPIDataOut};
    wire [33:0] SPIInputCDC_dOut;
    wire SPITransferACK = SPIInputCDC_dOut[33];
    wire Busy = SPIInputCDC_dOut[32];
    wire [31:0] SPIDataOut = SPIInputCDC_dOut[31:0];
    FIFO_ClockDomainCrosser #(
        .BITWIDTH(34),
        .DEPTH   (8),
        .TESTENABLE(0)
    ) SPIInputCDC (
        .rst    (async_rst),
        .w_clk  (clk_25),
        .dInACK (LocalSPITransferACK),
        .dInREQ (), // Do Not Connect
        .dIN    (SPIInputCDC_dIn),
        .r_clk  (clk),
        .dOutACK(), // Do Not Connect
        .dOutREQ(clk_en),
        .dOUT   (SPIInputCDC_dOut)
    );

    reg  BusyDelay;
    wire BusyDelayTrigger = clk_en || sync_rst;
    wire NextBusyDelay = Busy && ~sync_rst;
    always_ff @(posedge clk) begin
        if (BusyDelayTrigger) begin
            BusyDelay <= NextBusyDelay;
        end
    end
    // assign TransferBusy = BusyDelay || Busy;
    assign TransferBusy = LocalBusy;

    reg  [31:0] SPIResultBuffer;
    wire        SPIResultBufferTrigger = (SPITransferACK && clk_en) || sync_rst;
    wire [31:0] NextSPIResultBuffer = (sync_rst) ? 0 : SPIDataOut;
    always_ff @(posedge clk) begin
        if (SPIResultBufferTrigger) begin
            SPIResultBuffer <= NextSPIResultBuffer;
        end
    end
    assign DataOutLower = SPIResultBuffer[15:0];
    assign DataOutUpper = SPIResultBuffer[31:0];



endmodule