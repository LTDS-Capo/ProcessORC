module Quartus_TopLevel (
    input PLL_refclk,
    input async_rst,

    input   [7:0] GPIO_DIn,
    output  [7:0] GPIO_DOut,
    output  [7:0] GPIO_DOutEn,

    output CPU_Halted
);
    
    wire sys_clk;
    wire src_clk0;
    wire src_clk1;
    wire src_clk2;
    wire clk_en;

    //replace timers with fixed speed clock for timers

    PLL ClockGeneration (
        .refclk  (PLL_refclk),  
        .rst     (~async_rst),     
        .outclk_0(sys_clk),  // 50mhz (dropped to 45mhz until the pipeline is optimized)
        .outclk_1(src_clk0), // 25mhz
        .outclk_2(src_clk1), // 10mhz
        .outclk_3(src_clk2), // 2p5mhz
        .locked  (clk_en) 
    );

    PlatformIndependent_Test #(
        .DATABITWIDTH(16)
    ) PlatformIndependent (
        .sys_clk    (sys_clk),
        .clk_en     (clk_en),
        .async_rst  (~async_rst),
        .src_clk0   (src_clk0),
        .src_clk1   (src_clk1),
        .src_clk2   (src_clk2),
        .GPIO_DIn   (GPIO_DIn),
        .GPIO_DOut  (GPIO_DOut),
        .GPIO_DOutEn(GPIO_DOutEn),
        .CPU_Halted (CPU_Halted),
    );


endmodule