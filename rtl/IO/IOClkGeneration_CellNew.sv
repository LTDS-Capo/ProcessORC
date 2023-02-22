module IOClkGeneration_CellNew #(
    parameter DATABITWIDTH = 16
)(
    input sys_clk,
    input clk_en,
    input sync_rst,
    // input async_rst,

    input src_clk, // Whatever the fastest clock on the system is

    input                     ConfigACK,
    output                    ConfigREQ,
    input                     LoadEn,
    input               [3:0] MinorOpcodeIn,
    input  [DATABITWIDTH-1:0] DataAddrIn_Offest,
    input              [15:0] ConfigWordIn,
    input               [3:0] ConfigRegDestIn,

    output                    ResponseACK,
    input                     ResponseREQ,
    output              [3:0] ResponseRegDestOut,
    output [DATABITWIDTH-1:0] ResponseDataOut,

    output                    divided_clk,
    output              [1:0] divided_clk_sel
);

    // Command Active Reg
        reg  Active;
        wire ActiveTrigger = (ConfigACK && ConfigREQ && ~LoadEn) || (ConfigACK && LocalConfigREQ && ~LoadEn && clk_en) || sync_rst;
        wire NextActive = ~Active && ~sync_rst;
        always_ff @(posedge sys_clk) begin
            if (ActiveTrigger) begin
                Active <= NextActive;
            end
        end
        assign ConfigREQ = LoadEn ? ResponseREQ : (LocalConfigREQ && Active);
        assign ResponseACK = ConfigACK && LoadEn;
    //

    // Config Register - sys_clk
        reg  [15:0] ConfigRegister;
        wire        ConfigRegisterTrigger = (ConfigACK && ConfigREQ && ~LoadEn && clk_en) || sync_rst;
        wire [15:0] NextConfigRegister = (sync_rst) ? 0 : ConfigWordIn;
        always_ff @(posedge sys_clk) begin
            if (ConfigRegisterTrigger) begin
                ConfigRegister <= NextConfigRegister;
            end
        end

        wire [DATABITWIDTH-1:0] LoadAlignmentInput = {'0, ConfigRegister};
        wire [DATABITWIDTH-1:0] ResponseDataOut_Tmp;
        localparam PORTBYTEWIDTH = 2;
        IOLoadDataAlignment #(
            .DATABITWIDTH(DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH)
        ) LoadAlignment (
            .MinorOpcodeIn(MinorOpcodeIn),
            .DataAddrIn   (DataAddrIn_Offest),
            .DataIn       (LoadAlignmentInput),
            .DataOut      (ResponseDataOut_Tmp)
        );

        assign        ResponseDataOut = ResponseDataOut_Tmp;
        assign        ResponseRegDestOut = ConfigRegDestIn;
    //


    // Config FIFO [Only updates on an UpperWrite]
        wire        LocalConfigACK = ~LoadEn && ConfigACK;
        wire        LocalConfigREQ;
        wire [15:0] CDC_dIn = ConfigRegister;
        wire [15:0] CDC_dOut;
        wire        NewConfig;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(16),
            .DEPTH   (4),
            .TESTENABLE(0)
        ) SysToTarget (
            // .rst    (async_rst),
            .rst    (sync_rst),
            .w_clk  (sys_clk),
            .dInACK (LocalConfigACK),
            .dInREQ (LocalConfigREQ),
            .dIN    (CDC_dIn),
            .r_clk  (src_clk),
            .dOutACK(NewConfig),
            .dOutREQ(clk_en),
            .dOUT   (CDC_dOut)
        );
    //

    // Config Register - src_clk
        reg  [15:0] DividedClkConfig;
        wire        DividedClkConfigTrigger = (NewConfig && clk_en) || sync_rst;
        wire [15:0] NextDividedClkConfig = (sync_rst) ? 0 : CDC_dOut;
        always_ff @(posedge src_clk) begin
            if (DividedClkConfigTrigger) begin
                DividedClkConfig <= NextDividedClkConfig;
            end
        end
        wire [12:0] ClockDivisor_PreScaled = DividedClkConfig[12:0];
        wire  [2:0] ClockScale = DividedClkConfig[15:13];
        wire [19:0] ClockDivisor_Scaled = {'0, ClockDivisor_PreScaled} << {'0, ClockScale};
    //

    // clk division counter
        reg  [20:0] DivisionCounter;
        wire        DivisorElapsed = DivisionCounter == ClockDivisor_Scaled;
        wire        DivisionCounterTrigger = clk_en || sync_rst;
        wire [20:0] NextDivisionCounter = (sync_rst || DivisorElapsed) ? 0 : (DivisionCounter + 1);
        always_ff @(posedge src_clk) begin
            if (DivisionCounterTrigger) begin
                DivisionCounter <= NextDivisionCounter;
            end
        end
    //

    // divided_clk Flip-Flop and Output Assignment
        reg  clkFF;
        wire clkFFTrigger = (DivisorElapsed && clk_en) || sync_rst;
        wire NextclkFF = ~clkFF && ~sync_rst;
        always_ff @(posedge src_clk) begin
            if (clkFFTrigger) begin
                clkFF <= NextclkFF;
            end
        end
        assign divided_clk = clkFF;
        assign divided_clk_sel = '0;
    //

endmodule