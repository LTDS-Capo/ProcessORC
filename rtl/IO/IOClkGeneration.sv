module IOClkGeneration #(
    parameter DATABITWIDTH = 16
)(
    input sys_clk,
    input clk_en,
    input sync_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input                          CommandACK,
    output                         CommandREQ,
    input                    [3:0] MinorOpcodeIn,
    input       [DATABITWIDTH-1:0] CommandAddressIn_Offest,
    input       [DATABITWIDTH-1:0] CommandDataIn,
    input                    [3:0] CommandDestReg,

    output [3:0]                   WritebackACK,
    input  [3:0]                   WritebackREQ,
    output [3:0]             [3:0] WritebackDestReg,
    output [3:0][DATABITWIDTH-1:0] WritebackDataOut,

    output              [7:0]      divided_clk_out,
    output              [3:0][1:0] divided_clk_sel_out
);
    
    wire LoadEn = ~MinorOpcodeIn[2];

    // Interface Manager (For stores)
        localparam PORTBYTEWIDTH = 2; // Multiple of 2s only for now
        localparam BUFFERCOUNT = ((PORTBYTEWIDTH * 8) <= DATABITWIDTH) ? 1 : ((PORTBYTEWIDTH * 8) / DATABITWIDTH);
        wire LocalCommandACK = ~LoadEn && CommandACK;
        wire LocalCommandREQ;
        wire        ClockACK;
        wire  [3:0] REQSelectArray = ConfigREQArray & StoreDecoder;
        wire        ClockREQ = |REQSelectArray;
        wire [15:0] ClockDataOut;
        wire  [3:0] MinorOpcodeOut;
        wire [15:0] DataAddrOut;
        IOCommandInterface #(
            .DATABITWIDTH (DATABITWIDTH),
            .PORTBYTEWIDTH(PORTBYTEWIDTH),
            .BUFFERCOUNT  (BUFFERCOUNT)
        ) IOInterface (
            .clk            (sys_clk),
            .clk_en         (clk_en),
            .sync_rst       (sync_rst),
            .CommandInACK   (LocalCommandACK),
            .CommandInREQ   (LocalCommandREQ),
            .MinorOpcodeIn  (MinorOpcodeIn),
            .RegisterDestIn (CommandDestReg),
            .DataAddrIn     (CommandAddressIn_Offest),
            .DataIn         (CommandDataIn),
            .CommandOutACK  (ClockACK),
            .CommandOutREQ  (ClockREQ),
            .MinorOpcodeOut (MinorOpcodeOut),
            .RegisterDestOut(), // Do Not Connect
            .DataAddrOut    (DataAddrOut),
            .DataOut        (ClockDataOut)
        );
        assign CommandREQ = LoadEn ? ConfigREQArray[LoadDecoder] : LocalCommandREQ;
    //


    // clk0: sys_clk
    // clk1: src_clk0
    // clk2: src_clk1
    // clk3: src_clk2
    // clk4: divided_clk0
    // clk5: divided_clk1
    // clk6: divided_clk2
    // clk7: divided_clk3

    // divided_clk Config bits
    // >  [13:0] - clk division
    // > [15:16] - clk source

    // Config Decoder
        logic [3:0] LoadDecoder;
        always_comb begin
            LoadDecoder = 0;
            LoadDecoder[CommandDataIn[2:1]] = 1'b1;
        end
    //

    // Config Decoder
        logic [3:0] StoreDecoder;
        always_comb begin
            StoreDecoder = 0;
            StoreDecoder[DataAddrOut[2:1]] = 1'b1;
        end
    //

    // divided_clk Deneration
        wire   [3:0] [15:0] ConfigOutputs;
        wire   [3:0]        divided_clks;
        wire   [3:0]  [1:0] ConfigSelOutputs;
        wire   [3:0]        ConfigREQArray;
        genvar ClkGen;
        generate
            for (ClkGen = 0; ClkGen < 4; ClkGen = ClkGen + 1) begin : ClkDivisionGeneration
                wire LocalConfigACK = (LoadEn && LoadDecoder[ClkGen] && CommandACK) || (~LoadEn && ClockACK && StoreDecoder[ClkGen]);
                wire LocalConfigREQ;
                wire        divided_clk;
                wire  [1:0] divided_clk_sel;
                IOClkGeneration_Cell ClkDivisionGen (
                    .sys_clk           (sys_clk),
                    .clk_en            (clk_en),
                    .sync_rst          (sync_rst),
                    .src_clk0          (src_clk0),
                    .src_clk1          (src_clk1),
                    .src_clk2          (src_clk2),
                    .ConfigACK         (LocalConfigACK),
                    .ConfigREQ         (LocalConfigREQ),
                    .LoadEn            (LoadEn),
                    .MinorOpcodeIn     (MinorOpcodeOut),
                    .DataAddrIn_Offest (DataAddrOut),
                    .ConfigWordIn      (ClockDataOut),
                    .ConfigRegDestIn   (CommandDestReg),
                    .ResponseACK       (WritebackACK[ClkGen]),
                    .ResponseREQ       (WritebackREQ[ClkGen]),
                    .ResponseDataOut   (WritebackDataOut[ClkGen]),
                    .ResponseRegDestOut(WritebackDestReg[ClkGen]),
                    .divided_clk       (divided_clk),
                    .divided_clk_sel   (divided_clk_sel)
                );
                assign ConfigREQArray[ClkGen] = LocalConfigREQ;
                assign divided_clks[ClkGen] = divided_clk;
                assign ConfigSelOutputs[ClkGen] = divided_clk_sel;
            end
        endgenerate
    //

    // divided_clk output assignment
        assign divided_clk_out = {divided_clks, src_clk2, src_clk1, src_clk0, sys_clk};
        assign divided_clk_sel_out = ConfigSelOutputs;
    //

endmodule