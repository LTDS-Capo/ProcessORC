module SPIController_Advanced #(
    parameter READPADDINGBYTES = 3
)(
    input clk25,
    input clk_en,
    input sync_rst,
    
    input  SPITransferREQ,
    output SPITransferACK,
    input  [31:0] Config,
    input   [1:0] Command,
    input  [31:0] AddressIn,
    input  [31:0] DataIn,
    output [31:0] DataOut,

    output TransferBusy,

    output sclk,
    output ss,
    input  miso,
    output mosi
);
    

    always_ff @(posedge clk25) begin 
        $display("<.^.>State:NextState:Trigger   - %0h:%0h:%0b", State, NextState, StateTrigger);
        $display("<.^.>Count:Next:Compare             - %0dd(%0hh):%0dd(%0hh):%0dd(%0hh)", Count, Count, NextCount, NextCount, CountCompare, CountCompare);
        $display("<.^.>Data:Address:Config:Cmd   - %0h:%0h:%0bb(%0hh):%0h", DataRegister, AddressRegister, ConfigReg, ConfigReg, CurrentCommand);
        $display("<.^.>Length(Input) - Addr:Data - %0h:%0h:%0h:%0h", AddressLength, Config[28:24], DataLength, Config[20:16]);  
        $display("<.^.>RxBuffer - %0h" ,RxBuffer);
    end
    
    // State Tracking
    // Notes:
    // In:
    // Out:
        // Current Command
        reg  [1:0] CurrentCommand;
        wire       CurrentCommandTrigger = (SPITransferREQ && clk_en) || sync_rst;
        wire [1:0] NextCurrentCommand = (sync_rst) ? 0 : Command;
        always_ff @(posedge clk25) begin
            if (CurrentCommandTrigger) begin
                CurrentCommand <= NextCurrentCommand;
            end
        end
        
        
        // Current Configuration Register
            // Notes:
            // Configuration Input
            //   Mem Map -   Local
            //  r0 [3:0] -   [3:0] - Read Padding Length [Max 15]
            //  r0 [7:4] -   [7:4] - Write Padding Length [Max 15]
            //  r0   [8] -     [8] - Read Padding Enable
            //  r0   [9] -     [9] - Write Padding Enable
            //  r0  [10] -    [10] - Command Padding Enable [Padds 1 bit of X after Read/Write Command]
            //  r0  [11] -    [11] - Command Polarity [If 0 - Read Command is a 0, If 1 Read Command is a 1]
            //  r0  [12] -    [12] - MSB First Enable
            // TODO:
            //  r0  [13] -    [13] - Chip Select
            //  r0  [14] -    [14] - Clock Select b0
            //  r0  [15] -    [15] - Clock Select b1
            //  r0  [16] -    [16] - Clock Select b2
            // TODO:
            //  r1 [7:0] - [23:16] - Data Length - 1 [Max Length 32]
            //  r1[15:8] - [31:24] - Address Length - 1 [Max Length 32]
            // Configuration Register
            //     [3:0] - Read Padding Length - 1 [Max 16]
            //     [7:4] - Write Padding Length -1 [Max 16]
            //       [8] - Read Padding Enable
            //       [9] - Write Padding Enable
            //      [10] - Command Padding Enable
            //      [11] - Command Polarity [If 0 - Read Command is a 0, If 1 Read Command is a 1]
            //      [12] - MSB First Enable
            //   [17:13] - Data Length
            //   [22:18] - Address Length
        //

        // Base Length Generation
        wire [4:0] AddressLength = (Config[31:24] > 8'h1E) ? 5'h1F : Config[28:24]; // Limit Address size to 32bits
        wire [4:0] DataLength = (Config[23:16] > 8'h1E) ? 5'h1F : Config[20:16];    // Limit Data size to 32bits
        // Config Register
        reg  [22:0] ConfigReg;
        wire       ConfigRegTrigger = (SPITransferREQ && clk_en) || sync_rst;
        wire [22:0] NextConfigReg = (sync_rst) ? 0 : {AddressLength[4:0], DataLength[4:0], Config[12:0]}; 
        always_ff @(posedge clk25) begin
            if (ConfigRegTrigger) begin
                ConfigReg <= NextConfigReg;
            end
        end

        // Address Register
        reg  [31:0] AddressRegister;
        wire        AddressRegisterTrigger = (SPITransferREQ && clk_en) || sync_rst;
        wire [31:0] NextAddressRegister = (sync_rst) ? 0 : AddressIn;
        always_ff @(posedge clk25) begin
            if (AddressRegisterTrigger) begin
                AddressRegister <= NextAddressRegister;
            end
        end
        // Write Data Register
        reg  [31:0] DataRegister;
        wire        DataRegisterTrigger = (SPITransferREQ && clk_en) || sync_rst;
        wire [31:0] NextDataRegister = (sync_rst) ? 0 : DataIn;
        always_ff @(posedge clk25) begin
            if (DataRegisterTrigger) begin
                DataRegister <= NextDataRegister;
            end
        end


        // States
        //      Command          - Init
        //      Command Padd     - Init Delay
        //      Address Indexing - 4'b1000
        //      Delay            - 4'b1001
        //      Data Indexing    - 4'b1010
        //      Complete         - 4'b1100


        reg  [1:0] InitDelay;
        wire       InitDelayTrigger = clk_en || sync_rst;
        wire [1:0] NextInitDelay;
        assign  NextInitDelay[0] = SPITransferREQ && ~sync_rst;
        assign  NextInitDelay[1] = (InitDelay[0] && ConfigReg[10] && ~sync_rst);
        always_ff @(posedge clk25) begin
            if (InitDelayTrigger) begin
                InitDelay <= NextInitDelay;
            end
        end
        wire        TransferInit = (InitDelay[1] &&  ConfigReg[10]) || (InitDelay[0] && ~ConfigReg[10]);
        reg   [3:0] State;
        wire        StateTrigger = (CountMatch && State[3] && ~State[2] && clk_en) || (TransferInit && clk_en) || sync_rst;
        logic [3:0] NextState;
        wire  [1:0] NextStateCondition;
        wire        DataPaddingEnable = (ConfigReg[9] && CurrentCommand[1] && (State == 4'b1000)) || (ConfigReg[8] && CurrentCommand[0] && (State == 4'b1000));
        assign NextStateCondition[0] = (TransferInit || DataPaddingEnable) && ~sync_rst;
        assign NextStateCondition[1] = (~DataPaddingEnable || TransferInit) && ~sync_rst;
        always_comb begin : NextRegMux
            case (NextStateCondition)
                2'b01  : NextState = State + 1;
                2'b10  : NextState = State + 2;
                2'b11  : NextState = 4'b1000;
                default: NextState = 0; // Default is also case 0
            endcase
        end
        always_ff @(posedge clk25) begin
            if (StateTrigger) begin
                State <= NextState;
            end
        end
        
        // BitCounter
        reg  [7:0] Count;
        wire       CountTrigger = (StateTrigger && clk_en) || (State[3] && ~State[2] && clk_en) || sync_rst;
        wire [7:0] NextCount = (sync_rst || StateTrigger) ? 0 : (Count + 1);
        always_ff @(negedge clk25) begin
            if (CountTrigger) begin
                Count <= NextCount;
            end
        end
        logic [7:0] CountCompare;
        wire  [2:0] CountCompareCondition = {CurrentCommand[0], State[1:0]};
        always_comb begin : CountComparisonMux
            casex (CountCompareCondition)
                3'b001 : CountCompare = {1'b0, ConfigReg[7:4], 3'b0}; 
                3'bx10 : CountCompare = {2'b0, ConfigReg[17:13]}; // Data
                3'b101 : CountCompare = {1'b0, ConfigReg[3:0], 3'b0}; 
                default: CountCompare = {2'b0, ConfigReg[22:18]}; // Address
            endcase
        end
        wire CountMatch = CountCompare == Count;

        // TxBuffer - Buffer data for IO timing... Count will be 1 off for Rx Buffer with this buffer in place.
        reg        TxBuffer;
        wire       TxBufferTrigger = clk_en || sync_rst;
        wire [4:0] AddressIndex = ConfigReg[12] ? (ConfigReg[22:18] - Count) : Count;
        wire [4:0] DataIndex = ConfigReg[12] ? (ConfigReg[17:13] - Count) : Count;
        logic      NextTxValue;
        wire [3:0] NextTxCondition = {InitDelay, State[1:0]};
        always_comb begin : NextTxBitSelection
            casez (NextTxCondition)
                4'b0001: NextTxValue = 1'bx; // Data Delay Delay
                4'b0010: NextTxValue = CurrentCommand[0] ? 1'bx : DataRegister[DataIndex]; // Data
                4'b01xx: NextTxValue = CurrentCommand[1] ^ ConfigReg[11]; // Command
                4'b10xx: NextTxValue = 1'bx; // Command Padding
                default: NextTxValue = AddressRegister[AddressIndex]; // Address
            endcase
        end
        wire NextTxBuffer = NextTxValue;
        always_ff @(posedge clk25) begin
            if (TxBufferTrigger) begin
                TxBuffer <= NextTxBuffer;
            end
        end
        // RxBuffer
        reg  [31:0] RxBuffer;
        wire        RxBufferTrigger = ((State == 4'b1010) && clk_en);
        wire        NextRxBuffer = miso;
        always_ff @(posedge clk25) begin
            if (RxBufferTrigger) begin
                RxBuffer[DataIndex] <= NextRxBuffer;
            end
        end
        // SPI Output Assignments
        reg  AckBuffer;
        wire AckBufferTrigger = clk_en || sync_rst;
        wire NextAckBuffer = (State == 4'b1010) && StateTrigger && ~sync_rst;
        always_ff @(posedge clk25) begin
            if (AckBufferTrigger) begin
                AckBuffer <= NextAckBuffer;
            end
        end

        
        assign SPITransferACK = AckBuffer;
        assign DataOut = SPITransferACK ? RxBuffer : 0;
        assign sclk = clk25;
        assign ss = ~mosiEn;
        wire   mosiEn = (State[3] && ~State[2]) || InitDelay[1] || InitDelay[0];
        assign mosi = mosiEn ? TxBuffer : 1'bx;
    // 

endmodule