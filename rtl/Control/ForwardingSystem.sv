module ForwardingSystem #(
    parameter DATABITWIDTH = 16,
    parameter REGISTERCOUNT = 16,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                        RegAWriteEn,
    input                        RegAReadEn,
    input  [REGADDRBITWIDTH-1:0] RegAAddr,
    input     [DATABITWIDTH-1:0] RegAData,

    input                        RegBReadEn,
    input  [REGADDRBITWIDTH-1:0] RegBAddr,
    input     [DATABITWIDTH-1:0] RegBData,

    input     [DATABITWIDTH-1:0] Forward0Data,

    input                        Forward1Valid,
    input     [DATABITWIDTH-1:0] Forward1Data,
    input  [REGADDRBITWIDTH-1:0] Forward1RegAddr,

    output    [DATABITWIDTH-1:0] FwdADataOut,
    output    [DATABITWIDTH-1:0] FwdBDataOut
);
    
    // Debugger Stuff
        always_ff @(posedge clk) begin
            $display("FWD - WriteChk:Addr - %0b:%0h", WriteAddressCheck[REGADDRBITWIDTH], WriteAddressCheck[REGADDRBITWIDTH-1:0]);
            $display("FWD - AddrA:B       - %0h:%0h", RegAAddr, RegBAddr);
            $display("FWD - FwdA:B        - %0b:%0b", Forward0toAEn, Forward0toBEn);
            $display("FWD - DataA:B       - %0h:%0h", FwdADataOut, FwdBDataOut);
        end
    //

    // Forward Checking  ("Forward Check" on block diagram)
    // Notes: Checks the incoming read operands
    //        to check if they need to be forwarded
        // Store the write address to compare
        reg  [REGADDRBITWIDTH:0] WriteAddressCheck;
        wire                     WriteAddressCheckTrigger = clk_en || sync_rst;
        wire [REGADDRBITWIDTH:0] NextWriteAddressCheck = (sync_rst) ? 0 : {RegAWriteEn, RegAAddr};
        always_ff @(posedge clk) begin
            if (WriteAddressCheckTrigger) begin
                WriteAddressCheck <= NextWriteAddressCheck;
            end
        end
        // Check what forwards need to occur
        wire Forward0toAEn = WriteAddressCheck[REGADDRBITWIDTH] && RegAReadEn && (WriteAddressCheck[REGADDRBITWIDTH-1:0] == RegAAddr[REGADDRBITWIDTH-1:0]);
        wire Forward0toBEn = WriteAddressCheck[REGADDRBITWIDTH] && RegBReadEn && (WriteAddressCheck[REGADDRBITWIDTH-1:0] == RegBAddr[REGADDRBITWIDTH-1:0]);
        wire Forward1toAEn = Forward1Valid && RegAReadEn && (Forward1RegAddr == RegAAddr);
        wire Forward1toBEn = Forward1Valid && RegBReadEn && (Forward1RegAddr == RegBAddr);
    //

    // Implement Forwarding ("Forwarders" on block diagram)
    // Notes: Takes the four foward enable flags and uses them to Mux the respective Fowarded outputs.
        // A Forward
        logic [DATABITWIDTH-1:0] NextADataOut;
        wire  [1:0] NextADataOutCondition;
        assign NextADataOutCondition[0] = Forward0toAEn;
        assign NextADataOutCondition[1] = Forward1toAEn;
        always_comb begin : NextAMux
            case (NextADataOutCondition)
                2'b01  : NextADataOut = Forward0Data;
                2'b10  : NextADataOut = Forward1Data;
                default: NextADataOut = RegAData; // Default is also case 0
            endcase
        end
        assign FwdADataOut = NextADataOut;
        // B Forward
        logic [DATABITWIDTH-1:0] NextBDataOut;
        wire  [1:0] NextBDataOutCondition;
        assign NextBDataOutCondition[0] = Forward0toBEn;
        assign NextBDataOutCondition[1] = Forward1toBEn;
        always_comb begin : NextBMux
            case (NextBDataOutCondition)
                2'b01  : NextBDataOut = Forward0Data;
                2'b10  : NextBDataOut = Forward1Data;
                default: NextBDataOut = RegBData; // Default is also case 0
            endcase
        end
        assign FwdBDataOut = NextBDataOut;
    //


endmodule