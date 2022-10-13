module HandshakeMux #(
    parameter DATABITWIDTH = 16,
    parameter INPUTPORTCOUNT = 4,
    parameter PORTADDRWIDTH = 2,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    output [INPUTPORTCOUNT-1:0]                       InputREQ,
    input  [INPUTPORTCOUNT-1:0]                       InputACK,
    input  [INPUTPORTCOUNT-1:0]    [DATABITWIDTH-1:0] InputData,
    input  [INPUTPORTCOUNT-1:0] [REGADDRBITWIDTH-1:0] InputAddr,

    output                       OutputACK,
    input                        OutputREQ,
    output    [DATABITWIDTH-1:0] OutputData,
    output [REGADDRBITWIDTH-1:0] OutputAddr
);

    wire  [PORTADDRWIDTH-1:0] PortSelection;
    wire RoundRobinEnable = clk_en && OutputACK && OutputREQ;
    RoundRobin #(
        .PORTCOUNT    (INPUTPORTCOUNT),
        .PORTADDRWIDTH(PORTADDRWIDTH)
    ) RRPortPriority (
        .clk          (clk),
        .clk_en       (RoundRobinEnable),
        .sync_rst     (sync_rst),
        .PortACKVector(InputACK),
        .PortSelection(PortSelection)
    );

    logic [INPUTPORTCOUNT-1:0] RequestMask;
    always_comb begin : RequestMaskGen
        RequestMask = 0;
        RequestMask[PortSelection] = 1'b1;
    end

    wire [INPUTPORTCOUNT-1:0] OutputREQ_tmp;
    genvar REQIndex;
    generate
        for (REQIndex = 0; REQIndex < INPUTPORTCOUNT; REQIndex = REQIndex + 1) begin : OutputREQExpansion
            assign OutputREQ_tmp[REQIndex] = OutputREQ;
        end
    endgenerate

    assign InputREQ = OutputREQ_tmp & RequestMask;
    assign OutputACK = |(InputACK & RequestMask);
    assign OutputData = InputData[PortSelection];
    assign OutputAddr = InputAddr[PortSelection];

endmodule