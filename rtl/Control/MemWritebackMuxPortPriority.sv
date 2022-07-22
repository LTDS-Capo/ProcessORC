module MemWritebackMux #(
    parameter DATABITWIDTH = 16,
    parameter INPUTPORTCOUNT = 4,
    parameter PORTADDRWIDTH = 2,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    output                       MemWritebackREQ    [INPUTPORTCOUNT-1:0],
    input                        MemWritebackACK    [INPUTPORTCOUNT-1:0],
    input     [DATABITWIDTH-1:0] MemWritebackDataIn [INPUTPORTCOUNT-1:0],
    input  [REGADDRBITWIDTH-1:0] MemWritebackAddrIn [INPUTPORTCOUNT-1:0],

    output                       RegWriteEn,
    output    [DATABITWIDTH-1:0] RegWriteData,
    output [REGADDRBITWIDTH-1:0] RegWriteAddr
);



endmodule