`define GEN_FIFO_LSRAM_INSTANCE(instance_name) begin \
    instance_name instance_name ( \
        .CLK       (CLK), \
        .DATA      (DATA), \
        .RE        (RE), \
        .RESET_N   (RESET_N), \
        .WE        (WE), \
        .AFULL     (AFULL), \
        .DVLD      (DVLD), \
        .EMPTY     (EMPTY), \
        .FULL      (FULL), \
        .Q         (Q), \
        .WACK      (WACK), \
        .SB_CORRECT(SB_CORRECT), \
        .DB_DETECT (DB_DETECT) \
    ); \
end
`define GEN_FIFO_USRAM_INSTANCE(instance_name) begin \
    instance_name instance_name ( \
        .CLK    (CLK), \
        .DATA   (DATA), \
        .RE     (RE), \
        .RESET_N(RESET_N), \
        .WE     (WE), \
        .AFULL  (AFULL), \
        .DVLD   (DVLD), \
        .EMPTY  (EMPTY), \
        .FULL   (FULL), \
        .Q      (Q), \
        .WACK   (WACK) \
    ); \
    assign SB_CORRECT = 1'b0; \
    assign DB_DETECT = 1'b0; \
end

module handshake_fifo_libero #(
    parameter DEPTH = 1024,
    parameter WIDTH = 32
)(
    input clk,
    input clk_en,
    input sync_rst,

    input              InputREQ,
    output             InputACK,
    input  [WIDTH-1:0] InputData,

    output             OutputREQ,
    input              OutputACK,
    output [WIDTH-1:0] OutputData,
    output CorrectedECC, // Error detected and corrected.
    output DetectedECC   // Uncorrectable error detected.
);

// Define fifo connections
logic CLK, RESET_N;
logic FULL, AFULL, EMPTY;
logic WE,   RE;
logic WACK, DVLD;
// ECC flags (SB_CORRECT and DB_DETECT) will only be valid the same clock cycle as the data out.
logic SB_CORRECT, DB_DETECT;

logic [WIDTH-1:0] DATA;
logic [WIDTH-1:0] Q;

generate
    // generate with First-Word-Fall-Through & handshake signals enabled, with
    // DEPTH-1 threshold set for AFULL to compensate for WACK's 1-cycle delay. 
    if((WIDTH==40)&&(DEPTH<=64)) `GEN_FIFO_USRAM_INSTANCE(COREFIFO_RAM64_40)
    else if(WIDTH==32) begin
        if     (DEPTH<=1024)  `GEN_FIFO_LSRAM_INSTANCE(COREFIFO_RAM1K_32)
        else if(DEPTH<=2048)  `GEN_FIFO_LSRAM_INSTANCE(COREFIFO_RAM2K_32)
        else if(DEPTH<=4096)  `GEN_FIFO_LSRAM_INSTANCE(COREFIFO_RAM4K_32)
        else if(DEPTH<=8192)  `GEN_FIFO_LSRAM_INSTANCE(COREFIFO_RAM8K_32)
        else if(DEPTH<=16384) `GEN_FIFO_LSRAM_INSTANCE(COREFIFO_RAM16K_32)
        else if(DEPTH<=32768) `GEN_FIFO_LSRAM_INSTANCE(COREFIFO_RAM32K_32)
    end 
endgenerate

assign CLK = clk;
assign RESET_N = ~sync_rst;

// NOTE: the underlying COREFIFO instance does NOT take a clock enable, 
//       so instead clk_en is masking the Read/Write enable pins.

// Write handshake control
reg LastWACK;
logic RealFull;
always_ff @(posedge clk) LastWACK <= WACK;
assign RealFull = FULL||(AFULL&&LastWACK); // compensate for 1 cycle write ack delay
assign InputACK = !RealFull;
assign WE = clk_en&&InputREQ&&!RealFull;
assign DATA = InputData;

// Read handshake control
assign OutputREQ = DVLD;
assign RE = clk_en&&OutputACK&&!EMPTY;
assign OutputData = Q;

// ECC signals
assign CorrectedECC = SB_CORRECT;
assign DetectedECC = DB_DETECT;

endmodule : handshake_fifo_libero
