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

    wire [INPUTPORTCOUNT-1:0] PortACKVector = MemWritebackACK;
    wire  [PORTADDRWIDTH-1:0] PortSelection;
    RoundRobinPortPriority #(
        .PORTCOUNT    (INPUTPORTCOUNT),
        .PORTADDRWIDTH(PORTADDRWIDTH),
    ) RRPortPriority (
        .clk          (clk),
        .clk_en       (clk_en),
        .sync_rst     (sync_rst),
        .PortACKVector(MemWritebackACK),
        .PortSelection(PortSelection)
    );

    logic [INPUTPORTCOUNT-1:0] RequestMask;
    always_comb begin : RequestMaskGen
        RequestMask = 0;
        RequestMask[PortSelection] = 1'b1;
    end

    assign MemWritebackREQ = MemWritebackACK & RequestMask;
    assign RegWriteEn = |MemWritebackACK;
    assign RegWriteData = MemWritebackDataIn[PortSelection];
    assign RegWriteAddr = MemWritebackAddrIn[PortSelection];

endmodule