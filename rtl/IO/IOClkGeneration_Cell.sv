module IOClkGeneration_Cell #(
    parameter DATABITWIDTH = 16
)(
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input                     ConfigACK,
    output                    ConfigREQ,
    input                     LoadEn,
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

        wire   [13:0] ClockDivisor_sys = ConfigRegister[13:0];
        wire    [1:0] ClockSelect_sys = ConfigRegister[15:14];
        assign        ResponseDataOut = {'0, ConfigRegister};
        assign        ResponseRegDestOut = ConfigRegDestIn;
    //

    // clk Mux
        logic divided_clk_src_Tmp;
        always_comb begin : clk_mux
            case (ClockSelect_sys)
                2'b01  : divided_clk_src_Tmp = src_clk0;
                2'b10  : divided_clk_src_Tmp = src_clk1;
                2'b11  : divided_clk_src_Tmp = src_clk2;
                default: divided_clk_src_Tmp = sys_clk; // Default is also case 0
            endcase
        end
        wire divided_clk_src = divided_clk_src_Tmp;
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
            .rst    (async_rst),
            .w_clk  (sys_clk),
            .dInACK (LocalConfigACK),
            .dInREQ (LocalConfigREQ),
            .dIN    (CDC_dIn),
            .r_clk  (divided_clk_src),
            .dOutACK(NewConfig),
            .dOutREQ(clk_en),
            .dOUT   (CDC_dOut)
        );
    //

    // Config Register - divided_clk_src
        reg  [15:0] DividedClkConfig;
        wire        DividedClkConfigTrigger = (NewConfig && clk_en) || sync_rst;
        wire [15:0] NextDividedClkConfig = (sync_rst) ? 0 : CDC_dOut;
        always_ff @(posedge divided_clk_src) begin
            if (DividedClkConfigTrigger) begin
                DividedClkConfig <= NextDividedClkConfig;
            end
        end
        wire [13:0] ClockDivisor_Divided = DividedClkConfig[13:0];
        wire  [1:0] ClockSelect_Divided = DividedClkConfig[15:14];
    //

    // clk division counter
        reg  [13:0] DivisionCounter;
        wire        DivisorElapsed = DivisionCounter == ClockDivisor_Divided;
        wire        DivisionCounterTrigger = clk_en || sync_rst;
        wire [13:0] NextDivisionCounter = (sync_rst || DivisorElapsed) ? 0 : (DivisionCounter + 1);
        always_ff @(posedge divided_clk_src) begin
            if (DivisionCounterTrigger) begin
                DivisionCounter <= NextDivisionCounter;
            end
        end
    //

    // divided_clk Flip-Flop and Output Assignment
        reg  clkFF;
        wire clkFFTrigger = (DivisorElapsed && clk_en) || sync_rst;
        wire NextclkFF = ~clkFF && ~sync_rst;
        always_ff @(posedge divided_clk_src) begin
            if (clkFFTrigger) begin
                clkFF <= NextclkFF;
            end
        end
        assign divided_clk = clkFF;
        assign divided_clk_sel = ClockSelect_Divided;
    //
endmodule