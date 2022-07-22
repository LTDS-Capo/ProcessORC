module MemWritebackMuxTagged #(
    parameter DATABITWIDTH = 16,
    parameter TAGBITWIDTH = 6,
    // parameter INPUTPORTCOUNT = 4,
    // parameter PORTADDRWIDTH = 2,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    //output                       MemWritebackREQ    [INPUTPORTCOUNT-1:0],
    //input                        MemWritebackACK    [INPUTPORTCOUNT-1:0],
    //input     [DATABITWIDTH-1:0] MemWritebackDataIn [INPUTPORTCOUNT-1:0],
    //input      [TAGBITWIDTH-1:0] MemWritebackTagIn  [INPUTPORTCOUNT-1:0],
    //input  [REGADDRBITWIDTH-1:0] MemWritebackAddrIn [INPUTPORTCOUNT-1:0],

    output                       ComplexALUREQ,
    input                        ComplexALUACK,
    input     [DATABITWIDTH-1:0] ComplexALUDataIn,
    input      [TAGBITWIDTH-1:0] ComplexALUTagIn,
    input  [REGADDRBITWIDTH-1:0] ComplexALUAddrIn,

    output                       CacheHitREQ,
    input                        CacheHitACK,
    input     [DATABITWIDTH-1:0] CacheHitDataIn,
    input      [TAGBITWIDTH-1:0] CacheHitTagIn,
    input  [REGADDRBITWIDTH-1:0] CacheHitAddrIn,

    output                       CacheMissREQ,
    input                        CacheMissACK,
    input     [DATABITWIDTH-1:0] CacheMissDataIn,
    input      [TAGBITWIDTH-1:0] CacheMissTagIn,
    input  [REGADDRBITWIDTH-1:0] CacheMissAddrIn,

    output                       MemMapIOREQ,
    input                        MemMapIOACK,
    input     [DATABITWIDTH-1:0] MemMapIODataIn,
    input      [TAGBITWIDTH-1:0] MemMapIOTagIn,
    input  [REGADDRBITWIDTH-1:0] MemMapIOAddrIn,

    output                       RegWriteEn,
    output    [DATABITWIDTH-1:0] RegWriteData,
    output [REGADDRBITWIDTH-1:0] RegWriteAddr
);

    // Tag Comparison
    wire                   ComplexALU_CacheHit_Select;
    wire                   ComplexALU_CacheHit_Valid;
    wire [TAGBITWIDTH-1:0] ComplexALU_CacheHit_Tag;
    TagComparisonUnit #(
        .TAGBITWIDTH(TAGBITWIDTH)
    ) ComplexALU_CacheHitComparison (
        .AValid       (ComplexALUACK),
        .ATag         (ComplexALUTagIn),
        .BValid       (CacheHitACK),
        .BTag         (CacheHitTagIn),
        .SelectedValue(ComplexALU_CacheHit_Select),
        .OutValid     (ComplexALU_CacheHit_Valid),
        .OutTag       (ComplexALU_CacheHit_Tag)
    );

    wire                   CacheMiss_MemMapIO_Select;
    wire                   CacheMiss_MemMapIO_Valid;
    wire [TAGBITWIDTH-1:0] CacheMiss_MemMapIO_Tag;
    TagComparisonUnit #(
        .TAGBITWIDTH(TAGBITWIDTH)
    ) CacheMiss_MemMapIOComparison (
        .AValid       (CacheMissACK),
        .ATag         (CacheMissTagIn),
        .BValid       (MemMapIOACK),
        .BTag         (MemMapIOTagIn),
        .SelectedValue(CacheMiss_MemMapIO_Select),
        .OutValid     (CacheMiss_MemMapIO_Valid),
        .OutTag       (CacheMiss_MemMapIO_Tag)
    );

    wire                   ALUHit_MissIO_Select;
    wire                   ALUHit_MissIO_Valid;
    wire [TAGBITWIDTH-1:0] ALUHit_MissIO_Tag;
    TagComparisonUnit #(
        .TAGBITWIDTH(TAGBITWIDTH)
    ) ALUHit_MissIOComparison (
        .AValid       (ComplexALU_CacheHit_Valid),
        .ATag         (ComplexALU_CacheHit_Tag),
        .BValid       (CacheMiss_MemMapIO_Valid),
        .BTag         (CacheMiss_MemMapIO_Tag),
        .SelectedValue(ALUHit_MissIO_Select),
        .OutValid     (ALUHit_MissIO_Valid),
        .OutTag       (ALUHit_MissIO_Tag)
    );

    wire LowestBitLSB = ALUHit_MissIO_Select ? CacheMiss_MemMapIO_Select : ComplexALU_CacheHit_Select;
    wire [1:0] LowestTag = {ALUHit_MissIO_Select, LowestBitLSB};

    // Output Mux
            localparam OUTPUTMUXBITWIDTH = DATABITWIDTH + REGADDRBITWIDTH;
            logic [OUTPUTMUXBITWIDTH-1:0] Output_Tmp;
            always_comb begin : OutputMux
                case (LowestTag)
                    2'b01  : Output_Tmp = {CacheHitAddrIn, CacheHitDataIn};
                    2'b10  : Output_Tmp = {CacheMissAddrIn, CacheMissDataIn};
                    2'b11  : Output_Tmp = {MemMapIOAddrIn, MemMapIODataIn};
                    default: Output_Tmp = {ComplexALUAddrIn, ComplexALUDataIn}; // Default is also case 0
                endcase
            end
    //

    logic [3:0] REQVector;
    always_comb begin : REQDemux
        REQVector = 0;
        REQVector[LowestTag] = ALUHit_MissIO_Valid;
    end

    // Output Assignments [Make this a buffer]
        assign ComplexALUREQ = REQVector[0];
        assign CacheHitREQ = REQVector[1];
        assign CacheMissREQ = REQVector[2];
        assign MemMapIOREQ = REQVector[3];

        // Output Buffer
        wire                       RegWriteEn_Tmp = ALUHit_MissIO_Valid;
        wire [REGADDRBITWIDTH-1:0] RegWriteAddr_Tmp = Output_Tmp[OUTPUTMUXBITWIDTH-1:DATABITWIDTH];
        wire    [DATABITWIDTH-1:0] RegWriteData_Tmp = Output_Tmp[DATABITWIDTH-1:0];
    
        localparam OUTPUTBUFFERBITWIDTH = DATABITWIDTH + REGADDRBITWIDTH + 1;
        reg  [OUTPUTBUFFERBITWIDTH-1:0] OutputBuffer;
        wire      OutputBufferTrigger = clk_en || sync_rst;
        wire [OUTPUTBUFFERBITWIDTH-1:0] NextOutputBuffer = (sync_rst) ? 0 : {RegWriteEn_Tmp, RegWriteAddr_Tmp, RegWriteData_Tmp};
        always_ff @(posedge clk) begin
            if (OutputBufferTrigger) begin
                OutputBuffer <= NextOutputBuffer;
            end
        end
        assign RegWriteEn = OutputBuffer[OUTPUTBUFFERBITWIDTH-1];
        assign RegWriteAddr = OutputBuffer[OUTPUTBUFFERBITWIDTH-2:DATABITWIDTH];
        assign RegWriteData = OutputBuffer[DATABITWIDTH-1:0];

    //



endmodule