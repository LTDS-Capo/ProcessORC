module RegisterFile_Cell #(
    parameter BITWIDTH = 16,
    parameter REGADDRBITWIDTH = 4
)(
    input clk,
    input clk_en,
    input sync_rst,

    input                 Write_En,
    input  [BITWIDTH-1:0] DataIn,

    input                 Dirty_Set,
    input                 Mem_Write_En,
    input  [BITWIDTH-1:0] Mem_DataIn,


    output [BITWIDTH-1:0] DataOut,
    output                DirtyBitOut,

    input [REGADDRBITWIDTH-1:0] TEST_REGADDRIN
);

    reg   [BITWIDTH-1:0] Register;
    wire                 RegisterTrigger = (Write_En && clk_en) || (Mem_Write_En && clk_en) || sync_rst;
    logic [BITWIDTH-1:0] NextRegister;
    wire  [1:0] NextRegisterCondition;
    assign NextRegisterCondition[0] = (Write_En) && ~sync_rst;
    assign NextRegisterCondition[1] = (Mem_Write_En) && ~sync_rst;
    always_comb begin : NextRegisterMux
        case (NextRegisterCondition)
            2'b01  : NextRegister = DataIn;
            2'b10  : NextRegister = Mem_DataIn;
            default: NextRegister = 0; // Default is also case 0
        endcase
    end
    always_ff @(posedge clk) begin
        if (RegisterTrigger) begin
            Register <= NextRegister;
        end
    end

    reg  DirtyBit;
    wire DirtyBitTrigger = (Dirty_Set && clk_en) || (Mem_Write_En && clk_en) || sync_rst;
    wire NextDirtyBit = Dirty_Set && ~Mem_Write_En && ~sync_rst;
    always_ff @(posedge clk) begin
        if (DirtyBitTrigger) begin
            DirtyBit <= NextDirtyBit;
        end
    end

    assign DataOut = Register;
    assign DirtyBitOut = DirtyBit && ~Mem_Write_En;

endmodule