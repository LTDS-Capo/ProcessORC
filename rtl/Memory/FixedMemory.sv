module FixedMemory #(
    parameter DATABITWIDTH = 16
)(
    input clk,
    input clk_en,

    input                     DataWriteEn,
    input  [DATABITWIDTH-1:0] DataAddrIn,
    input  [DATABITWIDTH-1:0] DataIn,
    output [DATABITWIDTH-1:0] DataOut
);
    
    reg [DATABITWIDTH-1:0] DataMemory [1023:0];
    wire [9:0] MemAddr = DataAddrIn[9:0];
    wire DataMemoryWriteTrigger = (DataWriteEn && clk_en);
    always_ff @(posedge clk) begin
        if (DataWriteEn) begin
            DataMemory[MemAddr] <= DataIn;
        end
    end
    assign DataOut = DataMemory[MemAddr];

endmodule