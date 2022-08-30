module IOManager #(
    parameter IOBASEADDR = 384,
    parameter TOTALIOBYTES = 128,
// $PARAMETERS$
    parameter TOTALIOPORTS = 8,
// $ENDPARAMETERS$
)(
    input sys_clk,
    input clk_en,
    input sync_rst,
    input async_rst,

    input src_clk0,
    input src_clk1,
    input src_clk2,

    input                     CommandACK,
    output                    CommandREQ,
    input               [3:0] MinorOpcodeIn,
    input  [DATABITWIDTH-1:0] CommandAddressIn_Offest,
    input  [DATABITWIDTH-1:0] CommandDataIn,
    input               [3:0] CommandDestReg,

    output                    WritebackACK,
    input                     WritebackREQ,
    output              [3:0] WritebackDestReg,
    output [DATABITWIDTH-1:0] WritebackDataOut,

// $IO$ // Have a different set for each Port
    output       IO_xxxx_Clk,
    input        IO_xxxx_ACK,
    output       IO_xxxx_REQ,
    output       IO_xxxx_CommandEn,
    output       IO_xxxx_ResponseRequested,
    input        IO_xxxx_CommandResponse,
    input        IO_xxxx_RegResponseFlag, // Force a Writeback handshake after updating local buffer
    input        IO_xxxx_MemResponseFlag, // Only update local buffer
    input  [3:0] IO_xxxx_DestRegIn,
    output [3:0] IO_xxxx_DestRegOut,
    input  [#:0] IO_xxxx_DataIn,
    output [#:0] IO_xxxx_DataOut,
// $ENDIO$
);

    wire LoadEn = ~MinorOpcodeIn[2] && MinorOpcodeIn[3];
    wire StoreEn = MinorOpcodeIn[2];

// Clocks


//

// Timers
    wire        TimerInACK;
    wire        TimerInREQ;
    wire        TimerOutACK;
    wire        TimerOutREQ;
    wire [15:0] TimerDataOut;
    wire  [3:0] RegisterDestOut;
    FBI_Timers #(
        .DATABITWIDTH(16)
    ) SystemTimers (
        .clk            (sys_clk),
        .clk_en         (clk_en),
        .sync_rst       (sync_rst),
        .IOInACK        (),
        .IOInREQ        (),
        .RegisterDestIn (CommandDestReg),
        .LoadEnIn       (LoadEn),
        .StoreEnIn      (StoreEn),
        .WordEn         (),
        .DataIn         (),
        .TimerOutACK    (),
        .TimerOutREQ    (),
        .TimerDataOut   (),
        .RegisterDestOut()
    );

//

// IO Interfaces
    // $GEN$ CaseGen([8:Addr, 4:Output], CaseConfig.txt)
        // Input Handshake Demux


        //
        // Output Handshake Demux


        //
    // $GENEND$
//


endmodule