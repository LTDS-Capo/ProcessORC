module IOClkGeneration_Cell (
    input sys_clk,
    input clk_en,
    input sync_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input         ConfigWriteEnUpper,
    input         ConfigWriteEnLower,
    input  [15:0] ConfigInput,
    output [15:0] ConfigOutput,

    output        divided_clk,
    output  [1:0] divided_clk_sel
);

    // Config Register - sys_clk
    // >  [13:0] - clk division
    // > [15:16] - clk source
        reg  [7:0] ConfigUpperRegister;
        wire       ConfigUpperRegisterTrigger = (ConfigWriteEnUpper && clk_en) || sync_rst;
        wire [7:0] NextConfigUpperRegister = (sync_rst) ? 0 : ConfigInput[15:0];
        always_ff @(posedge sys_clk) begin
            if (ConfigUpperRegisterTrigger) begin
                ConfigUpperRegister <= NextConfigUpperRegister;
            end
        end
        reg  [7:0] ConfigLowerRegister;
        wire       ConfigLowerRegisterTrigger = (ConfigWriteEnLower && clk_en) || sync_rst;
        wire [7:0] NextConfigLowerRegister = (sync_rst) ? 0 : ConfigInput[7:0];
        always_ff @(posedge sys_clk) begin
            if (ConfigLowerRegisterTrigger) begin
                ConfigLowerRegister <= NextConfigLowerRegister;
            end
        end
        wire [13:0] ClockDivisor_sys = {ConfigUpperRegister[5:0], ConfigLowerRegister};
        wire  [1:0] ClockSelect_sys = ConfigUpperRegister[7:6];
        assign      ConfigOutput = {ConfigUpperRegister, ConfigUpperRegister};
    //

    // Configuration Submit Delay
        reg  [1:0] ConfigSubmitDelay;
        wire ConfigSubmitDelayTrigger = clk_en || sync_rst;
        wire NextConfigSubmitDelay = ConfigUpperRegisterTrigger && ~sync_rst;
        always_ff @(posedge sys_clk) begin
            if (ConfigSubmitDelayTrigger) begin
                ConfigSubmitDelay[0] <= NextConfigSubmitDelay;
                ConfigSubmitDelay[1] <= ConfigSubmitDelay[0] && ~sync_rst;
            end
        end
        wire ConfigSubmit = ConfigSubmitDelay[1];
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
        wire [15:0] CDC_dIn = ConfigOutput;
        wire [15:0] CDC_dOut;
        wire        NewConfig;
        FIFO_ClockDomainCrosser #(
            .BITWIDTH(16),
            .DEPTH   (4),
            .TESTENABLE(0)
        ) SysToTarget (
            .rst    (async_rst),
            .w_clk  (sys_clk),
            .dInACK (ConfigSubmit),
            .dInREQ (), // Do Not Connect
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